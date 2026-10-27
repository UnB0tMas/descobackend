package com.franco.desco.application.resource.service;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.resource.ResourceModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.math.BigDecimal;
import java.sql.Types;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ProductPriceHistoryService {

    private static final int SQL_SERVER_GUID = -145;

    private final SimpleJdbcCall historyCall;
    private final SimpleJdbcCall versionCall;
    private final SimpleJdbcCall reactivateCall;

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


        this.versionCall = new SimpleJdbcCall(jdbcTemplate)
                .withSchemaName("logistica")
                .withProcedureName("PA_ProductoPrecio_Ins_VersionComercial")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("nUsuarioId", Types.BIGINT),
                        new SqlParameter("nUotIdContexto", Types.BIGINT),
                        new SqlParameter("nProductoId", Types.BIGINT),
                        new SqlParameter("nUotPrecioId", Types.BIGINT),
                        new SqlParameter("nPrecioInicial", Types.DECIMAL),
                        new SqlParameter("nPrecioVenta", Types.DECIMAL),
                        new SqlParameter("cMoneda", Types.CHAR),
                        new SqlParameter("gClaveIdempotencia", SQL_SERVER_GUID),
                        new SqlOutParameter("nProductoPrecioId", Types.BIGINT),
                        new SqlOutParameter("bResultado", Types.BIT),
                        new SqlOutParameter("cMensaje", Types.NVARCHAR),
                        new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR),
                        new SqlOutParameter("nHttpRespuesta", Types.SMALLINT)
                );

        this.reactivateCall = new SimpleJdbcCall(jdbcTemplate)
                .withSchemaName("logistica")
                .withProcedureName("PA_ProductoPrecio_Ins_ReactivarVersion")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("nUsuarioId", Types.BIGINT),
                        new SqlParameter("nUotId", Types.BIGINT),
                        new SqlParameter("nProductoId", Types.BIGINT),
                        new SqlParameter("nPrecioOrigenId", Types.BIGINT),
                        new SqlParameter("gClaveIdempotencia", SQL_SERVER_GUID),
                        new SqlOutParameter("nProductoPrecioId", Types.BIGINT),
                        new SqlOutParameter("nVersionNueva", Types.INTEGER),
                        new SqlOutParameter("bResultado", Types.BIT),
                        new SqlOutParameter("cMensaje", Types.NVARCHAR),
                        new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR),
                        new SqlOutParameter("nHttpRespuesta", Types.SMALLINT)
                );
    }

    public AppResult<List<ResourceModels.PriceHistory>> list(
            SessionIdentity identity,
            Long uotId,
            Long productId
    ) {
        if (identity == null || identity.usuarioId() == null || uotId == null || productId == null) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "HISTORIAL_PRECIOS_NO_LISTADO",
                    "Seleccione una UOT y un producto."
            );
        }

        try {
            Map<String, Object> out = historyCall.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("nUotId", uotId)
                            .addValue("nProductoId", productId)
            );

            if (!success(out.get("bResultado"))) {
                return error(
                        out,
                        "HISTORIAL_PRECIOS_NO_LISTADO",
                        "No se pudo consultar el historial de precios."
                );
            }

            @SuppressWarnings("unchecked")
            List<ResourceModels.PriceHistory> values =
                    (List<ResourceModels.PriceHistory>) out.getOrDefault("historial", List.of());

            return AppResult.ok(
                    text(out.get("cCodigoRespuesta"), "HISTORIAL_PRECIOS_LISTADO"),
                    text(out.get("cMensaje"), "Historial de precios consultado."),
                    values == null ? List.of() : List.copyOf(values)
            );
        } catch (DataAccessException exception) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "HISTORIAL_PRECIOS_NO_DISPONIBLE",
                    "No se pudo consultar el historial de precios."
            );
        }
    }

    public AppResult<Long> version(
            SessionIdentity identity,
            Long contextUotId,
            Long productId,
            Long priceUotId,
            BigDecimal initialPrice,
            BigDecimal salePrice,
            String currency,
            UUID idempotencyKey
    ) {
        if (identity == null || identity.usuarioId() == null
                || contextUotId == null || productId == null || priceUotId == null
                || initialPrice == null || salePrice == null || idempotencyKey == null) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "PRECIO_NO_REGISTRADO",
                    "Complete correctamente los datos del precio."
            );
        }

        try {
            Map<String, Object> out = versionCall.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("nUotIdContexto", contextUotId)
                            .addValue("nProductoId", productId)
                            .addValue("nUotPrecioId", priceUotId)
                            .addValue("nPrecioInicial", initialPrice)
                            .addValue("nPrecioVenta", salePrice)
                            .addValue("cMoneda", currency == null ? null : currency.trim().toUpperCase())
                            .addValue("gClaveIdempotencia", idempotencyKey.toString())
            );

            if (!success(out.get("bResultado"))) {
                return error(out, "PRECIO_NO_REGISTRADO", "No se pudo registrar el precio.");
            }

            Long priceId = nullableLong(out.get("nProductoPrecioId"));
            if (priceId == null) {
                return AppResult.error(
                        AppStatus.SERVICE_UNAVAILABLE,
                        "PRECIO_NO_REGISTRADO",
                        "No se pudo obtener la versión de precio registrada."
                );
            }

            AppStatus status = AppStatus.fromHttp(http(out), AppStatus.CREATED);
            String code = text(out.get("cCodigoRespuesta"), "PRECIO_REGISTRADO");
            String message = text(out.get("cMensaje"), "Precio registrado correctamente.");
            return status == AppStatus.CREATED
                    ? AppResult.created(code, message, priceId)
                    : AppResult.ok(code, message, priceId);
        } catch (DataAccessException exception) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "PRECIO_NO_REGISTRADO",
                    "No se pudo registrar el precio."
            );
        }
    }

    public AppResult<ResourceModels.PriceReactivation> reactivate(
            SessionIdentity identity,
            Long uotId,
            Long productId,
            Long sourcePriceId,
            UUID idempotencyKey
    ) {
        if (identity == null || identity.usuarioId() == null
                || uotId == null || productId == null || sourcePriceId == null || idempotencyKey == null) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "PRECIO_NO_REACTIVADO",
                    "Complete correctamente los datos del precio."
            );
        }

        try {
            Map<String, Object> out = reactivateCall.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("nUotId", uotId)
                            .addValue("nProductoId", productId)
                            .addValue("nPrecioOrigenId", sourcePriceId)
                            .addValue("gClaveIdempotencia", idempotencyKey.toString())
            );

            if (!success(out.get("bResultado"))) {
                return error(
                        out,
                        "PRECIO_NO_REACTIVADO",
                        "No se pudo reactivar el precio."
                );
            }

            Long newPriceId = nullableLong(out.get("nProductoPrecioId"));
            Integer newVersion = nullableInteger(out.get("nVersionNueva"));
            if (newPriceId == null || newVersion == null) {
                return AppResult.error(
                        AppStatus.SERVICE_UNAVAILABLE,
                        "PRECIO_NO_REACTIVADO",
                        "No se pudo obtener la nueva versión del precio."
                );
            }

            ResourceModels.PriceReactivation data = new ResourceModels.PriceReactivation(
                    newPriceId,
                    newVersion,
                    sourcePriceId
            );
            AppStatus status = AppStatus.fromHttp(http(out), AppStatus.CREATED);
            String code = text(out.get("cCodigoRespuesta"), "PRECIO_REACTIVADO");
            String message = text(out.get("cMensaje"), "Precio reactivado como nueva versión vigente.");

            return status == AppStatus.CREATED
                    ? AppResult.created(code, message, data)
                    : AppResult.ok(code, message, data);
        } catch (DataAccessException exception) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "PRECIO_NO_REACTIVADO",
                    "No se pudo reactivar el precio."
            );
        }
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
                resultSet.getBigDecimal("precioInicial"),
                resultSet.getBigDecimal("precioVenta"),
                resultSet.getString("moneda"),
                nullableInteger(resultSet, "version"),
                from == null ? null : from.toLocalDateTime(),
                to == null ? null : to.toLocalDateTime(),
                resultSet.getBoolean("vigente"),
                nullableLong(resultSet, "usuarioId"),
                resultSet.getString("nombreUsuario"),
                nullableLong(resultSet, "precioOrigenId"),
                nullableInteger(resultSet, "precioOrigenVersion")
        );
    }

    private static <T> AppResult<T> error(
            Map<String, Object> out,
            String fallbackCode,
            String fallbackMessage
    ) {
        return AppResult.error(
                AppStatus.fromHttp(http(out), AppStatus.BAD_REQUEST),
                text(out.get("cCodigoRespuesta"), fallbackCode),
                text(out.get("cMensaje"), fallbackMessage)
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

    private static Long nullableLong(Object value) {
        return value instanceof Number number ? number.longValue() : null;
    }

    private static Integer nullableInteger(Object value) {
        return value instanceof Number number ? number.intValue() : null;
    }

    private static Integer http(Map<String, Object> out) {
        Object value = out.get("nHttpRespuesta");
        return value instanceof Number number ? number.intValue() : null;
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
