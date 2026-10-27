package com.franco.desco.application.resource.service;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.resource.ResourceModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.List;
import java.util.Map;

@Service
public class ProductPriceHistoryService {

    private final SimpleJdbcCall historyCall;

    public ProductPriceHistoryService(JdbcTemplate jdbcTemplate) {
        this.historyCall = new SimpleJdbcCall(jdbcTemplate)
                .withSchemaName("logistica")
                .withProcedureName("PA_ProductoPrecio_Sel_Historial")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("nUsuarioId", Types.BIGINT),
                        new SqlParameter("nUotId", Types.BIGINT),
                        new SqlParameter("nProductoId", Types.BIGINT),
                        new SqlOutParameter("bResultado", Types.BIT),
                        new SqlOutParameter("cMensaje", Types.NVARCHAR),
                        new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR),
                        new SqlOutParameter("nHttpRespuesta", Types.SMALLINT)
                )
                .returningResultSet("historial", this::mapHistory);
    }

    public AppResult<List<ResourceModels.PriceHistory>> list(
            SessionIdentity identity,
            Long uotId,
            Long productId
    ) {
        if (uotId == null || productId == null) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "HISTORIAL_PRECIOS_NO_LISTADO",
                    "Seleccione una UOT y un producto."
            );
        }

        Map<String, Object> out;
        try {
            out = historyCall.execute(
                    Map.of(
                            "nUsuarioId", identity.usuarioId(),
                            "nUotId", uotId,
                            "nProductoId", productId
                    )
            );
        } catch (DataAccessException exception) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "HISTORIAL_PRECIOS_NO_DISPONIBLE",
                    "No se pudo consultar el historial de precios."
            );
        }

        String message = text(out.get("cMensaje"), "No se pudo consultar el historial de precios.");
        String code = text(out.get("cCodigoRespuesta"), "HISTORIAL_PRECIOS_NO_LISTADO");

        if (!success(out.get("bResultado"))) {
            return AppResult.error(AppStatus.BAD_REQUEST, code, message);
        }

        @SuppressWarnings("unchecked")
        List<ResourceModels.PriceHistory> values =
                (List<ResourceModels.PriceHistory>) out.getOrDefault("historial", List.of());

        return AppResult.ok(code, message, values == null ? List.of() : List.copyOf(values));
    }

    private ResourceModels.PriceHistory mapHistory(ResultSet resultSet, int rowNumber) throws SQLException {
        var from = resultSet.getTimestamp("fechaDesde");
        var to = resultSet.getTimestamp("fechaHasta");

        return new ResourceModels.PriceHistory(
                nullableLong(resultSet, "productoPrecioId"),
                nullableLong(resultSet, "productoId"),
                resultSet.getString("productoCodigo"),
                resultSet.getString("producto"),
                nullableLong(resultSet, "uotId"),
                resultSet.getString("uotCodigo"),
                resultSet.getString("uotNombre"),
                resultSet.getBigDecimal("precioVenta"),
                resultSet.getString("moneda"),
                nullableInteger(resultSet, "version"),
                from == null ? null : from.toLocalDateTime(),
                to == null ? null : to.toLocalDateTime(),
                resultSet.getBoolean("vigente"),
                nullableLong(resultSet, "usuarioId"),
                resultSet.getString("nombreUsuario")
        );
    }

    private static Long nullableLong(ResultSet resultSet, String column) throws SQLException {
        long value = resultSet.getLong(column);
        return resultSet.wasNull() ? null : value;
    }

    private static Integer nullableInteger(ResultSet resultSet, String column) throws SQLException {
        int value = resultSet.getInt(column);
        return resultSet.wasNull() ? null : value;
    }

    private static boolean success(Object value) {
        if (value instanceof Boolean bool) {
            return bool;
        }
        return value instanceof Number number && number.intValue() != 0;
    }

    private static String text(Object value, String fallback) {
        return value == null || value.toString().isBlank() ? fallback : value.toString().trim();
    }
}
