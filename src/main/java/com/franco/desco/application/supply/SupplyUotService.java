package com.franco.desco.application.supply;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.supply.SupplyModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import com.franco.desco.adapter.out.sql.common.SqlIdempotencyCoordinator;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.PersistenceResult;
import java.util.UUID;
import java.util.Arrays;
import java.util.HexFormat;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import tools.jackson.databind.json.JsonMapper;
import java.math.BigDecimal;
import java.sql.Types;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class SupplyUotService {

    private final SimpleJdbcCall list;
    private final SimpleJdbcCall create;
    private final SimpleJdbcCall update;
    private final SimpleJdbcCall movement;
    private final SimpleJdbcCall kardex;
    private final SimpleJdbcCall cancel;
    private final SimpleJdbcCall suggestedCode;
    private final JdbcTemplate jdbc;

    private final SqlIdempotencyCoordinator idempotency;
    private final JsonMapper json;

    public SupplyUotService(DataSource dataSource, SqlIdempotencyCoordinator idempotency, JsonMapper json) {
        this.idempotency = idempotency;
        this.json = json;
        this.jdbc = new JdbcTemplate(dataSource);

        this.list = base(
                dataSource,
                "PA_SuministroUOT_Sel_Listado",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nPagina", Types.INTEGER),
                in("nTamano", Types.INTEGER)
        ).returningResultSet(
                "items",
                (rs, rowNum) -> new SupplyModels.Summary(
                        rs.getLong("suministroId"),
                        rs.getLong("uotId"),
                        rs.getString("uotCodigo"),
                        rs.getString("uotNombre"),
                        rs.getString("codigo"),
                        rs.getString("nombre"),
                        rs.getString("unidadMedida"),
                        rs.getBoolean("estado"),
                        rs.getBigDecimal("stock"),
                        rs.getBigDecimal("stockActual"),
                        rs.getBigDecimal("stockReservado"),
                        rs.getBigDecimal("stockDisponible"),
                        rs.getBigDecimal("stockMinimo"),
                        rs.getBoolean("requiereReposicion"),
                        rs.getLong("totalRegistros")
                )
        );

        this.create = base(
                dataSource,
                "PA_SuministroUOT_Ins_Registro",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("cCodigo", Types.VARCHAR),
                in("cNombre", Types.NVARCHAR),
                in("cUnidad", Types.VARCHAR),
                in("nStockInicial", Types.DECIMAL),
                in("nStockMinimo", Types.DECIMAL),
                new SqlOutParameter("nSuministroId", Types.BIGINT)
        );

        this.update = base(
                dataSource,
                "PA_SuministroUOT_Upd_Registro",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nSuministroId", Types.BIGINT),
                in("cNombre", Types.NVARCHAR),
                in("cUnidad", Types.VARCHAR),
                in("nStockMinimo", Types.DECIMAL)
        );

        this.movement = base(
                dataSource,
                "PA_SuministroUOT_Ins_Movimiento",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nSuministroId", Types.BIGINT),
                in("cTipo", Types.VARCHAR),
                in("nCantidad", Types.DECIMAL),
                in("cDocumento", Types.NVARCHAR),
                in("cObservacion", Types.NVARCHAR),
                new SqlOutParameter("nMovimientoId", Types.BIGINT)
        );

        this.kardex = base(
                dataSource,
                "PA_SuministroUOT_Sel_Kardex",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nSuministroId", Types.BIGINT)
        ).returningResultSet(
                "items",
                (rs, rowNum) -> new SupplyModels.Movement(
                        rs.getLong("suministroMovimientoId"),
                        rs.getLong("suministroId"),
                        rs.getLong("uotId"),
                        rs.getString("uotCodigo"),
                        rs.getString("uotNombre"),
                        rs.getString("codigo"),
                        rs.getString("nombre"),
                        rs.getString("unidadMedida"),
                        (Long) rs.getObject("recursoProgramadoId"),
                        rs.getString("tipoMovimiento"),
                        rs.getBigDecimal("cantidad"),
                        rs.getTimestamp("fechaHora").toLocalDateTime().toInstant(java.time.ZoneOffset.UTC),
                        rs.getString("documentoReferencia"),
                        rs.getString("observacion"),
                        rs.getString("usuario"),
                        rs.getBigDecimal("saldo")
                )
        );

        this.cancel = base(
                dataSource,
                "PA_SuministroUOT_Upd_AnularMovimiento",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("nMovimientoId", Types.BIGINT),
                in("cMotivo", Types.NVARCHAR)
        );

        this.suggestedCode = base(
                dataSource,
                "PA_Recurso_Sel_CodigoSugerido",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("cTipo", Types.VARCHAR),
                new SqlOutParameter("cCodigo", Types.VARCHAR)
        );
    }

    @SuppressWarnings("unchecked")
    public AppResult<PageResult<SupplyModels.Summary>> list(
            SessionIdentity identity,
            Long uotId,
            int page,
            int size
    ) {
        try {
            MapSqlParameterSource parameters = params(identity);
            if (parameters == null) {
                return sessionUnavailable();
            }

            Map<String, Object> output = list.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("nPagina", page)
                            .addValue("nTamano", size)
            );

            if (!ok(output)) {
                return error(output);
            }

            List<SupplyModels.Summary> items =
                    (List<SupplyModels.Summary>) output.getOrDefault(
                            "items",
                            List.of()
                    );

            long total = items.isEmpty()
                    ? 0
                    : items.getFirst().totalRecords();

            int pages = size <= 0
                    ? 0
                    : (int) Math.ceil((double) total / size);

            return AppResult.ok(
                    responseCode(output),
                    message(output),
                    new PageResult<>(
                            items,
                            page,
                            size,
                            total,
                            pages
                    )
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<Long> createOnce(
            SessionIdentity identity,
            Long uotId,
            String code,
            String name,
            String unit,
            BigDecimal initial,
            BigDecimal minimum
    ) {
        try {
            MapSqlParameterSource parameters = params(identity);
            if (parameters == null) {
                return sessionUnavailable();
            }

            String resolvedCode = normalizeCode(code);
            if (resolvedCode == null) {
                Map<String, Object> suggestion = suggestedCode.execute(
                        new MapSqlParameterSource()
                                .addValue("nUsuarioId", identity.usuarioId())
                                .addValue("nSesionUsuarioId", parameters.getValue("nSesionUsuarioId"))
                                .addValue("nUotId", uotId)
                                .addValue("cTipo", "SUMINISTRO")
                );

                if (!ok(suggestion)) {
                    return error(suggestion);
                }

                resolvedCode = text(suggestion.get("cCodigo"));
                if (resolvedCode == null) {
                    return AppResult.error(
                            AppStatus.SERVICE_UNAVAILABLE,
                            "CODIGO_NO_GENERADO",
                            "No se pudo generar el código del suministro."
                    );
                }
            }

            Map<String, Object> output = create.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("cCodigo", resolvedCode)
                            .addValue("cNombre", name)
                            .addValue("cUnidad", unit)
                            .addValue("nStockInicial", initial)
                            .addValue(
                                    "nStockMinimo",
                                    minimum == null
                                            ? BigDecimal.ZERO
                                            : minimum
                            )
            );

            return ok(output)
                    ? AppResult.created(
                            responseCode(output),
                            message(output),
                            longValue(output, "nSuministroId")
                    )
                    : error(output);
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<Void> updateOnce(
            SessionIdentity identity,
            Long uotId,
            Long id,
            String name,
            String unit,
            BigDecimal minimum
    ) {
        try {
            MapSqlParameterSource parameters = params(identity);
            if (parameters == null) {
                return sessionUnavailable();
            }

            Map<String, Object> output = update.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("nSuministroId", id)
                            .addValue("cNombre", name)
                            .addValue("cUnidad", unit)
                            .addValue("nStockMinimo", minimum)
            );

            return ok(output)
                    ? AppResult.ok(
                            responseCode(output),
                            message(output),
                            null
                    )
                    : error(output);
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<Long> movementOnce(
            SessionIdentity identity,
            Long uotId,
            Long id,
            String type,
            BigDecimal quantity,
            String document,
            String observation
    ) {
        try {
            MapSqlParameterSource parameters = params(identity);
            if (parameters == null) {
                return sessionUnavailable();
            }

            Map<String, Object> output = movement.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("nSuministroId", id)
                            .addValue("cTipo", type)
                            .addValue("nCantidad", quantity)
                            .addValue("cDocumento", document)
                            .addValue("cObservacion", observation)
            );

            return ok(output)
                    ? AppResult.created(
                            responseCode(output),
                            message(output),
                            longValue(output, "nMovimientoId")
                    )
                    : error(output);
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    @SuppressWarnings("unchecked")
    public AppResult<List<SupplyModels.Movement>> kardex(
            SessionIdentity identity,
            Long uotId,
            Long id
    ) {
        try {
            MapSqlParameterSource parameters = params(identity);
            if (parameters == null) {
                return sessionUnavailable();
            }

            Map<String, Object> output = kardex.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("nSuministroId", id)
            );

            return ok(output)
                    ? AppResult.ok(
                            responseCode(output),
                            message(output),
                            (List<SupplyModels.Movement>) output.getOrDefault(
                                    "items",
                                    List.of()
                            )
                    )
                    : error(output);
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    private AppResult<Void> cancelOnce(
            SessionIdentity identity,
            Long uotId,
            Long id,
            String reason
    ) {
        try {
            MapSqlParameterSource parameters = params(identity);
            if (parameters == null) {
                return sessionUnavailable();
            }

            Map<String, Object> output = cancel.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("nMovimientoId", id)
                            .addValue("cMotivo", reason)
            );

            return ok(output)
                    ? AppResult.ok(
                            responseCode(output),
                            message(output),
                            null
                    )
                    : error(output);
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    public AppResult<Long> create(SessionIdentity actor, Long uotId, String code, String name,
            String unit, BigDecimal initial, BigDecimal minimum, UUID key) {
        return ApplicationResults.created(idempotency.executeLong(actor.usuarioId(),key,"SUMINISTRO_CREAR",
                "logistica","Suministro",hash(uotId,code,name,unit,initial,minimum),
                () -> persistence(createOnce(actor,uotId,code,name,unit,initial,minimum))),
                "SUMINISTRO_CREADO","SUMINISTRO_NO_CREADO");
    }

    public AppResult<Void> update(SessionIdentity actor, Long uotId, Long id, String name,
            String unit, BigDecimal minimum, UUID key) {
        return ApplicationResults.ok(idempotency.executeVoid(actor.usuarioId(),key,"SUMINISTRO_EDITAR",
                "logistica","Suministro",hash(uotId,id,name,unit,minimum),
                () -> persistence(updateOnce(actor,uotId,id,name,unit,minimum))),
                "SUMINISTRO_ACTUALIZADO","SUMINISTRO_NO_ACTUALIZADO",AppStatus.BAD_REQUEST);
    }

    public AppResult<Long> movement(SessionIdentity actor, Long uotId, Long id, String type,
            BigDecimal quantity, String document, String observation, UUID key) {
        return ApplicationResults.created(idempotency.executeLong(actor.usuarioId(),key,"SUMINISTRO_MOVIMIENTO",
                "logistica","SuministroMovimiento",hash(uotId,id,type,quantity,document,observation),
                () -> persistence(movementOnce(actor,uotId,id,type,quantity,document,observation))),
                "SUMINISTRO_MOVIMIENTO_CREADO","SUMINISTRO_MOVIMIENTO_NO_CREADO");
    }

    public AppResult<Void> cancel(SessionIdentity actor, Long uotId, Long id, String reason, UUID key) {
        return ApplicationResults.ok(idempotency.executeVoid(actor.usuarioId(),key,"SUMINISTRO_ANULAR",
                "logistica","SuministroMovimiento",hash(uotId,id,reason),
                () -> persistence(cancelOnce(actor,uotId,id,reason))),
                "SUMINISTRO_MOVIMIENTO_ANULADO","SUMINISTRO_MOVIMIENTO_NO_ANULADO",AppStatus.BAD_REQUEST);
    }

    private String hash(Object... values) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
                    json.writeValueAsString(Arrays.asList(values)).getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("No se pudo identificar la solicitud.",exception);
        }
    }

    private static <T> PersistenceResult<T> persistence(AppResult<T> result) {
        int http = switch(result.estado()) {
            case UNAUTHORIZED -> 401;
            case FORBIDDEN -> 403;
            case NOT_FOUND -> 404;
            case CONFLICT -> 409;
            case SERVICE_UNAVAILABLE -> 503;
            default -> result.exitoso() ? 200 : 400;
        };
        return new PersistenceResult<>(result.exitoso(),result.codigo(),result.mensaje(),http,result.datos());
    }

    private static SimpleJdbcCall base(
            DataSource dataSource,
            String name,
            SqlParameter... parameters
    ) {
        SqlParameter[] all = new SqlParameter[parameters.length + 4];
        System.arraycopy(parameters, 0, all, 0, parameters.length);
        all[parameters.length] = new SqlOutParameter("bResultado", Types.BIT);
        all[parameters.length + 1] = new SqlOutParameter("cMensaje", Types.NVARCHAR);
        all[parameters.length + 2] = new SqlOutParameter("cCodigoRespuesta", Types.VARCHAR);
        all[parameters.length + 3] = new SqlOutParameter("nHttpRespuesta", Types.SMALLINT);

        return new SimpleJdbcCall(dataSource)
                .withSchemaName("logistica")
                .withProcedureName(name)
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(all);
    }

    private static SqlParameter in(String name, int type) {
        return new SqlParameter(name, type);
    }

    private MapSqlParameterSource params(SessionIdentity identity) {
        if (identity == null
                || identity.usuarioId() == null
                || identity.sesionPublicaId() == null) {
            return null;
        }

        List<Long> values = jdbc.query(
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

        if (values.isEmpty()) {
            return null;
        }

        return new MapSqlParameterSource()
                .addValue("nUsuarioId", identity.usuarioId())
                .addValue("nSesionUsuarioId", values.getFirst());
    }

    private static String normalizeCode(String value) {
        String normalized = text(value);
        return normalized == null
                ? null
                : normalized.toUpperCase(Locale.ROOT);
    }

    private static boolean ok(Map<String, Object> output) {
        Object value = output.get("bResultado");
        return value instanceof Boolean booleanValue
                ? booleanValue
                : value instanceof Number number
                && number.intValue() != 0;
    }

    private static String message(Map<String, Object> output) {
        String value = text(output.get("cMensaje"));
        return value == null
                ? "Acción realizada."
                : value;
    }

    private static String responseCode(Map<String, Object> output) {
        String value = text(output.get("cCodigoRespuesta"));
        return value == null
                ? "OPERACION_COMPLETADA"
                : value;
    }

    private static Integer http(Map<String, Object> output) {
        Object value = output.get("nHttpRespuesta");
        return value instanceof Number number
                ? number.intValue()
                : 400;
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

    private static String text(Object value) {
        if (value == null) {
            return null;
        }
        String normalized = value.toString().trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private static <T> AppResult<T> error(Map<String, Object> output) {
        return AppResult.error(
                AppStatus.fromHttp(
                        http(output),
                        AppStatus.BAD_REQUEST
                ),
                text(output.get("cCodigoRespuesta")) == null
                        ? "OPERACION_NO_COMPLETADA"
                        : text(output.get("cCodigoRespuesta")),
                text(output.get("cMensaje")) == null
                        ? "No se pudo completar la operación."
                        : text(output.get("cMensaje"))
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
                "SUMINISTROS_NO_DISPONIBLES",
                "No se pudo completar la operación de suministros en este momento."
        );
    }
}
