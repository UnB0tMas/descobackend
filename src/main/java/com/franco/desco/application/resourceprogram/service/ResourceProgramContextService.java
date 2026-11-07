package com.franco.desco.application.resourceprogram.service;

import com.franco.desco.application.resourceprogram.ResourceProgramCommands;
import com.franco.desco.application.resourceprogram.port.in.ResourceProgramUseCase;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.resourceprogram.ResourceProgramModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class ResourceProgramContextService {

    private final ResourceProgramUseCase delegate;
    private final JdbcTemplate jdbc;
    private final SimpleJdbcCall destinations;
    private final SimpleJdbcCall availability;
    private final SimpleJdbcCall validateDestination;

    public ResourceProgramContextService(
            ResourceProgramUseCase delegate,
            DataSource dataSource
    ) {
        this.delegate = delegate;
        this.jdbc = new JdbcTemplate(dataSource);

        this.destinations = base(
                dataSource,
                "PA_RecursoProgramado_Sel_DestinosUOT",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT),
                in("cTipo", Types.VARCHAR)
        ).returningResultSet(
                "items",
                (rs, rowNum) -> new ResourceProgramModels.Destination(
                        rs.getString("tipo"),
                        rs.getLong("destinoId"),
                        rs.getLong("uotId"),
                        rs.getString("uotCodigo"),
                        rs.getString("uotNombre"),
                        rs.getString("codigo"),
                        rs.getString("nombre"),
                        rs.getString("estadoProceso"),
                        localDateTime(rs.getTimestamp("fechaReferencia")),
                        rs.getString("descripcion")
                )
        );

        this.availability = base(
                dataSource,
                "PA_RecursoProgramado_Sel_DisponibilidadUOT",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nUotId", Types.BIGINT)
        ).returningResultSet(
                "assets",
                (rs, rowNum) -> new ResourceProgramModels.AvailableAsset(
                        rs.getLong("bienInventarioId"),
                        rs.getLong("uotId"),
                        rs.getString("uotCodigo"),
                        rs.getString("uotNombre"),
                        rs.getString("codigoPatrimonial"),
                        rs.getString("nombre"),
                        rs.getString("estadoBien"),
                        rs.getBoolean("disponible")
                )
        ).returningResultSet(
                "supplies",
                (rs, rowNum) -> new ResourceProgramModels.AvailableSupply(
                        rs.getLong("suministroId"),
                        rs.getLong("uotId"),
                        rs.getString("uotCodigo"),
                        rs.getString("uotNombre"),
                        rs.getString("codigo"),
                        rs.getString("nombre"),
                        rs.getString("unidadMedida"),
                        rs.getBigDecimal("stockActual"),
                        rs.getBigDecimal("stockReservado"),
                        rs.getBigDecimal("stockDisponible"),
                        rs.getBigDecimal("stockMinimo"),
                        rs.getBoolean("requiereReposicion")
                )
        );

        this.validateDestination = base(
                dataSource,
                "PA_RecursoProgramado_Sel_ValidarDestinoContexto",
                in("nUsuarioId", Types.BIGINT),
                in("nSesionUsuarioId", Types.BIGINT),
                in("nCampaniaVentaId", Types.BIGINT),
                in("nOperativoVentaId", Types.BIGINT),
                in("nSalidaCampoId", Types.BIGINT),
                new SqlOutParameter("nUotDestino", Types.BIGINT)
        );
    }

    @SuppressWarnings("unchecked")
    public AppResult<List<ResourceProgramModels.Destination>> destinations(
            SessionIdentity identity,
            Long uotId,
            String type
    ) {
        String normalizedType = normalizeDestinationType(type);
        if (type != null && normalizedType == null) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "TIPO_DESTINO_NO_VALIDO",
                    "El tipo de destino no es válido."
            );
        }

        MapSqlParameterSource parameters = sessionParameters(identity);
        if (parameters == null) {
            return sessionUnavailable();
        }

        try {
            Map<String, Object> output = destinations.execute(
                    parameters
                            .addValue("nUotId", uotId)
                            .addValue("cTipo", normalizedType)
            );

            if (!ok(output)) {
                return databaseError(output);
            }

            List<ResourceProgramModels.Destination> items =
                    (List<ResourceProgramModels.Destination>) output.getOrDefault(
                            "items",
                            List.of()
                    );

            return AppResult.ok(
                    responseCode(output, "DESTINOS_LISTADOS"),
                    message(output, "Destinos consultados."),
                    items
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    @SuppressWarnings("unchecked")
    public AppResult<ResourceProgramModels.Availability> availability(
            SessionIdentity identity,
            Long uotId
    ) {
        MapSqlParameterSource parameters = sessionParameters(identity);
        if (parameters == null) {
            return sessionUnavailable();
        }

        try {
            Map<String, Object> output = availability.execute(
                    parameters.addValue("nUotId", uotId)
            );

            if (!ok(output)) {
                return databaseError(output);
            }

            List<ResourceProgramModels.AvailableAsset> assets =
                    (List<ResourceProgramModels.AvailableAsset>) output.getOrDefault(
                            "assets",
                            List.of()
                    );

            List<ResourceProgramModels.AvailableSupply> supplies =
                    (List<ResourceProgramModels.AvailableSupply>) output.getOrDefault(
                            "supplies",
                            List.of()
                    );

            return AppResult.ok(
                    responseCode(output, "DISPONIBILIDAD_LISTADA"),
                    message(output, "Disponibilidad consultada."),
                    new ResourceProgramModels.Availability(
                            assets,
                            supplies
                    )
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
    }

    public AppResult<Long> program(
            ResourceProgramCommands.Program command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        if (command.salidaCampoId() != null) {
            return AppResult.error(AppStatus.CONFLICT, "SALIDA_RECURSOS_GESTION_E2",
                    "Gestione los recursos de esta salida desde Salidas de campo. Deben incluirse en su solicitud y autorización.");
        }
        AppResult<Long> validation = validateDestination(
                identity,
                command.campaniaVentaId(),
                command.operativoVentaId(),
                command.salidaCampoId()
        );

        if (!validation.exitoso()) {
            return AppResult.error(
                    validation.estado(),
                    validation.codigo(),
                    validation.mensaje()
            );
        }

        return delegate.program(
                command,
                identity,
                metadata
        );
    }

    private AppResult<Long> validateDestination(
            SessionIdentity identity,
            Long campaignId,
            Long operationId,
            Long fieldTripId
    ) {
        MapSqlParameterSource parameters = sessionParameters(identity);
        if (parameters == null) {
            return sessionUnavailable();
        }

        try {
            Map<String, Object> output = validateDestination.execute(
                    parameters
                            .addValue("nCampaniaVentaId", campaignId)
                            .addValue("nOperativoVentaId", operationId)
                            .addValue("nSalidaCampoId", fieldTripId)
            );

            if (!ok(output)) {
                return databaseError(output);
            }

            Long uotId = longValue(output, "nUotDestino");
            if (uotId == null) {
                return AppResult.error(
                        AppStatus.BAD_REQUEST,
                        "DESTINO_NO_VALIDO",
                        "El destino seleccionado no está disponible."
                );
            }

            return AppResult.ok(
                    responseCode(output, "DESTINO_VALIDO"),
                    message(output, "Destino validado."),
                    uotId
            );
        } catch (DataAccessException exception) {
            return unavailable();
        }
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
                .withSchemaName("logistica")
                .withProcedureName(procedure)
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(all);
    }

    private static SqlParameter in(String name, int type) {
        return new SqlParameter(name, type);
    }

    private static LocalDateTime localDateTime(Timestamp value) {
        return value == null
                ? null
                : value.toLocalDateTime();
    }

    private static String normalizeDestinationType(String value) {
        String normalized = text(value);
        if (normalized == null) {
            return null;
        }

        normalized = normalized.toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "CAMPANIA", "OPERATIVO", "SALIDA" -> normalized;
            default -> null;
        };
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
                AppStatus.fromHttp(
                        http(output),
                        AppStatus.BAD_REQUEST
                ),
                responseCode(output, "OPERACION_NO_COMPLETADA"),
                message(
                        output,
                        "No se pudo completar la operación de recursos programados."
                )
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
                "RECURSOS_PROGRAMADOS_NO_DISPONIBLES",
                "No se pudo completar la operación de recursos programados en este momento."
        );
    }
}
