package com.franco.desco.application.resource.service;

import com.franco.desco.application.resource.ResourceCommands;
import com.franco.desco.application.resource.port.in.ResourceUseCase;
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

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.Types;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
public class ResourceExperienceService {

    private static final int SQL_SERVER_GUID = -145;

    private final ResourceUseCase resources;
    private final JdbcTemplate jdbc;
    private final SimpleJdbcCall suggestedCode;
    private final SimpleJdbcCall resolveLocation;
    private final SimpleJdbcCall configureWarehouseProduct;
    private final SimpleJdbcCall createCatalogProduct;
    private final SimpleJdbcCall updateProduct;
    private final SimpleJdbcCall deactivateProduct;
    private final SimpleJdbcCall reactivateProduct;
    private final SimpleJdbcCall manageWarehouseProduct;

    public ResourceExperienceService(
            ResourceUseCase resources,
            DataSource dataSource
    ) {
        this.resources = resources;
        this.jdbc = new JdbcTemplate(dataSource);
        this.manageWarehouseProduct = base(dataSource, "logistica", "PA_AlmacenProducto_Upd_Configuracion",
                in("nUsuarioId", Types.BIGINT), in("nSesionUsuarioId", Types.BIGINT), in("nUotId", Types.BIGINT),
                in("nAlmacenId", Types.BIGINT), in("nProductoId", Types.BIGINT), in("cOperacion", Types.VARCHAR),
                in("nStockMinimo", Types.DECIMAL), in("cMotivo", Types.NVARCHAR), in("gClaveIdempotencia", SQL_SERVER_GUID));

        this.suggestedCode = base(
                dataSource,
                "logistica",
                "PA_Recurso_Sel_CodigoSugerido",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("cTipo", Types.VARCHAR),
                new SqlOutParameter("cCodigo", Types.VARCHAR)
        );

        this.resolveLocation = base(
                dataSource,
                "geo",
                "PA_Ubicacion_Ins_ResolverRecurso",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("cDistritoCodigo", Types.CHAR),
                in("nCentroPobladoId", Types.BIGINT),
                in("cReferencia", Types.NVARCHAR),
                new SqlOutParameter("nUbicacionId", Types.BIGINT)
        );

        this.createCatalogProduct = new SimpleJdbcCall(dataSource)
                .withSchemaName("logistica")
                .withProcedureName("PA_Producto_Ins_Catalogo")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        in("nUsuarioId", Types.BIGINT),
                        in("nUotId", Types.BIGINT),
                        in("cCodigo", Types.VARCHAR),
                        in("cNombre", Types.NVARCHAR),
                        in("cDescripcion", Types.NVARCHAR),
                        in("cUnidad", Types.VARCHAR),
                        in("cCategoria", Types.NVARCHAR),
                        in("bPermiteVenta", Types.BIT),
                        in("nPrecioVenta", Types.DECIMAL), in("cMonedaVenta", Types.CHAR),
                        in("gClaveIdempotencia", SQL_SERVER_GUID),
                        new SqlOutParameter("nProductoId", Types.BIGINT),
                        new SqlOutParameter("bResultado", Types.BIT),
                        new SqlOutParameter("cMensaje", Types.NVARCHAR),
                        new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR),
                        new SqlOutParameter("nHttpRespuesta", Types.SMALLINT),
                        in("bRequiereLote", Types.BIT), in("bControlaVencimiento", Types.BIT)
                );

        this.updateProduct = base(
                dataSource,
                "logistica",
                "PA_Producto_Upd_Registro",
                in("nUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nProductoId", Types.BIGINT),
                in("cNombre", Types.NVARCHAR),
                in("cDescripcion", Types.NVARCHAR),
                in("cUnidad", Types.VARCHAR),
                in("cCategoria", Types.VARCHAR),
                in("bRequiereLote", Types.BIT),
                in("bControlaVencimiento", Types.BIT),
                in("bPermiteVenta", Types.BIT),
                in("nPrecioVenta", Types.DECIMAL), in("cMonedaVenta", Types.CHAR)
        );

        this.deactivateProduct = base(
                dataSource,
                "logistica",
                "PA_Producto_Del_Registro",
                in("nUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nProductoId", Types.BIGINT)
        );

        this.reactivateProduct = base(
                dataSource,
                "logistica",
                "PA_Producto_Upd_Reactivar",
                in("nUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nProductoId", Types.BIGINT)
        );

        this.configureWarehouseProduct = base(
                dataSource,
                "logistica",
                "PA_AlmacenProducto_Ins_StockInicial",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nAlmacenId", Types.BIGINT),
                in("nProductoId", Types.BIGINT),
                in("nStockInicial", Types.DECIMAL),
                in("nStockMinimo", Types.DECIMAL),
                in("nCostoUnitario", Types.DECIMAL),
                in("nPrecioVenta", Types.DECIMAL),
                in("cMoneda", Types.CHAR),
                in("cLote", Types.VARCHAR),
                in("dFechaVencimiento", Types.DATE),
                in("gClaveIdempotencia", SQL_SERVER_GUID),
                in("nArchivoSustentoId", Types.BIGINT),
                in("cDocumento", Types.NVARCHAR),
                in("cObservacion", Types.NVARCHAR),
                in("cMonedaVenta", Types.CHAR),
                new SqlOutParameter("nMovimientoId", Types.BIGINT),
                new SqlOutParameter("nStockActual", Types.DECIMAL),
                new SqlOutParameter("nStockMinimoFinal", Types.DECIMAL)
        );
    }

    public AppResult<ResourceModels.CodeSuggestion> suggestedCode(
            SessionIdentity identity,
            Long uotId,
            String type
    ) {
        String normalizedType = normalizeType(type);
        if (normalizedType == null) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "TIPO_RECURSO_NO_VALIDO",
                    "El tipo de recurso no es válido."
            );
        }

        MapSqlParameterSource parameters = sessionParameters(identity);
        if (parameters == null) {
            return sessionUnavailable();
        }

        try {
            Map<String, Object> output = suggestedCode.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("cTipo", normalizedType)
            );

            if (!ok(output)) {
                return databaseError(output);
            }

            String code = text(output.get("cCodigo"));
            if (code == null) {
                return AppResult.error(
                        AppStatus.SERVICE_UNAVAILABLE,
                        "CODIGO_NO_GENERADO",
                        "No se pudo generar el código."
                );
            }

            return AppResult.ok(
                    responseCode(output, "CODIGO_SUGERIDO"),
                    message(output, "Código sugerido generado."),
                    new ResourceModels.CodeSuggestion(uotId, normalizedType, code)
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    public AppResult<Long> createAsset(
            SessionIdentity identity,
            ResourceCommands.CreateAsset command
    ) {
        AppResult<String> codeResult = codeOrSuggested(
                identity,
                command.uotId(),
                "BIEN",
                command.patrimonialCode()
        );
        if (!codeResult.exitoso()) {
            return copyError(codeResult);
        }

        ResourceCommands.CreateAsset normalized = new ResourceCommands.CreateAsset(
                command.uotId(),
                command.assetTypeId(),
                codeResult.datos(),
                command.name(),
                command.brand(),
                command.model(),
                command.serial(),
                command.acquisitionDate(),
                command.acquisitionAmount(),
                command.currency(),
                command.providerPersonId(),
                command.providerCompanyId(),
                command.observation(),
                command.vehicle(),
                command.idempotencyKey()
        );

        return resources.createAsset(identity, normalized);
    }

    public AppResult<Long> createProduct(
            SessionIdentity identity,
            ResourceCommands.CreateProduct command,
            boolean allowsSale, BigDecimal salePrice, String saleCurrency,
            boolean requiresLot, boolean controlsExpiration
    ) {
        AppResult<String> codeResult = codeOrSuggested(
                identity,
                command.contextUotId(),
                "PRODUCTO",
                command.code()
        );
        if (!codeResult.exitoso()) {
            return copyError(codeResult);
        }

        if (identity == null || identity.usuarioId() == null) {
            return sessionUnavailable();
        }

        try {
            Map<String, Object> output = createCatalogProduct.execute(
                    new MapSqlParameterSource()
                            .addValue("nUsuarioId", identity.usuarioId())
                            .addValue("nUotId", command.contextUotId())
                            .addValue("cCodigo", codeResult.datos())
                            .addValue("bRequiereLote", requiresLot)
                            .addValue("bControlaVencimiento", controlsExpiration)
                            .addValue("cNombre", trimToNull(command.name()))
                            .addValue("cDescripcion", trimToNull(command.description()))
                            .addValue("cUnidad", trimToNull(command.unit()))
                            .addValue("cCategoria", trimToNull(command.category()))
                            .addValue("bPermiteVenta", allowsSale)
                            .addValue("nPrecioVenta", allowsSale ? salePrice : null)
                            .addValue("cMonedaVenta", allowsSale && saleCurrency != null ? saleCurrency.toUpperCase(Locale.ROOT) : null)
                            .addValue(
                                    "gClaveIdempotencia",
                                    command.idempotencyKey() == null ? null : command.idempotencyKey().toString()
                            )
            );

            if (!ok(output)) {
                return databaseError(output);
            }

            Long productId = longValue(output, "nProductoId");
            if (productId == null) {
                return AppResult.error(
                        AppStatus.SERVICE_UNAVAILABLE,
                        "PRODUCTO_NO_CREADO",
                        "No se pudo obtener el producto registrado."
                );
            }

            AppStatus status = AppStatus.fromHttp(http(output), AppStatus.CREATED);
            String code = responseCode(output, "PRODUCTO_CREADO");
            String message = message(output, "Producto agregado al catálogo.");
            return status == AppStatus.CREATED
                    ? AppResult.created(code, message, productId)
                    : AppResult.ok(code, message, productId);
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    public AppResult<Long> createWarehouse(
            SessionIdentity identity,
            Long uotId,
            String districtCode,
            Long populationCenterId,
            String reference,
            String requestedCode,
            String name,
            String description,
            UUID idempotencyKey
    ) {
        AppResult<String> codeResult = codeOrSuggested(
                identity,
                uotId,
                "ALMACEN",
                requestedCode
        );
        if (!codeResult.exitoso()) {
            return copyError(codeResult);
        }

        AppResult<Long> locationResult = resolveWarehouseLocation(
                identity,
                uotId,
                districtCode,
                populationCenterId,
                reference
        );
        if (!locationResult.exitoso()) {
            return copyError(locationResult);
        }

        return resources.createWarehouse(
                identity,
                new ResourceCommands.CreateWarehouse(
                        uotId,
                        locationResult.datos(),
                        codeResult.datos(),
                        name,
                        description,
                        idempotencyKey
                )
        );
    }

    public AppResult<Void> updateProduct(
            SessionIdentity identity,
            Long uotId,
            Long productId,
            String name,
            String description,
            String unit,
            String category,
            boolean requiresLot,
            boolean controlsExpiration,
            boolean allowsSale, BigDecimal salePrice, String saleCurrency
    ) {
        return executeProductWrite(
                updateProduct,
                identity,
                uotId,
                productId,
                parameters -> parameters
                        .addValue("cNombre", trimToNull(name))
                        .addValue("cDescripcion", trimToNull(description))
                        .addValue("cUnidad", trimToNull(unit))
                        .addValue("cCategoria", trimToNull(category))
                        .addValue("bRequiereLote", requiresLot)
                        .addValue("bControlaVencimiento", controlsExpiration)
                        .addValue("bPermiteVenta", allowsSale)
                            .addValue("nPrecioVenta", allowsSale ? salePrice : null)
                            .addValue("cMonedaVenta", allowsSale && saleCurrency != null ? saleCurrency.toUpperCase(Locale.ROOT) : null),
                "PRODUCTO_ACTUALIZADO",
                "Producto actualizado correctamente."
        );
    }

    public AppResult<Void> deactivateProduct(
            SessionIdentity identity,
            Long uotId,
            Long productId
    ) {
        return executeProductWrite(
                deactivateProduct, identity, uotId, productId,
                parameters -> parameters,
                "PRODUCTO_DESACTIVADO",
                "Producto desactivado correctamente."
        );
    }

    public AppResult<Void> reactivateProduct(
            SessionIdentity identity,
            Long uotId,
            Long productId
    ) {
        return executeProductWrite(
                reactivateProduct, identity, uotId, productId,
                parameters -> parameters,
                "PRODUCTO_REACTIVADO",
                "Producto reactivado correctamente."
        );
    }

    private AppResult<Void> executeProductWrite(
            SimpleJdbcCall call,
            SessionIdentity identity,
            Long uotId,
            Long productId,
            java.util.function.UnaryOperator<MapSqlParameterSource> customizer,
            String successCode,
            String successMessage
    ) {
        if (identity == null || identity.usuarioId() == null) {
            return sessionUnavailable();
        }

        try {
            MapSqlParameterSource parameters = new MapSqlParameterSource()
                    .addValue("nUsuarioId", identity.usuarioId())
                    .addValue("nUotId", uotId)
                    .addValue("nProductoId", productId);

            Map<String, Object> output = call.execute(customizer.apply(parameters));
            if (!ok(output)) {
                return databaseError(output);
            }

            return AppResult.ok(
                    responseCode(output, successCode),
                    message(output, successMessage),
                    null
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    public AppResult<Void> manageWarehouseProduct(SessionIdentity identity, Long uotId, Long warehouseId,
            Long productId, String operation, BigDecimal minimumStock, String reason, UUID key) {
        MapSqlParameterSource parameters = sessionParameters(identity);
        if (parameters == null) return sessionUnavailable();
        try {
            Map<String, Object> output = manageWarehouseProduct.execute(parameters
                    .addValue("nUotId", uotId).addValue("nAlmacenId", warehouseId).addValue("nProductoId", productId)
                    .addValue("cOperacion", operation).addValue("nStockMinimo", minimumStock)
                    .addValue("cMotivo", trimToNull(reason)).addValue("gClaveIdempotencia", key.toString()));
            if (!ok(output)) return databaseError(output);
            return AppResult.ok(responseCode(output, "ALMACEN_PRODUCTO_ACTUALIZADO"), message(output, "Configuración actualizada."), null);
        } catch (DataAccessException exception) { return unavailable(); }
    }

    public AppResult<ResourceModels.WarehouseProductConfiguration> configureWarehouseProduct(
            SessionIdentity identity,
            Long uotId,
            Long warehouseId,
            Long productId,
            BigDecimal initialStock,
            BigDecimal minimumStock,
            BigDecimal unitCost,
            BigDecimal salePrice,
            String currency,
            String lot,
            LocalDate expirationDate,
            UUID idempotencyKey,
            Long supportFileId,
            String observation, String saleCurrency
    ) {
        MapSqlParameterSource parameters = sessionParameters(identity);
        if (parameters == null) {
            return sessionUnavailable();
        }

        try {
            Map<String, Object> output = configureWarehouseProduct.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("nAlmacenId", warehouseId)
                            .addValue("nProductoId", productId)
                            .addValue("nStockInicial", initialStock)
                            .addValue("nStockMinimo", minimumStock)
                            .addValue("nCostoUnitario", unitCost)
                            .addValue("nPrecioVenta", salePrice)
                            .addValue("cMonedaVenta", normalizeCurrency(saleCurrency))
                            .addValue("cMoneda", normalizeCurrency(currency))
                            .addValue("cLote", trimToNull(lot))
                            .addValue("dFechaVencimiento", expirationDate)
                            .addValue(
                                    "gClaveIdempotencia",
                                    idempotencyKey == null ? null : idempotencyKey.toString()
                            )
                            .addValue("nArchivoSustentoId", supportFileId)
                            .addValue("cDocumento", null)
                            .addValue("cObservacion", trimToNull(observation))
            );

            if (!ok(output)) {
                return databaseError(output);
            }

            ResourceModels.WarehouseProductConfiguration data =
                    new ResourceModels.WarehouseProductConfiguration(
                            warehouseId,
                            productId,
                            longValue(output, "nMovimientoId"),
                            decimalValue(output, "nStockActual"),
                            decimalValue(output, "nStockMinimoFinal")
                    );

            AppStatus status = AppStatus.fromHttp(
                    http(output),
                    AppStatus.CREATED
            );

            if (status == AppStatus.CREATED) {
                return AppResult.created(
                        responseCode(output, "STOCK_INICIAL_REGISTRADO"),
                        message(output, "Producto configurado en el almacén."),
                        data
                );
            }

            return AppResult.ok(
                    responseCode(output, "STOCK_INICIAL_REGISTRADO"),
                    message(output, "Producto configurado en el almacén."),
                    data
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<Long> resolveWarehouseLocation(
            SessionIdentity identity,
            Long uotId,
            String districtCode,
            Long populationCenterId,
            String reference
    ) {
        MapSqlParameterSource parameters = sessionParameters(identity);
        if (parameters == null) {
            return sessionUnavailable();
        }

        try {
            Map<String, Object> output = resolveLocation.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("cDistritoCodigo", trimToNull(districtCode))
                            .addValue("nCentroPobladoId", populationCenterId)
                            .addValue("cReferencia", trimToNull(reference))
            );

            if (!ok(output)) {
                return databaseError(output);
            }

            Long locationId = longValue(output, "nUbicacionId");
            if (locationId == null) {
                return AppResult.error(
                        AppStatus.SERVICE_UNAVAILABLE,
                        "UBICACION_NO_RESUELTA",
                        "No se pudo resolver la ubicación del almacén."
                );
            }

            return AppResult.ok(
                    responseCode(output, "UBICACION_RESUELTA"),
                    message(output, "Ubicación validada."),
                    locationId
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<String> codeOrSuggested(
            SessionIdentity identity,
            Long uotId,
            String type,
            String requestedCode
    ) {
        String normalizedCode = trimToNull(requestedCode);
        if (normalizedCode != null) {
            return AppResult.ok(
                    "CODIGO_INFORMADO",
                    "Código validado.",
                    normalizedCode.toUpperCase(Locale.ROOT)
            );
        }

        AppResult<ResourceModels.CodeSuggestion> suggestion =
                suggestedCode(identity, uotId, type);

        if (!suggestion.exitoso()) {
            return copyError(suggestion);
        }

        return AppResult.ok(
                suggestion.codigo(),
                suggestion.mensaje(),
                suggestion.datos().code()
        );
    }

    private MapSqlParameterSource sessionParameters(
            SessionIdentity identity
    ) {
        if (identity == null
                || identity.usuarioId() == null
                || identity.sesionPublicaId() == null) {
            return null;
        }

        List<Long> values;
        try {
            values = jdbc.query(
                    """
                    SELECT sesion_usuario_id
                    FROM seg.SesionUsuario
                    WHERE sesion_publica_id = ?
                      AND usuario_id = ?
                      AND estado = 1
                      AND fecha_revocacion IS NULL
                    """,
                    (rs, rowNum) -> rs.getLong(1),
                    identity.sesionPublicaId(),
                    identity.usuarioId()
            );
        } catch (DataAccessException exception) {
            return null;
        }

        if (values.isEmpty()) {
            return null;
        }

        return new MapSqlParameterSource()
                .addValue("nUsuarioId", identity.usuarioId())
                .addValue("nSesionUsuarioId", values.getFirst());
    }

    private static SimpleJdbcCall base(
            DataSource dataSource,
            String schema,
            String procedure,
            SqlParameter... parameters
    ) {
        SqlParameter[] all = new SqlParameter[parameters.length + 4];
        System.arraycopy(parameters, 0, all, 0, parameters.length);
        all[parameters.length] = new SqlOutParameter("bResultado", Types.BIT);
        all[parameters.length + 1] = new SqlOutParameter("cMensaje", Types.NVARCHAR);
        all[parameters.length + 2] = new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR);
        all[parameters.length + 3] = new SqlOutParameter("nHttpRespuesta", Types.SMALLINT);

        return new SimpleJdbcCall(dataSource)
                .withSchemaName(schema)
                .withProcedureName(procedure)
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(all);
    }

    private static SqlParameter in(String name, int type) {
        return new SqlParameter(name, type);
    }

    private static String normalizeType(String value) {
        String normalized = trimToNull(value);
        if (normalized == null) {
            return null;
        }

        normalized = normalized.toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "BIEN", "PRODUCTO", "ALMACEN", "SUMINISTRO" -> normalized;
            default -> null;
        };
    }

    private static String normalizeCurrency(String value) {
        String normalized = trimToNull(value);
        return normalized == null
                ? null
                : normalized.toUpperCase(Locale.ROOT);
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }

        String normalized = value.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private static boolean ok(Map<String, Object> output) {
        Object value = output.get("bResultado");
        return value instanceof Boolean booleanValue
                ? booleanValue
                : value instanceof Number number
                && number.intValue() != 0;
    }

    private static String responseCode(
            Map<String, Object> output,
            String fallback
    ) {
        String value = text(output.get("cCodigoRespuesta"));
        return value == null ? fallback : value;
    }

    private static String message(
            Map<String, Object> output,
            String fallback
    ) {
        String value = text(output.get("cMensaje"));
        return value == null ? fallback : value;
    }

    private static Integer http(Map<String, Object> output) {
        Object value = output.get("nHttpRespuesta");
        return value instanceof Number number
                ? number.intValue()
                : null;
    }

    private static Long longValue(
            Map<String, Object> output,
            String key
    ) {
        Object value = output.get(key);
        return value instanceof Number number
                ? number.longValue()
                : null;
    }

    private static BigDecimal decimalValue(
            Map<String, Object> output,
            String key
    ) {
        Object value = output.get(key);
        if (value instanceof BigDecimal decimal) {
            return decimal;
        }
        if (value instanceof Number number) {
            return BigDecimal.valueOf(number.doubleValue());
        }
        return null;
    }

    private static String text(Object value) {
        if (value == null) {
            return null;
        }
        String normalized = value.toString().trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private static <T> AppResult<T> databaseError(
            Map<String, Object> output
    ) {
        return AppResult.error(
                AppStatus.fromHttp(http(output), AppStatus.BAD_REQUEST),
                responseCode(output, "OPERACION_NO_COMPLETADA"),
                message(output, "No se pudo completar la operación de recursos.")
        );
    }

    private static <T> AppResult<T> copyError(
            AppResult<?> source
    ) {
        return AppResult.error(
                source.estado(),
                source.codigo(),
                source.mensaje()
        );
    }

    private static <T> AppResult<T> sessionUnavailable() {
        return AppResult.error(
                AppStatus.UNAUTHORIZED,
                "SESION_NO_DISPONIBLE",
                "La sesión ya no está disponible. Inicie sesión nuevamente."
        );
    }

    private static <T> AppResult<T> unavailable() {
        return AppResult.error(
                AppStatus.SERVICE_UNAVAILABLE,
                "RECURSOS_NO_DISPONIBLES",
                "No se pudo completar la operación de recursos en este momento."
        );
    }
}
