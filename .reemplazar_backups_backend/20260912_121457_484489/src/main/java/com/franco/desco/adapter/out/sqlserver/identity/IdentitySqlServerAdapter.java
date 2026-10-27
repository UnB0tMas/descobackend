package com.franco.desco.adapter.out.sqlserver.identity;

import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.application.identity.port.out.IdentityPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.LocalResolution;
import com.franco.desco.domain.identity.IdentityModels.PersistOutcome;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import com.franco.desco.domain.identity.IdentityModels.Reservation;
import com.franco.desco.domain.identity.IdentityModels.Target;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class IdentitySqlServerAdapter
        implements IdentityPersistencePort {

    private static final String CALL_RESOLVE =
            "{call integracion.PA_Identidad_Sel_ResolverDocumento(?,?,?)}";

    private static final String CALL_RESERVE =
            "{call integracion.PA_Identidad_Ins_ReservarConsultaExterna(?,?,?)}";

    private static final String CALL_RESULT =
            "{call integracion.PA_Identidad_Upd_ResultadoConsultaExterna(?,?,?)}";

    private final JdbcTemplate jdbcTemplate;
    private final JsonMapper jsonMapper;

    public IdentitySqlServerAdapter(
            JdbcTemplate jdbcTemplate,
            JsonMapper jsonMapper
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public PersistenceResult<LocalResolution> resolveLocal(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return executeOne(
                CALL_RESOLVE,
                payload(identity, metadata, command, null),
                this::localResolution
        );
    }

    @Override
    public PersistenceResult<Reservation> reserveExternalQuery(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return executeOne(
                CALL_RESERVE,
                payload(identity, metadata, command, null),
                this::reservation
        );
    }

    @Override
    public PersistenceResult<PersistOutcome> registerExternalResult(
            ResolveDocument command,
            ProviderResult providerResult,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return executeOne(
                CALL_RESULT,
                payload(
                        identity,
                        metadata,
                        command,
                        providerResult
                ),
                this::persistOutcome
        );
    }

    private <T> PersistenceResult<T> executeOne(
            String callSql,
            String payload,
            RowMapper<T> mapper
    ) {
        PersistenceResult<T> result = jdbcTemplate.execute(
                (ConnectionCallback<PersistenceResult<T>>) connection ->
                        execute(
                                connection,
                                callSql,
                                payload,
                                mapper
                        )
        );

        if (result == null) {
            return PersistenceResult.error(
                    "SQL Server no devolvió una respuesta para la validación de identidad."
            );
        }

        return result;
    }

    private <T> PersistenceResult<T> execute(
            Connection connection,
            String callSql,
            String payload,
            RowMapper<T> mapper
    ) throws SQLException {
        T data = null;

        try (CallableStatement statement =
                     connection.prepareCall(callSql)) {
            statement.setNString(1, payload);
            statement.registerOutParameter(2, Types.BIT);
            statement.registerOutParameter(3, Types.NVARCHAR);

            boolean hasResultSet = statement.execute();

            while (true) {
                if (hasResultSet) {
                    try (ResultSet resultSet =
                                 statement.getResultSet()) {
                        if (data == null && resultSet.next()) {
                            data = mapper.map(resultSet);
                        }

                        while (resultSet.next()) {
                            // Este contrato requiere una sola fila.
                        }
                    }
                } else if (statement.getUpdateCount() == -1) {
                    break;
                }

                hasResultSet = statement.getMoreResults();
            }

            boolean successful = statement.getBoolean(2);
            String message = statement.getNString(3);

            if (!successful) {
                return PersistenceResult.error(
                        hasText(message)
                                ? message
                                : "La operación de identidad fue rechazada."
                );
            }

            return PersistenceResult.ok(
                    hasText(message)
                            ? message
                            : "Operación de identidad completada.",
                    data
            );
        }
    }

    private LocalResolution localResolution(
            ResultSet rs
    ) throws SQLException {
        return new LocalResolution(
                rs.getBoolean("encontradoLocal"),
                enumValue(Target.class, rs.getString("entidadObjetivo")),
                nullableLong(rs, "entidadId"),
                rs.getString("tipoPersona"),
                enumValue(DocumentType.class, rs.getString("tipoDocumento")),
                rs.getString("numeroDocumento"),
                rs.getString("nombres"),
                rs.getString("apellidoPaterno"),
                rs.getString("apellidoMaterno"),
                rs.getString("telefono"),
                rs.getString("correo"),
                rs.getString("razonSocial"),
                localDate(rs, "fechaNacimiento"),
                rs.getString("sexo"),
                nullableLong(rs, "ubicacionId"),
                rs.getString("departamentoCodigo"),
                rs.getString("departamentoNombre"),
                rs.getString("provinciaCodigo"),
                rs.getString("provinciaNombre"),
                rs.getString("distritoCodigo"),
                rs.getString("distritoNombre"),
                nullableLong(rs, "centroPobladoId"),
                rs.getString("centroPobladoNombre"),
                rs.getString("referenciaUbicacion"),
                nullableBoolean(rs, "estadoEntidad"),
                rs.getBoolean("esEmpleado"),
                rs.getBoolean("esSocio"),
                rs.getBoolean("esAsociacion"),
                rs.getBoolean("requiereConsultaExterna"),
                enumValue(
                        DocumentType.class,
                        rs.getString("tipoDocumentoConsultaExterna")
                ),
                rs.getString("numeroDocumentoConsultaExterna"),
                rs.getString("claveConsulta"),
                rs.getString("estadoConsultaPrevia"),
                instant(rs, "reintentoDesdeUtc"),
                instant(rs, "bloqueoHastaUtc")
        );
    }

    private Reservation reservation(
            ResultSet rs
    ) throws SQLException {
        return new Reservation(
                rs.getBoolean("puedeConsultar"),
                enumValue(
                        DocumentType.class,
                        rs.getString("tipoDocumentoConsultaExterna")
                ),
                rs.getString("numeroDocumentoConsultaExterna"),
                rs.getString("claveConsulta"),
                instant(rs, "reintentoDesdeUtc")
        );
    }

    private PersistOutcome persistOutcome(
            ResultSet rs
    ) throws SQLException {
        return new PersistOutcome(
                rs.getBoolean("insertado"),
                rs.getBoolean("permiteCargaManual"),
                nullableLong(rs, "entidadId"),
                rs.getString("estadoConsulta")
        );
    }

    private String payload(
            SessionIdentity identity,
            RequestMetadata metadata,
            ResolveDocument command,
            ProviderResult providerResult
    ) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put(
                "sesionPublicaId",
                identity.sesionPublicaId() == null
                        ? null
                        : identity.sesionPublicaId().toString()
        );
        context.put(
                "correlacionId",
                metadata.correlacionId() == null
                        ? null
                        : metadata.correlacionId().toString()
        );
        context.put(
                "solicitudId",
                metadata.solicitudId() == null
                        ? null
                        : metadata.solicitudId().toString()
        );
        context.put("ip", metadata.ip());
        context.put("endpoint", metadata.endpoint());

        Map<String, Object> query = new LinkedHashMap<>();
        query.put(
                "entidadObjetivo",
                command.entidadObjetivo().name()
        );
        query.put(
                "tipoDocumento",
                command.tipoDocumento().name()
        );
        query.put(
                "numeroDocumento",
                command.numeroDocumento()
        );

        Map<String, Object> root = new LinkedHashMap<>();
        root.put("contexto", context);
        root.put("consulta", query);

        if (providerResult != null) {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("exito", providerResult.exito());
            result.put("encontrado", providerResult.encontrado());
            result.put("codigoError", providerResult.codigoError());
            root.put("resultado", result);

            Map<String, Object> data = new LinkedHashMap<>();

            if (providerResult.datos() != null) {
                var providerData = providerResult.datos();

                data.put("nombres", providerData.nombres());
                data.put("apellidoPaterno", providerData.apellidoPaterno());
                data.put("apellidoMaterno", providerData.apellidoMaterno());
                data.put(
                        "fechaNacimiento",
                        providerData.fechaNacimiento() == null
                                ? null
                                : providerData.fechaNacimiento().toString()
                );
                data.put("razonSocial", providerData.razonSocial());
                data.put("direccionFiscal", providerData.direccionFiscal());
                data.put("direccionCompleta", providerData.direccionCompleta());
                data.put("sexo", providerData.sexo());
                data.put("departamento", providerData.departamento());
                data.put("provincia", providerData.provincia());
                data.put("distrito", providerData.distrito());
                data.put(
                        "departamentoCodigo",
                        providerData.departamentoCodigo()
                );
                data.put(
                        "provinciaCodigo",
                        providerData.provinciaCodigo()
                );
                data.put(
                        "distritoCodigo",
                        providerData.distritoCodigo()
                );
                data.put("centroPoblado", providerData.centroPoblado());
                data.put(
                        "centroPobladoCodigo",
                        providerData.centroPobladoCodigo()
                );
                data.put(
                        "tipoContribuyente",
                        providerData.tipoContribuyente()
                );
                data.put(
                        "estadoContribuyente",
                        providerData.estadoContribuyente()
                );
                data.put(
                        "condicionContribuyente",
                        providerData.condicionContribuyente()
                );
            }

            root.put("datos", data);
        }

        try {
            return jsonMapper.writeValueAsString(root);
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo construir el payload de identidad.",
                    exception
            );
        }
    }

    private Long nullableLong(
            ResultSet rs,
            String column
    ) throws SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private Boolean nullableBoolean(
            ResultSet rs,
            String column
    ) throws SQLException {
        boolean value = rs.getBoolean(column);
        return rs.wasNull() ? null : value;
    }

    private LocalDate localDate(
            ResultSet rs,
            String column
    ) throws SQLException {
        java.sql.Date value = rs.getDate(column);
        return value == null ? null : value.toLocalDate();
    }

    private Instant instant(
            ResultSet rs,
            String column
    ) throws SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toInstant();
    }

    private <E extends Enum<E>> E enumValue(
            Class<E> type,
            String value
    ) {
        if (!hasText(value)) {
            return null;
        }
        return Enum.valueOf(type, value.trim().toUpperCase());
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    @FunctionalInterface
    private interface RowMapper<T> {
        T map(ResultSet resultSet) throws SQLException;
    }
}
