
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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.sql.Types;
import java.time.Instant;
import java.util.*;

@Service
public class LocalDocumentService {
    private static final Logger LOG = LoggerFactory.getLogger(LocalDocumentService.class);
    private static final int UPLOAD_LOCK_STRIPES = 64;
    private static final Object[] UPLOAD_LOCKS = createUploadLocks();
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
        return upload(identity,uotId,file,category,description,targetType,targetId,principal,idempotencyKey,null);
    }

    public record EvidenceMetadata(String tipo, String origen, Instant fecha, Double latitud, Double longitud) {}

    public AppResult<LocalDocumentModels.FileInfo> upload(
            SessionIdentity identity, Long uotId, MultipartFile file, String category, String description,
            String targetType, Long targetId, boolean principal, UUID idempotencyKey, EvidenceMetadata evidence) {
        if (file == null || file.isEmpty()) {
            return bad("Seleccione un archivo para cargar.");
        }
        // Los técnicos pueden adjuntar evidencia a su salida aunque no administren el archivo general.
        boolean salida = "SALIDA".equalsIgnoreCase(targetType);
        boolean expedientePlanta = "PREDIO".equalsIgnoreCase(targetType)
                && uot.hasPermission(identity, uotId, "APAPPSS_PREDIOS_EDITAR");
        // Comprobante E5 en preparación: se vincula solo al confirmar el pago.
        boolean comprobantePago = "NINGUNO".equalsIgnoreCase(targetType)
                && "COMPROBANTE".equalsIgnoreCase(category)
                && uot.hasPermission(identity, uotId, "APAPPSS_PAGOS_PAGAR");
        boolean cajaEvidence = "OTRO".equalsIgnoreCase(category)
                && "NINGUNO".equalsIgnoreCase(targetType)
                && evidence!=null && "CAJA".equalsIgnoreCase(evidence.tipo())
                && (uot.hasPermission(identity,uotId,"CAJAS_ABRIR")
                    || uot.hasPermission(identity,uotId,"CAJAS_CERRAR"))
                && file.getContentType()!=null
                && java.util.Set.of("image/jpeg","image/png","image/webp").contains(file.getContentType().toLowerCase(java.util.Locale.ROOT))
                && file.getSize()<=8388608;
        boolean correspondencia = "CORRESPONDENCIA".equalsIgnoreCase(category);
        if (correspondencia && (!"NINGUNO".equalsIgnoreCase(targetType)
                || !belongsToPrincipalUot(identity, uotId)))
            return forbidden("Solo puede adjuntar archivos desde su unidad principal.");
        if (!correspondencia && !expedientePlanta && !comprobantePago && !cajaEvidence
                && !uot.hasPermission(identity, uotId, salida ? "SALIDAS_EDITAR" : "ARCHIVOS_CREAR"))
            return forbidden("No tiene permiso para registrar este documento.");
        if("CAJA".equalsIgnoreCase(evidence==null?null:evidence.tipo())&&!cajaEvidence)
            return bad("Selecciona imágenes JPG, PNG o WebP de hasta 8 MB.");
        String normalizedCategory;
        try {
            normalizedCategory = normalizeCategory(category);
        } catch (StorageFailure exception) {
            return AppResult.error(AppStatus.BAD_REQUEST, "ARCHIVO_INVALIDO", exception.getMessage());
        }
        String normalizedTarget = targetType == null || targetType.isBlank() ? "NINGUNO" : targetType.trim().toUpperCase(Locale.ROOT);
        if (!Set.of("NINGUNO", "BIEN", "PRODUCTO", "MOVIMIENTO", "SALIDA", "PREDIO", "PARCELA", "CULTIVO", "CENSO", "VISITA", "EVALUACION", "CASO_SANIDAD", "TRATAMIENTO", "SEGUIMIENTO", "PRODUCCION", "GASTO").contains(normalizedTarget)) return bad("El tipo de vínculo del archivo no es válido.");
        if (!"NINGUNO".equals(normalizedTarget) && (targetId == null || targetId <= 0)) return bad("Seleccione el registro al que pertenece el archivo.");
        if ("GASTO".equals(normalizedTarget)) {
            if (!uot.hasPermission(identity, uotId, "GASTOS_EDITAR"))
                return forbidden("No tiene permiso para adjuntar comprobantes al gasto.");
            if (!"COMPROBANTE".equals(normalizedCategory))
                return bad("Seleccione la categoría Comprobante para el gasto.");
            String mime = file.getContentType();
            if (mime == null || !Set.of("application/pdf", "image/jpeg", "image/png", "image/webp")
                    .contains(mime.split(";", 2)[0].trim().toLowerCase(Locale.ROOT)))
                return bad("Seleccione una imagen JPG, PNG, WebP o un PDF.");
        }

        if(evidence!=null) {
            if(evidence.tipo()==null || (evidence.tipo().isBlank() || evidence.tipo().length()>40) || !Set.of("CARGA","CAMARA").contains(evidence.origen())) return bad("Tipo de evidencia inválido.");
            if("CAMARA".equals(evidence.origen()) && (file.getContentType()==null || !file.getContentType().startsWith("image/"))) return bad("La captura debe ser una imagen.");
            if((evidence.latitud()==null)!=(evidence.longitud()==null) || (evidence.latitud()!=null && (!Double.isFinite(evidence.latitud()) || !Double.isFinite(evidence.longitud()) || Math.abs(evidence.latitud())>90 || Math.abs(evidence.longitud())>180))) return bad("Coordenadas inválidas.");
        }
        String key = storage.deterministicKey(
                uotId,
                identity.usuarioId(),
                idempotencyKey,
                normalizedCategory,
                normalizedTarget,
                targetId,
                file.getOriginalFilename()
        );
        try {
            LocalDocumentModels.FileInfo result;

            synchronized (uploadLock(idempotencyKey)) {
                result = transaction.execute(status -> {
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
                    if(evidence!=null) jdbc.update("""
                        UPDATE archivo.Archivo SET tipo_evidencia=?,origen_captura=?,fecha_captura=?,
                        posicion_captura=CASE WHEN ? IS NULL THEN NULL ELSE geography::Point(?,?,4326) END WHERE archivo_id=?
                        """,evidence.tipo(),evidence.origen(),evidence.fecha()==null?null:java.time.LocalDateTime.ofInstant(evidence.fecha(),java.time.ZoneOffset.UTC),
                        evidence.latitud(),evidence.latitud(),evidence.longitud(),fileId);
                    return getInternal(fileId);
                } catch (RuntimeException exception) {
                    deleteQueue.enqueue(stored.storageKey());
                    throw exception;
                }
                });
            }

            return AppResult.created("ARCHIVO_LOCAL_REGISTRADO", "Archivo almacenado correctamente.", result);
        } catch (StorageFailure exception) {
            return AppResult.error(AppStatus.BAD_REQUEST, "ARCHIVO_LOCAL_NO_REGISTRADO", exception.getMessage());
        } catch (DataAccessException exception) {
            // Registra el diagnóstico técnico real, sin exponer SQL ni datos personales al cliente.
            LOG.error("Fallo SQL al registrar archivo local: accion=SUBIR categoria={} uotId={} usuarioId={}",
                    normalizedCategory, uotId, identity.usuarioId(), exception);
            deleteQueue.enqueue(key);
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "ARCHIVO_LOCAL_NO_REGISTRADO", "No se pudo adjuntar el archivo. Intenta nuevamente.");
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
                      AND ISNULL(A.categoria,'')<>'CORRESPONDENCIA'
                      AND (NOT EXISTS(SELECT 1 FROM archivo.ArchivoVinculo AV
                           WHERE AV.archivo_id=A.archivo_id AND AV.estado=1 AND AV.gasto_campania_id IS NOT NULL)
                           OR (seg.FN_Usuario_TienePermisoUOT(?,A.uot_id,'ARCHIVOS_VER')=1
                           AND (seg.FN_Usuario_TienePermisoUOT(?,A.uot_id,'GASTOS_VER')=1
                                OR seg.FN_Usuario_TienePermisoUOT(?,A.uot_id,'GASTOS_LISTAR')=1)))
                      AND (? IS NULL OR A.uot_id=?)
                      AND (A.usuario_id=? OR NOT EXISTS(
                        SELECT 1 FROM archivo.ArchivoVinculo AV
                        WHERE AV.archivo_id=A.archivo_id AND AV.salida_campo_id IS NOT NULL AND AV.estado=1))
                    ORDER BY A.fecha_carga DESC,A.archivo_id DESC
                    """, (rs, rowNum) -> mapFile(rs), identity.usuarioId(), identity.usuarioId(), identity.usuarioId(), identity.usuarioId(), identity.usuarioId(), filterUot, filterUot, identity.usuarioId());
            return AppResult.ok("ARCHIVOS_LOCALES_LISTADOS", "Archivos consultados correctamente.", values);
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "ARCHIVOS_LOCALES_NO_LISTADOS", "No se pudieron consultar los archivos.");
        }
    }

    public AppResult<Content> content(SessionIdentity identity, Long fileId) {
        try {
            LocalDocumentModels.FileInfo info = getInternal(fileId);
            if (info == null || !canViewContent(identity, info)) return AppResult.error(AppStatus.NOT_FOUND, "ARCHIVO_NO_DISPONIBLE", "El archivo no está disponible.");
            Resource resource = storage.resource(info.storageKey());
            return AppResult.ok("ARCHIVO_LOCAL_OBTENIDO", "Archivo obtenido correctamente.", new Content(info, resource));
        } catch (IllegalArgumentException exception) {
            return AppResult.error(AppStatus.NOT_FOUND, "ARCHIVO_NO_DISPONIBLE", exception.getMessage());
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "ARCHIVO_NO_DISPONIBLE", "No se pudo obtener el archivo.");
        }
    }

    private boolean belongsToPrincipalUot(SessionIdentity identity, Long uotId) {
        if(identity==null || identity.usuarioId()==null || uotId==null) return false;
        Integer exists=jdbc.queryForObject("""
            SELECT COUNT(1) FROM seg.Usuario U
            JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
            JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.es_principal=1
                AND EU.estado=1 AND EU.uot_id=?
                AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
                AND (EU.fecha_cese IS NULL OR EU.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
            WHERE U.usuario_id=? AND U.estado=1 AND U.estado_cuenta='ACTIVA'
                AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
            """,Integer.class,uotId,identity.usuarioId());
        return exists!=null && exists>0;
    }

    private boolean canViewContent(SessionIdentity identity, LocalDocumentModels.FileInfo info) {
        if ("CORRESPONDENCIA".equals(info.category())) {
            // La correspondencia NUNCA hereda ARCHIVOS_VER ni permisos de APAPPSS.
            // Un adjunto aún no enviado solo puede verlo quien lo cargó.
            Integer allowed = jdbc.queryForObject("""
                SELECT CONVERT(INT,CASE WHEN EXISTS(
                    SELECT 1 FROM doc.DocumentoArchivo DA
                    JOIN doc.Documento D ON D.documento_id=DA.documento_id
                    WHERE DA.archivo_id=? AND (D.emisor_usuario_id=? OR EXISTS(
                        SELECT 1 FROM doc.Destinatario R
                        WHERE R.documento_id=D.documento_id AND R.usuario_id=?))
                )
                THEN 1 WHEN NOT EXISTS(SELECT 1 FROM doc.DocumentoArchivo WHERE archivo_id=?)
                    AND EXISTS(SELECT 1 FROM archivo.Archivo WHERE archivo_id=? AND usuario_id=? AND estado=1)
                THEN 1 ELSE 0 END)
                """, Integer.class, info.fileId(),identity.usuarioId(),identity.usuarioId(),
                info.fileId(),info.fileId(),identity.usuarioId());
            return allowed != null && allowed == 1;
        }
        Integer salida = jdbc.queryForObject("""
            SELECT COUNT(*) FROM archivo.ArchivoVinculo
            WHERE archivo_id=? AND salida_campo_id IS NOT NULL AND estado=1
            """, Integer.class, info.fileId());
        if (salida != null && salida > 0) {
            Integer allowed = jdbc.queryForObject("""
                SELECT COUNT(*) FROM archivo.ArchivoVinculo AV
                JOIN campo.SalidaE2 E ON E.salida_campo_id=AV.salida_campo_id
                JOIN seg.Usuario U ON U.usuario_id=?
                WHERE AV.archivo_id=? AND AV.estado=1 AND E.uot_id=?
                  AND seg.FN_Usuario_TienePermisoUOT(? , E.uot_id,'SALIDAS_VER')=1
                  AND (E.solicitante_empleado_id=U.persona_id OR
                       seg.FN_Usuario_TienePermisoUOT(?,E.uot_id,'SALIDAS_CONFIRMAR')=1)
                """, Integer.class, identity.usuarioId(),info.fileId(),info.uotId(),
                identity.usuarioId(),identity.usuarioId());
            return allowed != null && allowed > 0;
        }
        if (uot.hasPermission(identity, info.uotId(), "APAPPSS_PAGOS_VER")) {
            Integer comprobante = jdbc.queryForObject("""
                SELECT COUNT(*) FROM finanzas.PagoBeneficiarioE5 B
                JOIN finanzas.PagoSocio PS ON PS.pago_socio_id=B.pago_socio_id
                JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PS.liquidacion_socio_id
                JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=L.participacion_campania_socio_id
                JOIN comercial.CampaniaVenta C ON C.campania_venta_id=PC.campania_venta_id
                WHERE B.comprobante_archivo_id=? AND C.uot_id=? AND C.estado=1
                """, Integer.class, info.fileId(), info.uotId());
            if (comprobante!=null && comprobante>0) return true;
        }
        Integer expense = jdbc.queryForObject("""
                SELECT COUNT(1) FROM archivo.ArchivoVinculo
                WHERE archivo_id=? AND gasto_campania_id IS NOT NULL AND estado=1
                """, Integer.class, info.fileId());
        if (expense != null && expense > 0) {
            if (!uot.hasPermission(identity, info.uotId(), "ARCHIVOS_VER")
                    || (!uot.hasPermission(identity, info.uotId(), "GASTOS_VER")
                    && !uot.hasPermission(identity, info.uotId(), "GASTOS_LISTAR"))) return false;
            Integer allowed = jdbc.queryForObject("""
                    SELECT COUNT(1) FROM archivo.ArchivoVinculo AV
                    JOIN finanzas.GastoCampania G ON G.gasto_campania_id=AV.gasto_campania_id
                    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=G.campania_venta_id
                    WHERE AV.archivo_id=? AND AV.estado=1 AND C.uot_id=?
                    """, Integer.class, info.fileId(), info.uotId());
            return allowed != null && allowed > 0;
        }
        if (uot.hasPermission(identity, info.uotId(), "ARCHIVOS_VER")) return true;
        // Lectura puntual del documento vinculado a este expediente; no habilita
        // la descarga de documentos ajenos al predio o a otra UOT.
        if (uot.hasPermission(identity, info.uotId(), "APAPPSS_PREDIOS_VER")) {
            Integer permitido = jdbc.queryForObject("""
                SELECT COUNT(*) FROM prod.PlantaPaltaE3 P
                JOIN prod.PredioAmbito PA ON PA.predio_id=P.predio_id AND PA.uot_id=P.uot_id AND PA.estado=1
                WHERE P.uot_id=?
                  AND (EXISTS(SELECT 1 FROM prod.PlantaEvidenciaE3 E
                      WHERE E.planta_id=P.planta_id AND E.archivo_id=?)
                   OR EXISTS(SELECT 1 FROM sanidad.EpisodioPlantaE3 E
                      JOIN sanidad.TratamientoAplicacionE4 T ON T.episodio_id=E.episodio_id
                      JOIN sanidad.TratamientoArchivoE4 TA ON TA.aplicacion_id=T.aplicacion_id
                      WHERE E.planta_id=P.planta_id AND TA.archivo_id=?))
                """, Integer.class, info.uotId(), info.fileId(), info.fileId());
            if (permitido != null && permitido > 0) return true;
        }

        Integer allowed = jdbc.queryForObject(
                """
                SELECT CONVERT(INT, CASE WHEN
                    (EXISTS(SELECT 1 FROM logistica.BienImagen BI WHERE BI.archivo_id=? AND BI.estado=1)
                     AND seg.FN_Usuario_TienePermisoUOT(?,?,'INVENTARIO_LISTAR')=1)
                    OR
                    (EXISTS(SELECT 1 FROM logistica.ProductoImagen PI WHERE PI.archivo_id=? AND PI.estado=1)
                     AND seg.FN_Usuario_TienePermisoUOT(?,?,'PRODUCTOS_LISTAR')=1)
                    OR
                    (EXISTS(
                        SELECT 1
                        FROM archivo.ArchivoVinculo AV
                        INNER JOIN logistica.MovimientoInventario MI
                            ON MI.movimiento_inventario_id=AV.movimiento_inventario_id
                           AND MI.estado=1
                        WHERE AV.archivo_id=?
                          AND AV.estado=1
                    )
                     AND seg.FN_Usuario_TienePermisoUOT(?,?,'ALMACENES_KARDEX')=1)
                    THEN 1 ELSE 0 END)
                """,
                Integer.class,
                info.fileId(), identity.usuarioId(), info.uotId(),
                info.fileId(), identity.usuarioId(), info.uotId(),
                info.fileId(), identity.usuarioId(), info.uotId()
        );
        return allowed != null && allowed == 1;
    }

    public AppResult<Void> retire(SessionIdentity identity, Long fileId, String reason, UUID idempotencyKey) {
        if (reason == null || reason.isBlank()) return badVoid("Indique el motivo de retiro.");
        try {
            LocalDocumentModels.FileInfo info = getAnyInternal(fileId);
            if (info != null && "CORRESPONDENCIA".equals(info.category()))
                return badVoid("Los adjuntos administrativos se conservan en la trazabilidad; no se retiran desde Archivos.");
            if (info == null || !uot.hasPermission(identity, info.uotId(), "ARCHIVOS_RETIRAR")) return AppResult.error(AppStatus.NOT_FOUND, "ARCHIVO_NO_DISPONIBLE", "El archivo no está disponible.");
            Integer usado = jdbc.queryForObject("SELECT COUNT(*) FROM finanzas.PagoBeneficiarioE5 WHERE comprobante_archivo_id=?", Integer.class, fileId);
            if (usado!=null && usado>0) return badVoid("El comprobante pertenece a un pago confirmado.");
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
        if ("GASTO".equals(type)) {
            linkExpense(identity, uotId, fileId, targetId);
            return;
        }
        if ("MOVIMIENTO".equals(type)) {
            if (!uot.hasPermission(identity, uotId, "ALMACENES_MOVIMIENTO")) {
                throw new StorageFailure("No tiene permiso para adjuntar documentos al movimiento.");
            }
            Integer owned = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM logistica.MovimientoInventario M WITH (NOLOCK)
                    WHERE M.movimiento_inventario_id=? AND M.uot_id=? AND M.estado=1
                    """, Integer.class, targetId, uotId);
            if (owned == null || owned != 1) {
                throw new StorageFailure("El movimiento no pertenece a la UOT seleccionada.");
            }
            jdbc.update("""
                    INSERT INTO archivo.ArchivoVinculo (archivo_id,movimiento_inventario_id,estado)
                    VALUES (?,?,1)
                    """, fileId, targetId);
            return;
        }
        if ("SALIDA".equals(type)) {
            Integer owner = jdbc.queryForObject("""
                SELECT COUNT(*) FROM campo.SalidaE2 E
                JOIN seg.Usuario U ON U.usuario_id=?
                WHERE E.salida_campo_id=? AND E.uot_id=? AND E.solicitante_empleado_id=U.persona_id
                  AND E.estado NOT IN('BORRADOR','ELIMINADA','CANCELADA')
                """, Integer.class, identity.usuarioId(),targetId,uotId);
            if(owner==null||owner==0)throw new StorageFailure("Solo el responsable puede adjuntar archivos a su solicitud confirmada.");
            jdbc.update("INSERT archivo.ArchivoVinculo(archivo_id,salida_campo_id,estado) VALUES(?,?,1)",fileId,targetId);
            return;
        }
        if (!Set.of("BIEN","PRODUCTO").contains(type)) {
            linkTechnical(identity,uotId,fileId,type,targetId);
            return;
        }
        if (!mime.startsWith("image/")) throw new StorageFailure("Para vincular una imagen seleccione un archivo de imagen válido.");
        if ("BIEN".equals(type)) {
            if (!uot.hasPermission(identity, uotId, "INVENTARIO_EDITAR")) throw new StorageFailure("No tiene permiso para modificar imágenes del bien.");
            Long targetUot = jdbc.queryForObject("SELECT uot_id FROM logistica.BienInventario WHERE bien_inventario_id=? AND estado=1", Long.class, targetId);
            if (!Objects.equals(targetUot, uotId)) throw new StorageFailure("El bien no pertenece a la UOT seleccionada.");
            if (principal) jdbc.update("UPDATE logistica.BienImagen SET es_principal=0 WHERE bien_inventario_id=? AND estado=1", targetId);
            jdbc.update("INSERT logistica.BienImagen(bien_inventario_id,archivo_id,es_principal,orden,estado) VALUES(?,?,?,COALESCE((SELECT MAX(orden)+1 FROM logistica.BienImagen WHERE bien_inventario_id=?),1),1)", targetId, fileId, principal, targetId);
            return;
        }
        if (!uot.hasPermission(identity, uotId, "PRODUCTOS_IMAGENES")) throw new StorageFailure("No tiene permiso para administrar imágenes de productos.");
        Integer exists = jdbc.queryForObject("SELECT COUNT(*) FROM logistica.Producto WHERE producto_id=? AND estado=1", Integer.class, targetId);
        if (exists == null || exists == 0) throw new StorageFailure("El producto no está disponible.");
        if (principal) jdbc.update("UPDATE logistica.ProductoImagen SET es_principal=0 WHERE producto_id=? AND estado=1", targetId);
        jdbc.update("INSERT logistica.ProductoImagen(producto_id,archivo_id,es_principal,orden,estado) VALUES(?,?,?,COALESCE((SELECT MAX(orden)+1 FROM logistica.ProductoImagen WHERE producto_id=?),1),1)", targetId, fileId, principal, targetId);
    }

    private void linkExpense(SessionIdentity identity, Long uotId, Long fileId, Long expenseId) {
        // Se ejecuta dentro de la misma transacción que registra archivo.Archivo.
        // No se permite vincular un comprobante a un gasto de otra UOT.
        List<Long> campaigns = jdbc.queryForList("""
                SELECT G.campania_venta_id
                FROM finanzas.GastoCampania G
                JOIN comercial.CampaniaVenta C ON C.campania_venta_id=G.campania_venta_id
                WHERE G.gasto_campania_id=? AND G.estado=1 AND C.uot_id=? AND C.estado=1
                """, Long.class, expenseId, uotId);
        if (campaigns.size() != 1)
            throw new StorageFailure("El gasto no está disponible en la UOT seleccionada.");
        Long campaignId = campaigns.getFirst();
        // Mismo bloqueo de campaña que los gastos, repartos y pagos de E5.
        Integer lock = jdbc.queryForObject("""
                DECLARE @resultado INT;
                EXEC @resultado = sys.sp_getapplock
                    @Resource=?, @LockMode='Exclusive', @LockOwner='Transaction',
                    @LockTimeout=10000, @DbPrincipal='public';
                SELECT @resultado;
                """, Integer.class, "APAPPSS_E5_CAMP_" + campaignId);
        if (lock == null || lock < 0)
            throw new StorageFailure("La campaña está siendo procesada. Intente nuevamente.");
        if (!uot.hasPermission(identity, uotId, "GASTOS_EDITAR"))
            throw new StorageFailure("No tiene permiso para adjuntar comprobantes al gasto.");
        Integer allowed = jdbc.queryForObject("""
                SELECT COUNT(1)
                FROM finanzas.GastoCampania G WITH (UPDLOCK,HOLDLOCK)
                JOIN comercial.CampaniaVenta C WITH (UPDLOCK,HOLDLOCK)
                    ON C.campania_venta_id=G.campania_venta_id
                WHERE G.gasto_campania_id=? AND G.estado=1
                  AND G.estado_proceso IN ('REGISTRADO','APROBADO')
                  AND C.campania_venta_id=? AND C.uot_id=? AND C.estado=1
                  AND C.estado_proceso IN ('ACTIVA','VENCIDA')
                  AND NOT EXISTS (SELECT 1 FROM comercial.CierreCampaniaE5 X
                                  WHERE X.campania_venta_id=C.campania_venta_id)
                  AND NOT EXISTS (
                      SELECT 1 FROM finanzas.PagoSocio PG
                      JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PG.liquidacion_socio_id
                      JOIN comercial.ParticipacionCampaniaSocio P
                          ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
                      WHERE P.campania_venta_id=C.campania_venta_id AND PG.estado=1
                        AND PG.estado_proceso IN ('CONFIRMADO','ANULADO'))
                  AND EXISTS (
                      SELECT 1 FROM org.ConvenioUOTOrganizacion CU
                      JOIN org.ConvenioModuloEspecial CM
                          ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
                      JOIN seg.ModuloEspecial M ON M.modulo_especial_id=CM.modulo_especial_id
                          AND M.codigo='COMERCIALIZACION_ASOCIATIVA' AND M.estado=1
                      WHERE CU.uot_id=C.uot_id AND CU.empresa_id=C.asociacion_id AND CU.estado=1
                        AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
                        AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
                """, Integer.class, expenseId, campaignId, uotId);
        if (allowed == null || allowed != 1)
            throw new StorageFailure("El gasto o la campaña no admite nuevos comprobantes.");
        jdbc.update("""
                INSERT archivo.ArchivoVinculo(archivo_id,gasto_campania_id,estado)
                VALUES(?,?,1)
                """, fileId, expenseId);
    }

    private record TechnicalTarget(String column, String permission, String predioQuery) {}
    private void linkTechnical(SessionIdentity identity,Long uotId,Long fileId,String type,Long targetId) {
        // Table/column identifiers come only from this fixed server-side allowlist.
        TechnicalTarget target=switch(type) {
            case "PREDIO" -> new TechnicalTarget("predio_id","PREDIOS_VER","SELECT predio_id FROM prod.Predio WHERE predio_id=? AND estado=1");
            case "PARCELA" -> new TechnicalTarget("parcela_id","CULTIVOS_VER","SELECT predio_id FROM prod.Parcela WHERE parcela_id=? AND estado=1");
            case "CULTIVO" -> new TechnicalTarget("parcela_cultivo_id","CULTIVOS_VER","SELECT P.predio_id FROM prod.ParcelaCultivo C JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE C.parcela_cultivo_id=? AND C.estado=1 AND C.situacion_cultivo='ACTIVO'");
            case "CENSO" -> new TechnicalTarget("censo_plantas_id","CENSOS_VER","SELECT P.predio_id FROM prod.CensoPlantas X JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=X.parcela_cultivo_id JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE X.censo_plantas_id=? AND X.estado=1 AND C.situacion_cultivo='ACTIVO'");
            case "VISITA" -> new TechnicalTarget("visita_tecnica_id","VISITAS_VER","SELECT predio_id FROM campo.VisitaTecnica WHERE visita_tecnica_id=? AND estado=1 AND estado_proceso='INICIADA'");
            case "EVALUACION" -> new TechnicalTarget("evaluacion_agronomica_id","EVALUACIONES_VER","SELECT V.predio_id FROM campo.EvaluacionAgronomica X JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id WHERE X.evaluacion_agronomica_id=? AND X.estado=1 AND V.estado_proceso='INICIADA'");
            case "CASO_SANIDAD" -> new TechnicalTarget("caso_fitosanitario_id","SANIDAD_VER","SELECT P.predio_id FROM sanidad.CasoFitosanitario X JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=X.parcela_cultivo_id JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE X.caso_fitosanitario_id=? AND X.estado=1 AND X.estado_caso<>'CERRADO'");
            case "TRATAMIENTO" -> new TechnicalTarget("tratamiento_id","SANIDAD_VER","SELECT P.predio_id FROM sanidad.TratamientoFitosanitario X JOIN sanidad.CasoFitosanitario CF ON CF.caso_fitosanitario_id=X.caso_fitosanitario_id JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=CF.parcela_cultivo_id JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE X.tratamiento_fitosanitario_id=? AND X.estado=1 AND CF.estado=1 AND CF.estado_caso<>'CERRADO'");
            case "SEGUIMIENTO" -> new TechnicalTarget("seguimiento_fitosanitario_id","SANIDAD_VER","SELECT P.predio_id FROM sanidad.SeguimientoFitosanitario X JOIN sanidad.CasoFitosanitario CF ON CF.caso_fitosanitario_id=X.caso_fitosanitario_id JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=CF.parcela_cultivo_id JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE X.seguimiento_fitosanitario_id=? AND X.estado=1 AND CF.estado=1 AND CF.estado_caso<>'CERRADO'");
            case "PRODUCCION" -> new TechnicalTarget("disponibilidad_produccion_id","PRODUCCION_VER","SELECT P.predio_id FROM prod.DisponibilidadProduccion X JOIN prod.ParcelaCultivo C ON C.parcela_cultivo_id=X.parcela_cultivo_id JOIN prod.Parcela P ON P.parcela_id=C.parcela_id WHERE X.disponibilidad_produccion_id=? AND X.estado=1 AND X.estado_estimacion='ESTIMADA'");
            default -> throw new StorageFailure("Contexto no disponible.");
        };
        if(!uot.hasPermission(identity,uotId,target.permission())
                && !("PREDIO".equals(type) && uot.hasPermission(identity,uotId,"APAPPSS_PREDIOS_EDITAR")))
            throw new StorageFailure("No tiene permiso para adjuntar evidencia en este contexto.");
        var predios=jdbc.queryForList(target.predioQuery(),Long.class,targetId);
        if(predios.size()!=1) throw new StorageFailure("El contexto no está disponible o ya está cerrado.");
        Integer matches=jdbc.queryForObject("SELECT COUNT(*) FROM prod.PredioAmbito WHERE predio_id=? AND uot_id=? AND estado=1 AND (convenio_uot_organizacion_id IS NULL OR seg.FN_Usuario_TienePermisoUOT(?,uot_id,'APAPPSS_PREDIOS_VER')=1)",Integer.class,predios.getFirst(),uotId,identity.usuarioId());
        if(matches==null||matches==0) throw new StorageFailure("El contexto no pertenece a la UOT seleccionada.");
        jdbc.update("INSERT archivo.ArchivoVinculo(archivo_id,"+target.column()+",estado) VALUES(?,?,1)",fileId,targetId);
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
                rs.getTimestamp("fecha_carga").toLocalDateTime().toInstant(java.time.ZoneOffset.UTC));
    }

    private static Object uploadLock(UUID idempotencyKey) {
        int hash = idempotencyKey == null
                ? 0
                : idempotencyKey.hashCode();

        return UPLOAD_LOCKS[
                Math.floorMod(hash, UPLOAD_LOCKS.length)
        ];
    }

    private static Object[] createUploadLocks() {
        Object[] locks = new Object[UPLOAD_LOCK_STRIPES];

        Arrays.setAll(
                locks,
                index -> new Object()
        );

        return locks;
    }

    private static String normalizeCategory(String value) {
        if (value == null || value.isBlank()) {
            return "DOCUMENTO";
        }

        String category = value.trim().toUpperCase(Locale.ROOT);

        if (Set.of(
                "IMAGEN",
                "BIEN_IMAGEN",
                "PRODUCTO_IMAGEN"
        ).contains(category)) {
            return "FOTOGRAFIA";
        }

        if (!Set.of(
                "FOTOGRAFIA",
                "DOCUMENTO",
                "TICKET",
                "COMPROBANTE",
                "CORRESPONDENCIA",
                "OTRO"
        ).contains(category)) {
            throw new StorageFailure(
                    "La categoría del archivo no es válida."
            );
        }

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
