package com.franco.desco.application.resource.service;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.resource.ResourceModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
public class ResourceReadService {

    private final JdbcTemplate jdbc;
    private final SimpleJdbcCall assetsCall;
    private final SimpleJdbcCall productsCall;
    private final SimpleJdbcCall productDetailCall;

    public ResourceReadService(DataSource dataSource) {
        this.jdbc = new JdbcTemplate(dataSource);
        this.assetsCall = base(dataSource, "PA_BienInventario_Sel_ListadoPaginado",
                in("nUsuarioId", Types.BIGINT), in("nSesionUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT),
                in("cBuscar", Types.NVARCHAR), in("nTipoBienId", Types.INTEGER), in("cEstado", Types.VARCHAR),
                in("nPagina", Types.INTEGER), in("nTamano", Types.INTEGER))
                .returningResultSet("items", this::mapAsset);
        this.productsCall = base(dataSource, "PA_Producto_Sel_ListadoPaginado",
                in("nUsuarioId", Types.BIGINT), in("nSesionUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT),
                in("cBuscar", Types.NVARCHAR), in("cCategoria", Types.VARCHAR), in("bEstado", Types.BIT),
                in("nPagina", Types.INTEGER), in("nTamano", Types.INTEGER))
                .returningResultSet("items", this::mapProduct);
        this.productDetailCall = base(dataSource, "PA_Producto_Sel_DetalleUOT",
                in("nUsuarioId", Types.BIGINT), in("nSesionUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT),
                in("nProductoId", Types.BIGINT))
                .returningResultSet("items", this::mapProductDetail);
    }

    public AppResult<PageResult<ResourceModels.AssetListItem>> assets(
            SessionIdentity identity, Long uotId, String search, Integer assetTypeId, String state, int page, int size) {
        MapSqlParameterSource parameters = session(identity);
        if (parameters == null) return sessionUnavailable();
        try {
            Map<String, Object> out = assetsCall.execute(parameters
                    .addValue("nUotId", uotId).addValue("cBuscar", trim(search)).addValue("nTipoBienId", assetTypeId)
                    .addValue("cEstado", trim(state)).addValue("nPagina", page).addValue("nTamano", size));
            if (!ok(out)) return error(out, "BIENES_NO_LISTADOS", "No se pudo consultar el inventario.");
            List<ResourceModels.AssetListItem> items = list(out, "items");
            return AppResult.ok(code(out, "BIENES_LISTADOS"), message(out, "Inventario consultado."), page(items, page, size));
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "BIENES_NO_LISTADOS", "No se pudo consultar el inventario.");
        }
    }

    public AppResult<PageResult<ResourceModels.ProductListItem>> products(
            SessionIdentity identity, Long uotId, String search, String category, Boolean active, int page, int size) {
        MapSqlParameterSource parameters = session(identity);
        if (parameters == null) return sessionUnavailable();
        try {
            Map<String, Object> out = productsCall.execute(parameters
                    .addValue("nUotId", uotId).addValue("cBuscar", trim(search)).addValue("cCategoria", trim(category))
                    .addValue("bEstado", active).addValue("nPagina", page).addValue("nTamano", size));
            if (!ok(out)) return error(out, "PRODUCTOS_NO_LISTADOS", "No se pudieron consultar los productos.");
            List<ResourceModels.ProductListItem> items = list(out, "items");
            return AppResult.ok(code(out, "PRODUCTOS_LISTADOS"), message(out, "Productos consultados."), page(items, page, size));
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "PRODUCTOS_NO_LISTADOS", "No se pudieron consultar los productos.");
        }
    }

    public AppResult<ResourceModels.ProductDetail> product(SessionIdentity identity, Long uotId, Long productId) {
        MapSqlParameterSource parameters = session(identity);
        if (parameters == null) return sessionUnavailable();
        try {
            Map<String, Object> out = productDetailCall.execute(parameters.addValue("nUotId", uotId).addValue("nProductoId", productId));
            if (!ok(out)) return error(out, "PRODUCTO_NO_DISPONIBLE", "El producto no está disponible.");
            List<ResourceModels.ProductDetail> items = list(out, "items");
            if (items.isEmpty()) return AppResult.error(AppStatus.NOT_FOUND, "PRODUCTO_NO_DISPONIBLE", "El producto no está disponible.");
            ResourceModels.ProductDetail item = items.getFirst();
            List<Long> imageIds = jdbc.query(
                    """
                    SELECT PI.archivo_id
                    FROM logistica.ProductoImagen PI
                    INNER JOIN archivo.Archivo A
                        ON A.archivo_id = PI.archivo_id
                       AND A.estado = 1
                       AND A.uot_id = ?
                    WHERE PI.producto_id = ?
                      AND PI.estado = 1
                    ORDER BY PI.es_principal DESC, PI.orden, PI.producto_imagen_id
                    """,
                    (rs, rowNum) -> rs.getLong(1),
                    uotId,
                    productId
            );
            ResourceModels.ProductDetail enriched = new ResourceModels.ProductDetail(
                    item.productId(), item.uotId(), item.uotCode(), item.uotName(), item.code(),
                    item.name(), item.description(), item.unitCode(), item.unitName(), item.categoryCode(),
                    item.categoryName(), item.requiresLot(), item.controlsExpiration(), item.allowsSale(), item.initialPrice(),
                    item.currentPrice(), item.currency(), item.currentPriceId(), item.currentPriceVersion(),
                    item.mainImageFileId(), imageIds, item.active()
            );
            return AppResult.ok(code(out, "PRODUCTO_OBTENIDO"), message(out, "Producto consultado."), enriched);
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "PRODUCTO_NO_DISPONIBLE", "No se pudo consultar el producto.");
        }
    }

    private MapSqlParameterSource session(SessionIdentity identity) {
        if (identity == null || identity.usuarioId() == null || identity.sesionPublicaId() == null) return null;
        List<Long> ids = jdbc.query("""
                SELECT sesion_usuario_id FROM seg.SesionUsuario
                WHERE sesion_publica_id=? AND usuario_id=? AND estado=1 AND fecha_revocacion IS NULL
                """, (rs, rowNum) -> rs.getLong(1), identity.sesionPublicaId(), identity.usuarioId());
        if (ids.isEmpty()) return null;
        return new MapSqlParameterSource().addValue("nUsuarioId", identity.usuarioId()).addValue("nSesionUsuarioId", ids.getFirst());
    }

    private ResourceModels.AssetListItem mapAsset(ResultSet rs, int row) throws SQLException {
        return new ResourceModels.AssetListItem(
                nullableLong(rs,"bienInventarioId"), nullableLong(rs,"uotId"), rs.getString("uotCodigo"), rs.getString("uotNombre"),
                nullableInteger(rs,"tipoBienId"), rs.getString("tipoBienCodigo"), rs.getString("tipoBien"), rs.getString("codigoPatrimonial"),
                rs.getString("nombre"), rs.getString("marca"), rs.getString("modelo"), rs.getString("serie"), rs.getString("estadoBien"),
                date(rs,"fechaAdquisicion"), rs.getBigDecimal("montoAdquisicion"), rs.getString("monedaAdquisicion"),
                nullableLong(rs,"proveedorPersonaId"), nullableLong(rs,"proveedorEmpresaId"), rs.getString("proveedorNombre"), rs.getString("observacion"),
                rs.getString("placa"), rs.getString("tipoVehiculo"), rs.getBigDecimal("kilometrajeKm"), rs.getString("color"), nullableLong(rs,"archivoPrincipalId"),
                rs.getInt("incidentesAbiertos"), rs.getBoolean("estado"), rs.getLong("totalRegistros"));
    }

    private ResourceModels.ProductListItem mapProduct(ResultSet rs, int row) throws SQLException {
        return new ResourceModels.ProductListItem(
                nullableLong(rs,"productoId"), nullableLong(rs,"uotId"), rs.getString("uotCodigo"), rs.getString("uotNombre"), rs.getString("codigo"),
                rs.getString("nombre"), rs.getString("descripcion"), rs.getString("unidadMedidaCodigo"), rs.getString("unidadMedidaNombre"),
                rs.getString("categoriaCodigo"), rs.getString("categoriaNombre"), rs.getBoolean("requiereLote"), rs.getBoolean("controlaVencimiento"), rs.getBoolean("permiteVenta"),
                rs.getBigDecimal("precioInicial"), rs.getBigDecimal("precioVenta"), rs.getString("moneda"), nullableLong(rs,"productoPrecioId"), nullableInteger(rs,"precioVersion"),
                nullableLong(rs,"archivoPrincipalId"), rs.getBoolean("estado"), rs.getLong("totalRegistros"));
    }

    private ResourceModels.ProductDetail mapProductDetail(ResultSet rs, int row) throws SQLException {
        return new ResourceModels.ProductDetail(
                nullableLong(rs,"productoId"), nullableLong(rs,"uotId"), rs.getString("uotCodigo"), rs.getString("uotNombre"), rs.getString("codigo"),
                rs.getString("nombre"), rs.getString("descripcion"), rs.getString("unidadMedidaCodigo"), rs.getString("unidadMedidaNombre"),
                rs.getString("categoriaCodigo"), rs.getString("categoriaNombre"), rs.getBoolean("requiereLote"), rs.getBoolean("controlaVencimiento"), rs.getBoolean("permiteVenta"),
                rs.getBigDecimal("precioInicial"), rs.getBigDecimal("precioVenta"), rs.getString("moneda"), nullableLong(rs,"productoPrecioId"), nullableInteger(rs,"precioVersion"),
                nullableLong(rs,"archivoPrincipalId"), List.of(), rs.getBoolean("estado")
        );
    }

    private static SimpleJdbcCall base(DataSource ds, String procedure, SqlParameter... parameters) {
        SqlParameter[] all = new SqlParameter[parameters.length + 4];
        System.arraycopy(parameters,0,all,0,parameters.length);
        all[parameters.length]=new SqlOutParameter("bResultado",Types.BIT);
        all[parameters.length+1]=new SqlOutParameter("cMensaje",Types.NVARCHAR);
        all[parameters.length+2]=new SqlOutParameter("cCodigoRespuesta",Types.VARCHAR);
        all[parameters.length+3]=new SqlOutParameter("nHttpRespuesta",Types.SMALLINT);
        return new SimpleJdbcCall(ds).withSchemaName("logistica").withProcedureName(procedure).withoutProcedureColumnMetaDataAccess().declareParameters(all);
    }
    private static SqlParameter in(String name,int type){return new SqlParameter(name,type);}
    @SuppressWarnings("unchecked") private static <T> List<T> list(Map<String,Object> out,String key){Object v=out.get(key);return v instanceof List<?> l?(List<T>)l:List.of();}
    private static <T> PageResult<T> page(List<T> items,int page,int size){
        long total=items.isEmpty()?0:total(items.getFirst());
        int pages=total==0?0:(int)Math.ceil((double)total/size);
        return new PageResult<>(items,page,size,total,pages);
    }
    private static long total(Object item){
        if(item instanceof ResourceModels.AssetListItem value) return value.totalRecords();
        if(item instanceof ResourceModels.ProductListItem value) return value.totalRecords();
        return 0;
    }
    private static boolean ok(Map<String,Object> out){Object v=out.get("bResultado");return v instanceof Boolean b?b:v instanceof Number n&&n.intValue()!=0;}
    private static String code(Map<String,Object> out,String f){Object v=out.get("cCodigoRespuesta");return v==null||v.toString().isBlank()?f:v.toString();}
    private static String message(Map<String,Object> out,String f){Object v=out.get("cMensaje");return v==null||v.toString().isBlank()?f:v.toString();}
    private static Integer http(Map<String,Object> out){Object v=out.get("nHttpRespuesta");return v instanceof Number n?n.intValue():400;}
    private static <T> AppResult<T> error(Map<String,Object> out,String c,String m){return AppResult.error(AppStatus.fromHttp(http(out),AppStatus.BAD_REQUEST),code(out,c),message(out,m));}
    private static <T> AppResult<T> sessionUnavailable(){return AppResult.error(AppStatus.UNAUTHORIZED,"SESION_NO_DISPONIBLE","La sesión ya no está disponible. Inicie sesión nuevamente.");}
    private static String trim(String value){if(value==null)return null;String s=value.trim();return s.isEmpty()?null:s;}
    private static Long nullableLong(ResultSet rs,String c)throws SQLException{long v=rs.getLong(c);return rs.wasNull()?null:v;}
    private static Integer nullableInteger(ResultSet rs,String c)throws SQLException{int v=rs.getInt(c);return rs.wasNull()?null:v;}
    private static LocalDate date(ResultSet rs,String c)throws SQLException{var v=rs.getDate(c);return v==null?null:v.toLocalDate();}
}
