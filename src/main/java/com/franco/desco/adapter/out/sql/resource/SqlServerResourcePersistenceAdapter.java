package com.franco.desco.adapter.out.sql.resource;

import com.franco.desco.adapter.out.sql.common.SqlIdempotencyCoordinator;
import com.franco.desco.adapter.out.sql.common.SqlProcedureExecutor;
import com.franco.desco.application.resource.ResourceCommands;
import com.franco.desco.application.resource.port.out.ResourcePersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.port.out.UotPersistencePort;
import com.franco.desco.domain.resource.ResourceModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.*;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.sql.Types;
import java.time.*;
import java.util.*;

@Repository
public class SqlServerResourcePersistenceAdapter implements ResourcePersistencePort {
    private final JdbcTemplate jdbc;
    private final SqlProcedureExecutor procedures;
    private final UotPersistencePort uot;
    private final TransactionTemplate transaction;
    private final JsonMapper json;
    private final SqlIdempotencyCoordinator idempotency;

    public SqlServerResourcePersistenceAdapter(JdbcTemplate jdbc, SqlProcedureExecutor procedures, UotPersistencePort uot,
                                               PlatformTransactionManager transactionManager, JsonMapper json,
                                               SqlIdempotencyCoordinator idempotency) {
        this.jdbc = jdbc;
        this.procedures = procedures;
        this.uot = uot;
        this.transaction = new TransactionTemplate(transactionManager);
        this.json = json;
        this.idempotency = idempotency;
    }

    @Override
    public PersistenceResult<List<ResourceModels.Asset>> assets(SessionIdentity identity, Long requestedUot) {
        Long filter = readScope(identity, requestedUot, "INVENTARIO_LISTAR");
        if (filter == INVALID_SCOPE) return PersistenceResult.error("Seleccione una UOT autorizada.");
        try {
            List<ResourceModels.Asset> values = jdbc.query("""
                    SELECT B.bien_inventario_id,B.uot_id,U.codigo uot_codigo,U.nombre uot_nombre,B.tipo_bien_id,T.nombre tipo_bien,
                           B.codigo_patrimonial,B.nombre,B.marca,B.modelo,B.serie,B.estado_bien,B.fecha_adquisicion,B.monto_adquisicion,
                           B.moneda_adquisicion,B.proveedor_persona_id,B.proveedor_empresa_id,B.observacion,B.estado,
                           (SELECT TOP(1) BI.archivo_id FROM logistica.BienImagen BI WHERE BI.bien_inventario_id=B.bien_inventario_id AND BI.estado=1 ORDER BY BI.es_principal DESC,BI.orden,BI.bien_imagen_id) imagen_id,
                           (SELECT COUNT(*) FROM logistica.BienIncidente I WHERE I.bien_inventario_id=B.bien_inventario_id AND I.estado=1 AND I.estado_incidente IN('ABIERTO','EN_ATENCION')) incidentes_abiertos
                    FROM logistica.BienInventario B JOIN org.UOT U ON U.uot_id=B.uot_id JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
                    WHERE EXISTS(SELECT 1 FROM seg.UsuarioUOT UU WHERE UU.usuario_id=? AND UU.uot_id=B.uot_id AND UU.estado=1 AND UU.fecha_hasta IS NULL)
                      AND seg.FN_Usuario_TienePermisoUOT(?,B.uot_id,'INVENTARIO_LISTAR')=1
                      AND (? IS NULL OR B.uot_id=?)
                    ORDER BY U.nombre,B.nombre
                    """, (rs, rowNum) -> assetRow(rs), identity.usuarioId(), identity.usuarioId(), filter, filter);
            return PersistenceResult.ok("Inventario consultado correctamente.", values);
        } catch (DataAccessException e) {
            return PersistenceResult.error("No se pudo consultar el inventario.");
        }
    }

    @Override
    public PersistenceResult<ResourceModels.AssetDetail> asset(SessionIdentity identity, Long assetId) {
        try {
            List<ResourceModels.Asset> assets = jdbc.query("""
                    SELECT B.bien_inventario_id,B.uot_id,U.codigo uot_codigo,U.nombre uot_nombre,B.tipo_bien_id,T.nombre tipo_bien,
                           B.codigo_patrimonial,B.nombre,B.marca,B.modelo,B.serie,B.estado_bien,B.fecha_adquisicion,B.monto_adquisicion,
                           B.moneda_adquisicion,B.proveedor_persona_id,B.proveedor_empresa_id,B.observacion,B.estado,
                           (SELECT TOP(1) BI.archivo_id FROM logistica.BienImagen BI WHERE BI.bien_inventario_id=B.bien_inventario_id AND BI.estado=1 ORDER BY BI.es_principal DESC,BI.orden,BI.bien_imagen_id) imagen_id,
                           (SELECT COUNT(*) FROM logistica.BienIncidente I WHERE I.bien_inventario_id=B.bien_inventario_id AND I.estado=1 AND I.estado_incidente IN('ABIERTO','EN_ATENCION')) incidentes_abiertos
                    FROM logistica.BienInventario B JOIN org.UOT U ON U.uot_id=B.uot_id JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
                    WHERE B.bien_inventario_id=?
                    """, (rs, rowNum) -> assetRow(rs), assetId);
            if (assets.isEmpty()) return PersistenceResult.error("El recurso no está disponible.");
            ResourceModels.Asset asset = assets.getFirst();
            if (!uot.hasPermission(identity, asset.uotId(), "INVENTARIO_VER")) return PersistenceResult.error("No tiene acceso al recurso seleccionado.");
            List<ResourceModels.AssetHistory> history = jdbc.query("SELECT bien_estado_historial_id,estado_bien,fecha_desde,fecha_hasta,motivo,usuario_id FROM logistica.BienEstadoHistorial WHERE bien_inventario_id=? ORDER BY fecha_desde DESC,bien_estado_historial_id DESC",
                    (rs, n) -> new ResourceModels.AssetHistory(rs.getLong(1), rs.getString(2), localDateTime(rs,3), localDateTime(rs,4), rs.getString(5), nullableLong(rs,6)), assetId);
            List<ResourceModels.Incident> incidents = jdbc.query("SELECT bien_incidente_id,tipo_incidente,fecha_hora,descripcion,costo_estimado,costo_real,estado_incidente,usuario_reporte_id,fecha_cierre,solucion FROM logistica.BienIncidente WHERE bien_inventario_id=? AND estado=1 ORDER BY fecha_hora DESC,bien_incidente_id DESC",
                    (rs,n) -> new ResourceModels.Incident(rs.getLong(1),rs.getString(2),localDateTime(rs,3),rs.getString(4),rs.getBigDecimal(5),rs.getBigDecimal(6),rs.getString(7),rs.getLong(8),localDateTime(rs,9),rs.getString(10)), assetId);
            List<Long> images = jdbc.query("SELECT archivo_id FROM logistica.BienImagen WHERE bien_inventario_id=? AND estado=1 ORDER BY es_principal DESC,orden,bien_imagen_id", (rs,n)->rs.getLong(1), assetId);
            return PersistenceResult.ok("Recurso obtenido correctamente.", new ResourceModels.AssetDetail(asset, history, incidents, images));
        } catch (DataAccessException e) {
            return PersistenceResult.error("No se pudo consultar el recurso.");
        }
    }

    @Override
    public PersistenceResult<Long> createAsset(SessionIdentity identity, ResourceCommands.CreateAsset command) {
        if (!uot.hasPermission(identity, command.uotId(), "INVENTARIO_CREAR")) return PersistenceResult.error("No tiene permiso para registrar recursos en esa UOT.");
        if (command.idempotencyKey() == null) return PersistenceResult.error("La clave de idempotencia es obligatoria.");
        if (!validAssetProvider(command.providerPersonId(),command.providerCompanyId())) return PersistenceResult.error("Seleccione una empresa activa de Administración como proveedor.");
        return idempotency.executeLong(identity.usuarioId(), command.idempotencyKey(),
                "BIEN_UOT_CREAR", "logistica", "BienInventario", () -> {
            Long companyId = compatibilityCompany(command.uotId());
            if (companyId == null) return PersistenceResult.error("No existe una organización DESCO para registrar el bien.");
            validateVehicleType(command.assetTypeId(), command.vehicle());
            String code = required(command.patrimonialCode(), "El código patrimonial es obligatorio.").toUpperCase(Locale.ROOT);
            Integer duplicated = jdbc.queryForObject("SELECT COUNT(*) FROM logistica.BienInventario WITH (UPDLOCK,HOLDLOCK) WHERE codigo_patrimonial=?", Integer.class, code);
            if (duplicated != null && duplicated > 0) return PersistenceResult.error("El código patrimonial ya está registrado.");
            // The plate guard requires the vehicle row before a vehicle can become available.
            // saveVehicle completes the transition atomically after inserting that row.
            String initialState = command.vehicle() != null ? "PENDIENTE_PLACA" : "DISPONIBLE";
            Long assetId = jdbc.queryForObject("""
                    DECLARE @creado TABLE (id BIGINT);
                    INSERT logistica.BienInventario(empresa_id,uot_id,tipo_bien_id,codigo_patrimonial,nombre,marca,modelo,serie,estado_bien,estado,
                      fecha_adquisicion,monto_adquisicion,moneda_adquisicion,proveedor_persona_id,proveedor_empresa_id,observacion)
                    OUTPUT INSERTED.bien_inventario_id INTO @creado VALUES(?,?,?,?,?,?,?,?,?,1,?,?,?,?,?,?);
                    SELECT id FROM @creado;
                    """, Long.class, companyId, command.uotId(), command.assetTypeId(), code,
                    required(command.name(), "El nombre del bien es obligatorio."), trim(command.brand()), trim(command.model()), trim(command.serial()), initialState,
                    command.acquisitionDate(), command.acquisitionAmount(), currency(command.currency()), command.providerPersonId(), command.providerCompanyId(), trim(command.observation()));
            if (assetId == null) throw new BusinessFailure("No se pudo obtener el recurso registrado.");
            jdbc.update("INSERT logistica.BienEstadoHistorial(bien_inventario_id,estado_bien,fecha_desde,motivo,usuario_id,estado) VALUES(?,?,SYSUTCDATETIME(),N'Registro inicial.',?,1)", assetId, initialState, identity.usuarioId());
            if (command.vehicle() != null) saveVehicle(identity, assetId, command.vehicle());
            return PersistenceResult.ok("Recurso registrado correctamente.", assetId);
        });
    }

    @Override
    public PersistenceResult<Void> updateAsset(SessionIdentity identity, ResourceCommands.UpdateAsset command) {
        Long assetUot = assetUot(command.assetId());
        if (assetUot == null) return PersistenceResult.error("El recurso no está disponible.");
        if (!uot.hasPermission(identity, assetUot, "INVENTARIO_EDITAR")) return PersistenceResult.error("No tiene permiso para modificar el recurso.");
        if (!validAssetProvider(command.providerPersonId(),command.providerCompanyId())) return PersistenceResult.error("Seleccione una empresa activa de Administración como proveedor.");
        try {
            return transaction.execute(status -> {
                validateVehicleType(command.assetTypeId(), command.vehicle());
                int changed = jdbc.update("""
                        UPDATE logistica.BienInventario SET tipo_bien_id=?,nombre=?,marca=?,modelo=?,serie=?,fecha_adquisicion=?,monto_adquisicion=?,
                        moneda_adquisicion=?,proveedor_persona_id=?,proveedor_empresa_id=?,observacion=? WHERE bien_inventario_id=? AND estado=1
                        """, command.assetTypeId(), required(command.name(), "El nombre del bien es obligatorio."), trim(command.brand()), trim(command.model()), trim(command.serial()),
                        command.acquisitionDate(), command.acquisitionAmount(), currency(command.currency()), command.providerPersonId(), command.providerCompanyId(), trim(command.observation()), command.assetId());
                if (changed != 1) return PersistenceResult.error("El recurso no está disponible.");
                if (command.vehicle() != null) saveVehicle(identity, command.assetId(), command.vehicle());
                return PersistenceResult.ok("Recurso actualizado correctamente.", null);
            });
        } catch (RuntimeException e) {
            return PersistenceResult.error(e instanceof BusinessFailure ? e.getMessage() : "No se pudo actualizar el recurso.");
        }
    }

    private boolean validAssetProvider(Long personId,Long companyId) {
        if(personId!=null)return false;
        if(companyId==null)return true;
        return Boolean.TRUE.equals(jdbc.queryForObject("SELECT CONVERT(BIT,CASE WHEN EXISTS(SELECT 1 FROM org.Empresa E WHERE E.empresa_id=? AND E.estado=1 AND NOT EXISTS(SELECT 1 FROM org.Asociacion A WHERE A.asociacion_id=E.empresa_id)) THEN 1 ELSE 0 END)",Boolean.class,companyId));
    }

    private void validateVehicleType(Integer typeId, ResourceCommands.VehicleData vehicle) {
        String name = jdbc.queryForObject("SELECT nombre FROM logistica.TipoBien WHERE tipo_bien_id=? AND estado=1", String.class, typeId);
        boolean vehicleType = name != null && java.text.Normalizer.normalize(name, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").trim().equalsIgnoreCase("VEHICULO");
        if (vehicleType && vehicle == null) throw new BusinessFailure("Complete los datos del vehículo.");
        if (!vehicleType && vehicle != null) throw new BusinessFailure("Los datos vehiculares requieren el tipo de bien Vehículo.");
    }

    private void saveVehicle(SessionIdentity identity, Long assetId, ResourceCommands.VehicleData vehicle) {
        Map<String,Object> result = procedures.call("logistica", "PA_Vehiculo_Upd_DatosPatrimoniales", map(
                "nUsuarioId",identity.usuarioId(),"nBienId",assetId,"cPlaca",trim(vehicle.plate()),
                "cTipo",vehicle.type(),"nKilometraje",vehicle.mileage(),"cColor",trim(vehicle.color())),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nBienId",Types.BIGINT),
                new SqlParameter("cPlaca",Types.VARCHAR),new SqlParameter("cTipo",Types.VARCHAR),
                new SqlParameter("nKilometraje",Types.DECIMAL),
                new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR),
                new SqlParameter("cColor",Types.NVARCHAR));
        if (!SqlProcedureExecutor.success(result)) throw new BusinessFailure(SqlProcedureExecutor.message(result,"No se pudieron guardar los datos del vehículo."));
    }

    @Override
    public PersistenceResult<Void> changeAssetState(SessionIdentity identity, ResourceCommands.ChangeAssetState command) {
        Long assetUot = assetUot(command.assetId());
        if (assetUot == null || !uot.hasPermission(identity, assetUot, "INVENTARIO_EDITAR")) return PersistenceResult.error("No tiene permiso para modificar el recurso.");
        try {
            String currentState = jdbc.queryForObject("SELECT estado_bien FROM logistica.BienInventario WHERE bien_inventario_id=? AND estado=1", String.class, command.assetId());
            if (currentState != null && currentState.equalsIgnoreCase(command.state())) {
                return PersistenceResult.ok("El recurso ya se encuentra en el estado solicitado.", null);
            }
        } catch (DataAccessException exception) {
            return PersistenceResult.error("No se pudo validar el estado actual del recurso.");
        }
        Map<String,Object> out = procedures.call("logistica","PA_BienInventario_Ins_CambioEstado", map(
                        "nUsuarioId",identity.usuarioId(),"nBienInventarioId",command.assetId(),"cEstadoBien",command.state(),"cMotivo",command.reason()),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nBienInventarioId",Types.BIGINT),new SqlParameter("cEstadoBien",Types.VARCHAR),new SqlParameter("cMotivo",Types.NVARCHAR),
                new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        return voidResult(out,"No se pudo cambiar el estado del recurso.");
    }

    @Override
    public PersistenceResult<Long> reportIncident(SessionIdentity identity, ResourceCommands.ReportIncident command) {
        Long assetUot = assetUot(command.assetId());
        if (assetUot == null || !uot.hasPermission(identity, assetUot, "INVENTARIO_EDITAR")) return PersistenceResult.error("No tiene permiso para registrar incidentes del recurso.");
        return idempotency.executeLong(identity.usuarioId(), command.idempotencyKey(), "BIEN_INCIDENTE_CREAR", "logistica", "BienIncidente", () -> {
            Map<String,Object> out = procedures.call("logistica","PA_BienInventario_Ins_Incidente", map(
                            "nUsuarioId",identity.usuarioId(),"nBienInventarioId",command.assetId(),"cTipo",command.type(),"dFechaHora",command.dateTime(),
                            "cDescripcion",command.description(),"nCostoEstimado",command.estimatedCost()),
                    new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nBienInventarioId",Types.BIGINT),new SqlParameter("cTipo",Types.VARCHAR),
                    new SqlParameter("dFechaHora",Types.TIMESTAMP),new SqlParameter("cDescripcion",Types.NVARCHAR),new SqlParameter("nCostoEstimado",Types.DECIMAL),
                    new SqlOutParameter("nBienIncidenteId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
            if (!SqlProcedureExecutor.success(out)) return PersistenceResult.error(SqlProcedureExecutor.message(out,"No se pudo registrar el incidente."));
            return PersistenceResult.ok(SqlProcedureExecutor.message(out,"Incidente registrado correctamente."),SqlProcedureExecutor.longValue(out,"nBienIncidenteId"));
        });
    }

    @Override
    public PersistenceResult<List<ResourceModels.Product>> products(SessionIdentity identity, Long requestedUot) {
        Long priceUot = priceScope(identity, requestedUot);
        if (priceUot == INVALID_SCOPE) return PersistenceResult.error("Seleccione una UOT autorizada.");
        try {
            List<ResourceModels.Product> values = jdbc.query("""
                    SELECT P.producto_id,P.codigo,P.nombre,P.descripcion,P.unidad_medida,P.categoria,P.requiere_lote,P.controla_vencimiento,P.estado,
                           PR.producto_precio_id,PR.precio_venta,PR.moneda,
                           (SELECT TOP(1) PI.archivo_id FROM logistica.ProductoImagen PI WHERE PI.producto_id=P.producto_id AND PI.estado=1 ORDER BY PI.es_principal DESC,PI.orden,PI.producto_imagen_id) imagen_id
                    FROM logistica.Producto P
                    OUTER APPLY(SELECT TOP(1) X.producto_precio_id,X.precio_venta,X.moneda FROM logistica.ProductoPrecio X
                        WHERE X.producto_id=P.producto_id AND X.estado=1 AND X.fecha_hasta IS NULL AND (X.uot_id=? OR X.uot_id IS NULL)
                        ORDER BY CASE WHEN X.uot_id=? THEN 0 ELSE 1 END,X.version DESC) PR
                    WHERE P.estado=1 ORDER BY P.nombre
                    """, (rs,n)->new ResourceModels.Product(rs.getLong("producto_id"),rs.getString("codigo"),rs.getString("nombre"),rs.getString("descripcion"),
                    rs.getString("unidad_medida"),rs.getString("categoria"),rs.getBoolean("requiere_lote"),rs.getBoolean("controla_vencimiento"),rs.getBigDecimal("precio_venta"),
                    rs.getString("moneda"),nullableLong(rs,"producto_precio_id"),nullableLong(rs,"imagen_id"),rs.getBoolean("estado")), priceUot, priceUot);
            return PersistenceResult.ok("Productos consultados correctamente.",values);
        } catch (DataAccessException e) { return PersistenceResult.error("No se pudieron consultar los productos."); }
    }

    @Override
    public PersistenceResult<Long> createProduct(SessionIdentity identity, ResourceCommands.CreateProduct c) {
        return idempotency.executeLong(identity.usuarioId(), c.idempotencyKey(), "PRODUCTO_CREAR", "logistica", "Producto", () -> {
            Map<String,Object> out = procedures.call("logistica","PA_Producto_Ins_Registro",map("nUsuarioId",identity.usuarioId(),"nUotId",c.contextUotId(),"cCodigo",c.code(),"cNombre",c.name(),"cDescripcion",c.description(),"cUnidad",c.unit(),"cCategoria",c.category()),
                    new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nUotId",Types.BIGINT),new SqlParameter("cCodigo",Types.VARCHAR),new SqlParameter("cNombre",Types.NVARCHAR),new SqlParameter("cDescripcion",Types.NVARCHAR),new SqlParameter("cUnidad",Types.VARCHAR),new SqlParameter("cCategoria",Types.NVARCHAR),
                    new SqlOutParameter("nProductoId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
            return idResult(out,"nProductoId","No se pudo registrar el producto.");
        });
    }

    @Override
    public PersistenceResult<Long> versionPrice(SessionIdentity identity, ResourceCommands.VersionPrice c) {
        return idempotency.executeLong(identity.usuarioId(), c.idempotencyKey(), "PRODUCTO_PRECIO_VERSIONAR", "logistica", "ProductoPrecio", () -> {
            Map<String,Object> out = procedures.call("logistica","PA_ProductoPrecio_Ins_Version",map("nUsuarioId",identity.usuarioId(),"nUotIdContexto",c.contextUotId(),"nProductoId",c.productId(),"nUotPrecioId",c.priceUotId(),"nPrecio",c.price(),"cMoneda",currency(c.currency())),
                    new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nUotIdContexto",Types.BIGINT),new SqlParameter("nProductoId",Types.BIGINT),new SqlParameter("nUotPrecioId",Types.BIGINT),new SqlParameter("nPrecio",Types.DECIMAL),new SqlParameter("cMoneda",Types.CHAR),
                    new SqlOutParameter("nProductoPrecioId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
            return idResult(out,"nProductoPrecioId","No se pudo versionar el precio.");
        });
    }

    @Override
    public PersistenceResult<List<ResourceModels.Warehouse>> warehouses(SessionIdentity identity, Long requestedUot) {
        Long filter=readScope(identity,requestedUot,"ALMACENES_LISTAR");
        if(filter==INVALID_SCOPE)return PersistenceResult.error("Seleccione una UOT autorizada.");
        try {
            List<ResourceModels.Warehouse> values=jdbc.query("""
                    SELECT A.almacen_id,A.uot_propietaria_id,UP.nombre uot_propietaria,A.ubicacion_id,A.codigo,A.nombre,A.descripcion,
                           AU.tipo_acceso,AU.permite_entrada,AU.permite_salida,A.estado
                    FROM logistica.AlmacenUOT AU JOIN logistica.Almacen A ON A.almacen_id=AU.almacen_id JOIN org.UOT UP ON UP.uot_id=A.uot_propietaria_id
                    WHERE AU.estado=1 AND AU.fecha_hasta IS NULL AND A.estado=1
                      AND EXISTS(SELECT 1 FROM seg.UsuarioUOT UU WHERE UU.usuario_id=? AND UU.uot_id=AU.uot_id AND UU.estado=1 AND UU.fecha_hasta IS NULL)
                      AND seg.FN_Usuario_TienePermisoUOT(?,AU.uot_id,'ALMACENES_LISTAR')=1 AND (? IS NULL OR AU.uot_id=?)
                    ORDER BY A.nombre
                    """,(rs,n)->new ResourceModels.Warehouse(rs.getLong("almacen_id"),rs.getLong("uot_propietaria_id"),rs.getString("uot_propietaria"),nullableLong(rs,"ubicacion_id"),rs.getString("codigo"),rs.getString("nombre"),rs.getString("descripcion"),rs.getString("tipo_acceso"),rs.getBoolean("permite_entrada"),rs.getBoolean("permite_salida"),rs.getBoolean("estado")),identity.usuarioId(),identity.usuarioId(),filter,filter);
            return PersistenceResult.ok("Almacenes consultados correctamente.",values);
        }catch(DataAccessException e){return PersistenceResult.error("No se pudieron consultar los almacenes.");}
    }

    @Override
    public PersistenceResult<Long> createWarehouse(SessionIdentity identity, ResourceCommands.CreateWarehouse c) {
        return idempotency.executeLong(identity.usuarioId(), c.idempotencyKey(), "ALMACEN_CREAR", "logistica", "Almacen", () -> {
            Map<String,Object> out=procedures.call("logistica","PA_Almacen_Ins_Registro",map("nUsuarioId",identity.usuarioId(),"nUotId",c.uotId(),"nUbicacionId",c.locationId(),"cCodigo",c.code(),"cNombre",c.name(),"cDescripcion",c.description()),
                    new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nUotId",Types.BIGINT),new SqlParameter("nUbicacionId",Types.BIGINT),new SqlParameter("cCodigo",Types.VARCHAR),new SqlParameter("cNombre",Types.NVARCHAR),new SqlParameter("cDescripcion",Types.NVARCHAR),new SqlOutParameter("nAlmacenId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
            return idResult(out,"nAlmacenId","No se pudo registrar el almacén.");
        });
    }

    @Override
    public PersistenceResult<Void> shareWarehouse(SessionIdentity identity, ResourceCommands.ShareWarehouse c) {
        try {
            Long owner=jdbc.queryForObject("SELECT uot_propietaria_id FROM logistica.Almacen WHERE almacen_id=? AND estado=1",Long.class,c.warehouseId());
            if(owner==null || !uot.hasPermission(identity,owner,"ALMACENES_CREAR") || !uot.hasPermission(identity,c.uotId(),"ALMACENES_CREAR")) return PersistenceResult.error("Necesita permiso sobre la UOT propietaria y la UOT que utilizará el almacén.");
            Integer same=jdbc.queryForObject("SELECT COUNT(*) FROM logistica.AlmacenUOT WHERE almacen_id=? AND uot_id=? AND estado=1 AND fecha_hasta IS NULL AND permite_entrada=? AND permite_salida=?",Integer.class,c.warehouseId(),c.uotId(),c.allowsEntry(),c.allowsExit());
            if(same!=null&&same>0)return PersistenceResult.ok("El almacén ya tiene el acceso solicitado.",null);
            transaction.executeWithoutResult(status->{
                jdbc.update("UPDATE logistica.AlmacenUOT SET estado=0,fecha_hasta=SYSUTCDATETIME() WHERE almacen_id=? AND uot_id=? AND estado=1 AND fecha_hasta IS NULL",c.warehouseId(),c.uotId());
                jdbc.update("INSERT logistica.AlmacenUOT(almacen_id,uot_id,tipo_acceso,permite_entrada,permite_salida,estado) VALUES(?,?,'COMPARTIDO',?,?,1)",c.warehouseId(),c.uotId(),c.allowsEntry(),c.allowsExit());
            });
            return PersistenceResult.ok("Acceso al almacén actualizado correctamente.",null);
        }catch(DataAccessException e){return PersistenceResult.error("No se pudo compartir el almacén.");}
    }

    @Override
    public PersistenceResult<List<ResourceModels.Stock>> stock(SessionIdentity identity, Long requestedUot, Long warehouseId) {
        Long filter=readScope(identity,requestedUot,"ALMACENES_LISTAR"); if(filter==INVALID_SCOPE)return PersistenceResult.error("Seleccione una UOT autorizada.");
        try{
            List<ResourceModels.Stock> values=jdbc.query("""
                    SELECT S.almacen_id,S.almacen,S.producto_id,S.producto,S.unidad_medida,S.stock_actual,S.stock_reservado,S.stock_disponible,S.stock_minimo,S.fecha_actualizacion
                    FROM logistica.VW_StockProducto S
                    WHERE EXISTS(
                        SELECT 1
                        FROM logistica.AlmacenUOT AU
                        JOIN seg.UsuarioUOT UU ON UU.uot_id=AU.uot_id
                        WHERE AU.almacen_id=S.almacen_id
                          AND AU.estado=1 AND AU.fecha_hasta IS NULL
                          AND UU.usuario_id=? AND UU.estado=1 AND UU.fecha_hasta IS NULL
                          AND seg.FN_Usuario_TienePermisoUOT(?,AU.uot_id,'ALMACENES_LISTAR')=1
                          AND (? IS NULL OR AU.uot_id=?)
                    )
                      AND (? IS NULL OR S.almacen_id=?)
                    ORDER BY S.almacen,S.producto
                    """,(rs,n)->new ResourceModels.Stock(rs.getLong(1),rs.getString(2),rs.getLong(3),rs.getString(4),rs.getString(5),rs.getBigDecimal(6),rs.getBigDecimal(7),rs.getBigDecimal(8),rs.getBigDecimal(9),localDateTime(rs,10)),
                    identity.usuarioId(),identity.usuarioId(),filter,filter,warehouseId,warehouseId);
            return PersistenceResult.ok("Stock consultado correctamente.",values);
        }catch(DataAccessException e){return PersistenceResult.error("No se pudo consultar el stock.");}
    }

    @Override
    public PersistenceResult<List<ResourceModels.Kardex>> kardex(SessionIdentity identity, Long requestedUot, Long warehouseId, Long productId) {
        Long filter=readScope(identity,requestedUot,"ALMACENES_KARDEX"); if(filter==INVALID_SCOPE)return PersistenceResult.error("Seleccione una UOT autorizada.");
        try{
            List<ResourceModels.Kardex> values=jdbc.query("""
                    SELECT K.movimiento_inventario_id,K.fecha_hora,K.uot_id,U.nombre uot_nombre,K.almacen_id,A.nombre almacen,K.tipo_movimiento,K.naturaleza,K.documento_referencia,
                           K.producto_id,P.nombre producto_nombre,K.cantidad,K.costo_unitario,K.moneda,K.lote,K.fecha_vencimiento,K.usuario_id,K.observacion
                    FROM logistica.VW_KardexProducto K JOIN org.UOT U ON U.uot_id=K.uot_id JOIN logistica.Almacen A ON A.almacen_id=K.almacen_id JOIN logistica.Producto P ON P.producto_id=K.producto_id
                    WHERE EXISTS(SELECT 1 FROM seg.UsuarioUOT UU WHERE UU.usuario_id=? AND UU.uot_id=K.uot_id AND UU.estado=1 AND UU.fecha_hasta IS NULL)
                      AND seg.FN_Usuario_TienePermisoUOT(?,K.uot_id,'ALMACENES_KARDEX')=1
                      AND (? IS NULL OR K.uot_id=?) AND (? IS NULL OR K.almacen_id=?) AND (? IS NULL OR K.producto_id=?)
                    ORDER BY K.fecha_hora DESC,K.movimiento_inventario_id DESC
                    """,(rs,n)->new ResourceModels.Kardex(rs.getLong(1),localDateTime(rs,2),rs.getLong(3),rs.getString(4),rs.getLong(5),rs.getString(6),rs.getString(7),rs.getString(8),rs.getString(9),rs.getLong(10),rs.getString(11),rs.getBigDecimal(12),rs.getBigDecimal(13),rs.getString(14),rs.getString(15),localDate(rs,16),rs.getLong(17),rs.getString(18)),identity.usuarioId(),identity.usuarioId(),filter,filter,warehouseId,warehouseId,productId,productId);
            return PersistenceResult.ok("Kardex consultado correctamente.",values);
        }catch(DataAccessException e){return PersistenceResult.error("No se pudo consultar el Kardex.");}
    }

    @Override
    public PersistenceResult<Long> registerMovement(SessionIdentity identity, ResourceCommands.RegisterMovement c) {
        String details;
        try {
            var serializableLines = c.lines().stream().map(line -> map(
                    "productoId", line.productId(), "cantidad", line.quantity(), "costoUnitario", line.unitCost(),
                    "moneda", line.currency(), "lote", line.lot(), "fechaVencimiento", line.expirationDate()
            )).toList();
            details=json.writeValueAsString(serializableLines);
        } catch(RuntimeException e){ return PersistenceResult.error("El detalle del movimiento no es válido."); }
        Map<String,Object> out=procedures.call("logistica","PA_MovimientoInventario_Ins_Registrar",map("nUsuarioId",identity.usuarioId(),"nUotId",c.uotId(),"nAlmacenId",c.warehouseId(),"cTipo",c.type(),"cNaturaleza",c.nature(),"gClaveIdempotencia",c.idempotencyKey().toString(),"cDetalleJson",details,"nProveedorPersonaId",c.providerPersonId(),"nProveedorEmpresaId",c.providerCompanyId(),"cDocumento",c.documentReference(),"cObservacion",c.observation()),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nUotId",Types.BIGINT),new SqlParameter("nAlmacenId",Types.BIGINT),new SqlParameter("cTipo",Types.VARCHAR),new SqlParameter("cNaturaleza",Types.CHAR),new SqlParameter("gClaveIdempotencia",Types.VARCHAR),new SqlParameter("cDetalleJson",Types.NVARCHAR),new SqlParameter("nProveedorPersonaId",Types.BIGINT),new SqlParameter("nProveedorEmpresaId",Types.BIGINT),new SqlParameter("cDocumento",Types.NVARCHAR),new SqlParameter("cObservacion",Types.NVARCHAR),new SqlOutParameter("nMovimientoId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        return idResult(out,"nMovimientoId","No se pudo registrar el movimiento.");
    }

    private Long readScope(SessionIdentity identity, Long requested, String permission) {
        if(requested!=null)return uot.hasPermission(identity,requested,permission)?requested:INVALID_SCOPE;
        var result=uot.context(identity); if(!result.exitoso()||result.datos()==null)return INVALID_SCOPE;
        var context=result.datos();
        if("GENERAL".equals(context.mode())) return null;
        Long selected=context.selectedUotId();
        return selected!=null&&uot.hasPermission(identity,selected,permission)?selected:INVALID_SCOPE;
    }

    private Long priceScope(SessionIdentity identity, Long requested) {
        if(requested!=null)return uot.hasPermission(identity,requested,"PRODUCTOS_LISTAR")?requested:INVALID_SCOPE;
        var result=uot.context(identity); if(!result.exitoso()||result.datos()==null)return INVALID_SCOPE;
        if("GENERAL".equals(result.datos().mode())) return null;
        Long selected=result.datos().selectedUotId(); return selected!=null&&uot.hasPermission(identity,selected,"PRODUCTOS_LISTAR")?selected:INVALID_SCOPE;
    }

    private Long assetUot(Long id){try{return jdbc.queryForObject("SELECT uot_id FROM logistica.BienInventario WHERE bien_inventario_id=?",Long.class,id);}catch(DataAccessException e){return null;}}
    private Long compatibilityCompany(Long uotId){
        List<Long> ids=jdbc.query("SELECT COALESCE((SELECT empresa_legacy_id FROM org.UOT WHERE uot_id=?),(SELECT TOP(1) empresa_legacy_id FROM org.UOT WHERE es_raiz=1 AND estado=1 AND empresa_legacy_id IS NOT NULL ORDER BY uot_id))",(rs,n)->rs.getLong(1),uotId);
        return ids.isEmpty()||ids.getFirst()==0?null:ids.getFirst();
    }

    private static ResourceModels.Asset assetRow(java.sql.ResultSet rs)throws java.sql.SQLException{return new ResourceModels.Asset(rs.getLong("bien_inventario_id"),rs.getLong("uot_id"),rs.getString("uot_codigo"),rs.getString("uot_nombre"),rs.getInt("tipo_bien_id"),rs.getString("tipo_bien"),rs.getString("codigo_patrimonial"),rs.getString("nombre"),rs.getString("marca"),rs.getString("modelo"),rs.getString("serie"),rs.getString("estado_bien"),localDate(rs,"fecha_adquisicion"),rs.getBigDecimal("monto_adquisicion"),rs.getString("moneda_adquisicion"),nullableLong(rs,"proveedor_persona_id"),nullableLong(rs,"proveedor_empresa_id"),rs.getString("observacion"),nullableLong(rs,"imagen_id"),rs.getInt("incidentes_abiertos"),rs.getBoolean("estado"));}
    private static PersistenceResult<Long> idResult(Map<String,Object> out,String key,String fallback){if(!SqlProcedureExecutor.success(out))return PersistenceResult.error(SqlProcedureExecutor.message(out,fallback));return PersistenceResult.ok(SqlProcedureExecutor.message(out,"Registro creado correctamente."),SqlProcedureExecutor.longValue(out,key));}
    private static PersistenceResult<Void> voidResult(Map<String,Object> out,String fallback){if(!SqlProcedureExecutor.success(out))return PersistenceResult.error(SqlProcedureExecutor.message(out,fallback));return PersistenceResult.ok(SqlProcedureExecutor.message(out,"Acción realizada."),null);}
    private static Map<String,Object> map(Object...p){Map<String,Object>m=new LinkedHashMap<>();for(int i=0;i<p.length;i+=2)m.put(String.valueOf(p[i]),p[i+1]);return m;}
    private static Long nullableLong(java.sql.ResultSet rs,String n)throws java.sql.SQLException{long v=rs.getLong(n);return rs.wasNull()?null:v;}
    private static Long nullableLong(java.sql.ResultSet rs,int n)throws java.sql.SQLException{long v=rs.getLong(n);return rs.wasNull()?null:v;}
    private static LocalDate localDate(java.sql.ResultSet rs,String n)throws java.sql.SQLException{java.sql.Date v=rs.getDate(n);return v==null?null:v.toLocalDate();}
    private static LocalDate localDate(java.sql.ResultSet rs,int n)throws java.sql.SQLException{java.sql.Date v=rs.getDate(n);return v==null?null:v.toLocalDate();}
    private static LocalDateTime localDateTime(java.sql.ResultSet rs,int n)throws java.sql.SQLException{java.sql.Timestamp v=rs.getTimestamp(n);return v==null?null:v.toLocalDateTime();}
    private static String trim(String v){return v==null||v.isBlank()?null:v.trim();}
    private static String required(String v,String m){if(v==null||v.isBlank())throw new BusinessFailure(m);return v.trim();}
    private static String currency(String v){return v==null||v.isBlank()?"PEN":v.trim().toUpperCase(Locale.ROOT);}
    private static final Long INVALID_SCOPE=Long.MIN_VALUE;
    private static final class BusinessFailure extends com.franco.desco.application.shared.BusinessRuleViolation {
        private BusinessFailure(String message) { super(message); }
    }
}
