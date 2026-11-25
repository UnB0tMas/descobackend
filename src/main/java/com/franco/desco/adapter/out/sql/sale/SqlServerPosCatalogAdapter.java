package com.franco.desco.adapter.out.sql.sale;

import com.franco.desco.adapter.out.sqlserver.shared.LoggedSimpleJdbcCall;
import com.franco.desco.application.sale.port.out.PosCatalogPort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.sale.PosCatalogModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Types;
import java.util.List;
import java.util.Map;

@Repository
public class SqlServerPosCatalogAdapter implements PosCatalogPort {
    private final SimpleJdbcCall call;

    public SqlServerPosCatalogAdapter(JdbcTemplate jdbc) {
        this.call = new LoggedSimpleJdbcCall(jdbc, "comercial.PA_Pos_Sel_CatalogoOperativo")
                .withSchemaName("comercial")
                .withProcedureName("PA_Pos_Sel_CatalogoOperativo")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("nUsuarioId", Types.BIGINT),
                        new SqlParameter("gSesionPublicaId", -145),
                        new SqlParameter("nUotId", Types.BIGINT),
                        new SqlParameter("nAlmacenId", Types.BIGINT),
                        new SqlParameter("bUsoInterno", Types.BIT),
                        new SqlOutParameter("bResultado", Types.BIT),
                        new SqlOutParameter("cMensaje", Types.NVARCHAR),
                        new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR),
                        new SqlOutParameter("nHttpRespuesta", Types.SMALLINT))
                .returningResultSet("warehouses", (rs, row) -> new PosCatalogModels.Warehouse(
                        rs.getLong("warehouseId"), rs.getString("code"), rs.getString("name")))
                .returningResultSet("products", (rs, row) -> new PosCatalogModels.Product(
                        rs.getLong("productId"), rs.getString("code"), rs.getString("name"),
                        rs.getString("description"), rs.getString("unit"), rs.getString("category"),
                        rs.getBigDecimal("unitPrice"), rs.getBigDecimal("initialPrice"),
                        rs.getString("currency"), rs.getBigDecimal("stockAvailable"),
                        rs.getObject("imageFileId") == null ? null : rs.getLong("imageFileId"),
                        rs.getString("imageUrl")));
    }

    @Override
    @SuppressWarnings("unchecked")
    public PersistenceResult<PosCatalogModels.Catalog> list(SessionIdentity identity, Long uotId,
                                                             Long warehouseId, boolean internal) {
        if (identity == null || identity.usuarioId() == null || identity.sesionPublicaId() == null
                || uotId == null || uotId <= 0 || (warehouseId != null && warehouseId <= 0)) {
            return PersistenceResult.error("POS_CATALOGO_NO_DISPONIBLE",
                    "No se pudo consultar el catálogo.", 400);
        }
        try {
            Map<String, Object> out = call.execute(new MapSqlParameterSource()
                    .addValue("nUsuarioId", identity.usuarioId())
                    .addValue("gSesionPublicaId", identity.sesionPublicaId().toString())
                    .addValue("nUotId", uotId)
                    .addValue("nAlmacenId", warehouseId)
                    .addValue("bUsoInterno", internal));
            boolean success = Boolean.TRUE.equals(out.get("bResultado"))
                    || out.get("bResultado") instanceof Number n && n.intValue() == 1;
            String code = String.valueOf(out.getOrDefault("cCodigoRespuesta", "POS_CATALOGO_NO_DISPONIBLE"));
            String message = String.valueOf(out.getOrDefault("cMensaje", "No se pudo consultar el catálogo."));
            int http = out.get("nHttpRespuesta") instanceof Number n ? n.intValue() : (success ? 200 : 400);
            if (!success) return PersistenceResult.error(code, message, http);
            List<PosCatalogModels.Warehouse> warehouses = (List<PosCatalogModels.Warehouse>) out.get("warehouses");
            List<PosCatalogModels.Product> products = (List<PosCatalogModels.Product>) out.get("products");
            return PersistenceResult.ok(code, message, 200,
                    new PosCatalogModels.Catalog(warehouses == null ? List.of() : warehouses,
                            products == null ? List.of() : products));
        } catch (DataAccessException ex) {
            return PersistenceResult.error("POS_CATALOGO_NO_DISPONIBLE",
                    "No se pudo consultar el catálogo.", 503);
        }
    }
}
