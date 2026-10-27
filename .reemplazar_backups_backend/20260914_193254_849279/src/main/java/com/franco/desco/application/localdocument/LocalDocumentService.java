package com.franco.desco.application.localdocument;

import com.franco.desco.adapter.out.sql.common.SqlIdempotencyCoordinator;
import com.franco.desco.adapter.out.sql.common.SqlProcedureExecutor;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.uot.port.out.UotPersistencePort;
import com.franco.desco.domain.localdocument.LocalDocumentModels;
import com.franco.desco.infrastructure.storage.*;
import org.springframework.core.io.Resource;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.sql.Types;
import java.time.Instant;
import java.util.*;

@Service
public class LocalDocumentService {
    private final JdbcTemplate jdbc;
    private final SqlProcedureExecutor procedures;
    private final UotPersistencePort uot;
    private final LocalBinaryStorage storage;
    private final LocalFileDeleteQueue deleteQueue;
    private final TransactionTemplate transaction;
    private final SqlIdempotencyCoordinator idempotency;

    public LocalDocumentService(JdbcTemplate jdbc, SqlProcedureExecutor procedures, UotPersistencePort uot,
                                LocalBinaryStorage storage, LocalFileDeleteQueue deleteQueue,
                                PlatformTransactionManager transactionManager, SqlIdempotencyCoordinator idempotency) {
        this.jdbc = jdbc;
        this.procedures = procedures;
        this.uot = uot;
        this.storage = storage;
        this.deleteQueue = deleteQueue;
        this.transaction = new TransactionTemplate(transactionManager);
        this.idempotency = idempotency;
    }

    public AppResult<LocalDocumentModels.FileInfo> upload(
            SessionIdentity identity, Long uotId, MultipartFile file, String category, String description,
            String targetType, Long targetId, boolean principal, UUID idempotencyKey) {
        if (!uot.hasPermission(identity, uotId, "ARCHIVOS_CREAR")) return forbidden("No tiene permiso para registrar archivos en la UOT seleccionada.");
        String normalizedCategory;
        try {
            normalizedCategory = normalizeCategory(category);
        } catch (StorageFailure exception) {
            return AppResult.error(AppStatus.BAD_REQUEST, "ARCHIVO_INVALIDO", exception.getMessage());
        }
        String normalizedTarget = targetType == null || targetType.isBlank() ? "NINGUNO" : targetType.trim().toUpperCase(Locale.ROOT);
        if (!Set.of("NINGUNO", "BIEN", "PRODUCTO").contains(normalizedTarget)) return bad("El tipo de vínculo del archivo no es válido.");
        if (!"NINGUNO".equals(normalizedTarget) && targetId == null) return bad("Seleccione el registro al que pertenece el archivo.");

        String key = storage.deterministicKey(uotId, identity.usuarioId(), idempotencyKey);
        try {
            LocalDocumentModels.FileInfo result = transaction.execute(status -> {
                acquireApplicationLock("DESCO:ARCHIVO_LOCAL:" + idempotencyKey);
                LocalDocumentModels.FileInfo existing = findByKey(identity.usuarioId(), uotId, key);
                if (existing != null) return existing;

                // Si una ejecución anterior alcanzó a escribir el binario pero la
                // transacción SQL no confirmó, se reemplaza ese huérfano bajo el
                // mismo lock. La fila existente, en cambio, siempre gana arriba.
                storage.deleteQuietly(key);

                LocalBinaryStorage.StoredFile stored;
                try {
                    stored = storage.store(key, file);
                } catch (Exception exception) {
                    throw new StorageFailure(publicMessage(exception));
                }

                try {
                    Map<String, Object> out = procedures.call("archivo", "PA_Archivo_Ins_RegistroAlmacenamiento", map(
                                    "nUsuarioId", identity.usuarioId(), "nUotId", uotId, "cNombreOriginal", stored.originalName(),
                                    "cMimeType", stored.contentType(), "cProveedor", "LOCAL", "cClave", stored.storageKey(),
                                    "cUrl", null, "nTamano", stored.size(), "cCategoria", normalizedCategory, "cDescripcion", description),
                            new SqlParameter("nUsuarioId", Types.BIGINT), new SqlParameter("nUotId", Types.BIGINT),
                            new SqlParameter("cNombreOriginal", Types.NVARCHAR), new SqlParameter("cMimeType", Types.VARCHAR),
                            new SqlParameter("cProveedor", Types.VARCHAR), new SqlParameter("cClave", Types.NVARCHAR),
                            new SqlParameter("cUrl", Types.NVARCHAR), new SqlParameter("nTamano", Types.BIGINT),
                            new SqlParameter("cCategoria", Types.VARCHAR), new SqlParameter("cDescripcion", Types.NVARCHAR),
                            new SqlOutParameter("nArchivoId", Types.BIGINT), new SqlOutParameter("bResultado", Types.BIT),
                            new SqlOutParameter("cMensaje", Types.NVARCHAR));
                    if (!SqlProcedureExecutor.success(out)) throw new StorageFailure(SqlProcedureExecutor.message(out, "No se pudo registrar el archivo."));
                    Long fileId = SqlProcedureExecutor.longValue(out, "nArchivoId");
                    jdbc.update("UPDATE archivo.Archivo SET hash_sha256=? WHERE archivo_id=?", HexFormat.of().parseHex(stored.sha256Hex()), fileId);
                    link(identity, uotId, fileId, stored.contentType(), normalizedTarget, targetId, principal);
                    return getInternal(fileId);
                } catch (RuntimeException exception) {
                    deleteQueue.enqueue(stored.storageKey());
                    throw exception;
                }
            });
            return AppResult.created("ARCHIVO_LOCAL_REGISTRADO", "Archivo almacenado correctamente.", result);
        } catch (StorageFailure exception) {
            return AppResult.error(AppStatus.BAD_REQUEST, "ARCHIVO_LOCAL_NO_REGISTRADO", exception.getMessage());
        } catch (DataAccessException exception) {
            // También cubre un eventual fallo al confirmar la transacción, que
            // sucede fuera del cuerpo de transaction.execute(...).
            deleteQueue.enqueue(key);
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "ARCHIVO_LOCAL_NO_REGISTRADO", "No se pudo registrar el archivo en este momento.");
        }
    }

    public AppResult<List<LocalDocumentModels.FileInfo>> list(SessionIdentity identity, Long requestedUotId) {
        try {
            var contextResult = uot.context(identity);
            if (!contextResult.exitoso() || contextResult.datos() == null) return AppResult.error(AppStatus.BAD_REQUEST, "UOT_REQUERIDA", "Seleccione una UOT de trabajo.");
            var context = contextResult.datos();
            Long filterUot;
            if (requestedUotId != null) {
                if (!uot.hasPermission(identity, requestedUotId, "ARCHIVOS_LISTAR")) return forbidden("No tiene permiso para consultar archivos en esa UOT.");
                filterUot = requestedUotId;
            } else if ("GENERAL".equals(context.mode())) {
                filterUot = null;
            } else {
                filterUot = context.selectedUotId();
                if (filterUot == null) return AppResult.error(AppStatus.BAD_REQUEST, "UOT_REQUERIDA", "Seleccione una UOT de trabajo.");
            }
            List<LocalDocumentModels.FileInfo> values = jdbc.query("""
                    SELECT A.archivo_id,A.uot_id,U.nombre uot_nombre,A.nombre_original,A.mime_type,ISNULL(A.tamano_bytes,0) tamano_bytes,
                           A.categoria,A.descripcion,A.clave_almacenamiento,A.hash_sha256,A.fecha_carga
                    FROM archivo.Archivo A JOIN org.UOT U ON U.uot_id=A.uot_id
                    WHERE A.estado=1 AND A.proveedor_almacenamiento='LOCAL'
                      AND EXISTS(SELECT 1 FROM seg.UsuarioUOT UU WHERE UU.usuario_id=? AND UU.uot_id=A.uot_id AND UU.estado=1 AND UU.fecha_hasta IS NULL)
                      AND seg.FN_Usuario_TienePermisoUOT(?,A.uot_id,'ARCHIVOS_LISTAR')=1
                      AND (? IS NULL OR A.uot_id=?)
                    ORDER BY A.fecha_carga DESC,A.archivo_id DESC
                    """, (rs, rowNum) -> mapFile(rs), identity.usuarioId(), identity.usuarioId(), filterUot, filterUot);
            return AppResult.ok("ARCHIVOS_LOCALES_LISTADOS", "Archivos consultados correctamente.", values);
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "ARCHIVOS_LOCALES_NO_LISTADOS", "No se pudieron consultar los archivos.");
        }
    }

    public AppResult<Content> content(SessionIdentity identity, Long fileId) {
        try {
            LocalDocumentModels.FileInfo info = getInternal(fileId);
            if (info == null || !uot.hasPermission(identity, info.uotId(), "ARCHIVOS_VER")) return AppResult.error(AppStatus.NOT_FOUND, "ARCHIVO_NO_DISPONIBLE", "El archivo no está disponible.");
            Resource resource = storage.resource(info.storageKey());
            return AppResult.ok("ARCHIVO_LOCAL_OBTENIDO", "Archivo obtenido correctamente.", new Content(info, resource));
        } catch (IllegalArgumentException exception) {
            return AppResult.error(AppStatus.NOT_FOUND, "ARCHIVO_NO_DISPONIBLE", exception.getMessage());
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "ARCHIVO_NO_DISPONIBLE", "No se pudo obtener el archivo.");
        }
    }

    public AppResult<Void> retire(SessionIdentity identity, Long fileId, String reason, UUID idempotencyKey) {
        if (reason == null || reason.isBlank()) return badVoid("Indique el motivo de retiro.");
        try {
            LocalDocumentModels.FileInfo info = getAnyInternal(fileId);
            if (info == null || !uot.hasPermission(identity, info.uotId(), "ARCHIVOS_RETIRAR")) return AppResult.error(AppStatus.NOT_FOUND, "ARCHIVO_NO_DISPONIBLE", "El archivo no está disponible.");
            PersistenceResult<Void> persistence = idempotency.executeVoid(identity.usuarioId(), idempotencyKey, "ARCHIVO_LOCAL_RETIRAR", "archivo", "Archivo", () -> {
                jdbc.update("""
                        UPDATE archivo.Archivo SET estado=0,fecha_retiro=COALESCE(fecha_retiro,SYSUTCDATETIME()),
                            retirado_por_usuario_id=COALESCE(retirado_por_usuario_id,?),usuario_retiro_id=COALESCE(usuario_retiro_id,?),
                            motivo_retiro=COALESCE(motivo_retiro,?)
                        WHERE archivo_id=?
                        """, identity.usuarioId(), identity.usuarioId(), reason.trim(), fileId);
                return PersistenceResult.ok("Archivo retirado correctamente.", null);
            });
            if (!persistence.exitoso()) return AppResult.error(AppStatus.BAD_REQUEST, "ARCHIVO_NO_RETIRADO", persistence.mensaje());
            deleteQueue.enqueue(info.storageKey());
            return AppResult.ok("ARCHIVO_RETIRADO", persistence.mensaje(), null);
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "ARCHIVO_NO_RETIRADO", "No se pudo retirar el archivo.");
        }
    }

    private void link(SessionIdentity identity, Long uotId, Long fileId, String mime, String type, Long targetId, boolean principal) {
        if ("NINGUNO".equals(type)) return;
        if (!mime.startsWith("image/")) throw new StorageFailure("Para vincular una imagen seleccione un archivo de imagen válido.");
        if ("BIEN".equals(type)) {
            if (!uot.hasPermission(identity, uotId, "INVENTARIO_EDITAR")) throw new StorageFailure("No tiene permiso para modificar imágenes del bien.");
            Long targetUot = jdbc.queryForObject("SELECT uot_id FROM logistica.BienInventario WHERE bien_inventario_id=? AND estado=1", Long.class, targetId);
            if (!Objects.equals(targetUot, uotId)) throw new StorageFailure("El bien no pertenece a la UOT seleccionada.");
            if (principal) jdbc.update("UPDATE logistica.BienImagen SET es_principal=0 WHERE bien_inventario_id=? AND estado=1", targetId);
            jdbc.update("INSERT logistica.BienImagen(bien_inventario_id,archivo_id,es_principal,orden,estado) VALUES(?,?,?,COALESCE((SELECT MAX(orden)+1 FROM logistica.BienImagen WHERE bien_inventario_id=?),1),1)", targetId, fileId, principal, targetId);
            return;
        }
        if (!uot.hasPermission(identity, uotId, "PRODUCTOS_CREAR")) throw new StorageFailure("No tiene permiso para administrar imágenes de productos.");
        Integer exists = jdbc.queryForObject("SELECT COUNT(*) FROM logistica.Producto WHERE producto_id=? AND estado=1", Integer.class, targetId);
        if (exists == null || exists == 0) throw new StorageFailure("El producto no está disponible.");
        if (principal) jdbc.update("UPDATE logistica.ProductoImagen SET es_principal=0 WHERE producto_id=? AND estado=1", targetId);
        jdbc.update("INSERT logistica.ProductoImagen(producto_id,archivo_id,es_principal,orden,estado) VALUES(?,?,?,COALESCE((SELECT MAX(orden)+1 FROM logistica.ProductoImagen WHERE producto_id=?),1),1)", targetId, fileId, principal, targetId);
    }

    private LocalDocumentModels.FileInfo findByKey(Long userId, Long uotId, String key) {
        List<LocalDocumentModels.FileInfo> values = jdbc.query("""
                SELECT TOP(1) A.archivo_id,A.uot_id,U.nombre uot_nombre,A.nombre_original,A.mime_type,ISNULL(A.tamano_bytes,0) tamano_bytes,
                       A.categoria,A.descripcion,A.clave_almacenamiento,A.hash_sha256,A.fecha_carga
                FROM archivo.Archivo A JOIN org.UOT U ON U.uot_id=A.uot_id
                WHERE A.usuario_id=? AND A.uot_id=? AND A.proveedor_almacenamiento='LOCAL' AND A.clave_almacenamiento=? AND A.estado=1
                ORDER BY A.archivo_id
                """, (rs, rowNum) -> mapFile(rs), userId, uotId, key);
        return values.isEmpty() ? null : values.getFirst();
    }

    private LocalDocumentModels.FileInfo getInternal(Long fileId) {
        List<LocalDocumentModels.FileInfo> values = jdbc.query("""
                SELECT A.archivo_id,A.uot_id,U.nombre uot_nombre,A.nombre_original,A.mime_type,ISNULL(A.tamano_bytes,0) tamano_bytes,
                       A.categoria,A.descripcion,A.clave_almacenamiento,A.hash_sha256,A.fecha_carga
                FROM archivo.Archivo A JOIN org.UOT U ON U.uot_id=A.uot_id
                WHERE A.archivo_id=? AND A.estado=1 AND A.proveedor_almacenamiento='LOCAL'
                """, (rs, rowNum) -> mapFile(rs), fileId);
        return values.isEmpty() ? null : values.getFirst();
    }

    private LocalDocumentModels.FileInfo getAnyInternal(Long fileId) {
        List<LocalDocumentModels.FileInfo> values = jdbc.query("""
                SELECT A.archivo_id,A.uot_id,U.nombre uot_nombre,A.nombre_original,A.mime_type,ISNULL(A.tamano_bytes,0) tamano_bytes,
                       A.categoria,A.descripcion,A.clave_almacenamiento,A.hash_sha256,A.fecha_carga
                FROM archivo.Archivo A JOIN org.UOT U ON U.uot_id=A.uot_id
                WHERE A.archivo_id=? AND A.proveedor_almacenamiento='LOCAL'
                """, (rs, rowNum) -> mapFile(rs), fileId);
        return values.isEmpty() ? null : values.getFirst();
    }

    private static LocalDocumentModels.FileInfo mapFile(java.sql.ResultSet rs) throws java.sql.SQLException {
        byte[] hash = rs.getBytes("hash_sha256");
        return new LocalDocumentModels.FileInfo(rs.getLong("archivo_id"), rs.getLong("uot_id"), rs.getString("uot_nombre"),
                rs.getString("nombre_original"), rs.getString("mime_type"), rs.getLong("tamano_bytes"), rs.getString("categoria"),
                rs.getString("descripcion"), rs.getString("clave_almacenamiento"), hash == null ? null : HexFormat.of().formatHex(hash),
                rs.getTimestamp("fecha_carga").toInstant());
    }

    private void acquireApplicationLock(String resource) {
        Integer result = jdbc.queryForObject("DECLARE @r int; EXEC @r=sp_getapplock @Resource=?,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000; SELECT @r;", Integer.class, resource);
        if (result == null || result < 0) throw new StorageFailure("No se pudo reservar la operación de carga. Intente nuevamente.");
    }

    private static String normalizeCategory(String value) {
        if (value == null || value.isBlank()) return "DOCUMENTO";
        String category = value.trim().toUpperCase(Locale.ROOT);
        if (!Set.of("FOTOGRAFIA", "DOCUMENTO", "TICKET", "COMPROBANTE", "OTRO").contains(category)) throw new StorageFailure("La categoría del archivo no es válida.");
        return category;
    }

    private static String publicMessage(Exception exception) {
        return exception instanceof IllegalArgumentException && exception.getMessage() != null ? exception.getMessage() : "No se pudo almacenar el archivo.";
    }

    private static Map<String, Object> map(Object... pairs) {
        Map<String, Object> values = new LinkedHashMap<>();
        for (int i = 0; i < pairs.length; i += 2) values.put(String.valueOf(pairs[i]), pairs[i + 1]);
        return values;
    }

    private static <T> AppResult<T> forbidden(String message) { return AppResult.error(AppStatus.FORBIDDEN, "UOT_SIN_PERMISO", message); }
    private static <T> AppResult<T> bad(String message) { return AppResult.error(AppStatus.BAD_REQUEST, "ARCHIVO_INVALIDO", message); }
    private static AppResult<Void> badVoid(String message) { return AppResult.error(AppStatus.BAD_REQUEST, "ARCHIVO_INVALIDO", message); }

    public record Content(LocalDocumentModels.FileInfo info, Resource resource) {}
    private static final class StorageFailure extends RuntimeException { private StorageFailure(String message) { super(message); } }
}
