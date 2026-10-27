package com.franco.desco.adapter.out.sqlserver.identity;

import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.application.identity.port.out.IdentityPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.LocalResolution;
import com.franco.desco.domain.identity.IdentityModels.PersistOutcome;
import com.franco.desco.domain.identity.IdentityModels.ProviderData;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import com.franco.desco.domain.identity.IdentityModels.Reservation;
import com.franco.desco.domain.identity.IdentityModels.Target;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
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
                payload(
                        identity,
                        metadata,
                        command,
                        null
                ),
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
                payload(
                        identity,
                        metadata,
                        command,
                        null
                ),
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
        PersistenceResult<T> result =
                jdbcTemplate.execute(
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
                    "No fue posible completar la validación."
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

            statement.setNString(
                    1,
                    payload
            );

            statement.registerOutParameter(
                    2,
                    Types.BIT
            );

            statement.registerOutParameter(
                    3,
                    Types.NVARCHAR
            );

            boolean hasResultSet =
                    statement.execute();

            while (true) {

                if (hasResultSet) {

                    try (ResultSet resultSet =
                                 statement.getResultSet()) {

                        if (data == null
                                && resultSet.next()) {

                            data =
                                    mapper.map(
                                            resultSet
                                    );
                        }

                        while (resultSet.next()) {
                            // El contrato de identidad utiliza una sola fila.
                        }
                    }

                } else if (statement.getUpdateCount() == -1) {
                    break;
                }

                hasResultSet =
                        statement.getMoreResults();
            }

            boolean successful =
                    statement.getBoolean(2);

            String message =
                    statement.getNString(3);

            if (!successful) {
                return PersistenceResult.error(
                        hasText(message)
                                ? message
                                : "No fue posible completar la validación."
                );
            }

            return PersistenceResult.ok(
                    hasText(message)
                            ? message
                            : "Operación completada correctamente.",
                    data
            );
        }
    }

    /*
     * IMPORTANTE
     *
     * Este orden debe mantenerse sincronizado con
     * IdentityModels.LocalResolution.
     *
     * PA_Identidad_Sel_ResolverDocumento devuelve la identidad
     * ya persistida en DESCO_DB, incluyendo fecha de nacimiento
     * y geografía.
     */
    private LocalResolution localResolution(
            ResultSet rs
    ) throws SQLException {

        return new LocalResolution(

                // Identificación base
                rs.getBoolean(
                        "encontradoLocal"
                ),

                enumValue(
                        Target.class,
                        rs.getString(
                                "entidadObjetivo"
                        )
                ),

                nullableLong(
                        rs,
                        "entidadId"
                ),

                rs.getString(
                        "tipoPersona"
                ),

                enumValue(
                        DocumentType.class,
                        rs.getString(
                                "tipoDocumento"
                        )
                ),

                rs.getString(
                        "numeroDocumento"
                ),

                rs.getString(
                        "nombres"
                ),

                rs.getString(
                        "apellidoPaterno"
                ),

                rs.getString(
                        "apellidoMaterno"
                ),

                rs.getString(
                        "razonSocial"
                ),

                // Datos personales
                localDate(
                        rs,
                        "fechaNacimiento"
                ),

                rs.getString(
                        "sexo"
                ),

                // Ubicación
                nullableLong(
                        rs,
                        "ubicacionId"
                ),

                trimToNull(
                        rs.getString(
                                "departamentoCodigo"
                        )
                ),

                rs.getString(
                        "departamentoNombre"
                ),

                trimToNull(
                        rs.getString(
                                "provinciaCodigo"
                        )
                ),

                rs.getString(
                        "provinciaNombre"
                ),

                trimToNull(
                        rs.getString(
                                "distritoCodigo"
                        )
                ),

                rs.getString(
                        "distritoNombre"
                ),

                nullableLong(
                        rs,
                        "centroPobladoId"
                ),

                rs.getString(
                        "centroPobladoNombre"
                ),

                rs.getString(
                        "referenciaUbicacion"
                ),

                trimToNull(
                        rs.getString(
                                "ubigeoReniec"
                        )
                ),

                trimToNull(
                        rs.getString(
                                "ubigeoSunat"
                        )
                ),

                // Estado local
                nullableBoolean(
                        rs,
                        "estadoEntidad"
                ),

                rs.getBoolean(
                        "esEmpleado"
                ),

                rs.getBoolean(
                        "esSocio"
                ),

                rs.getBoolean(
                        "esAsociacion"
                ),

                // Control de consulta externa
                rs.getBoolean(
                        "requiereConsultaExterna"
                ),

                enumValue(
                        DocumentType.class,
                        rs.getString(
                                "tipoDocumentoConsultaExterna"
                        )
                ),

                rs.getString(
                        "numeroDocumentoConsultaExterna"
                ),

                rs.getString(
                        "claveConsulta"
                ),

                rs.getString(
                        "estadoConsultaPrevia"
                ),

                instant(
                        rs,
                        "reintentoDesdeUtc"
                ),

                instant(
                        rs,
                        "bloqueoHastaUtc"
                )
        );
    }

    private Reservation reservation(
            ResultSet rs
    ) throws SQLException {

        return new Reservation(
                rs.getBoolean(
                        "puedeConsultar"
                ),

                enumValue(
                        DocumentType.class,
                        rs.getString(
                                "tipoDocumentoConsultaExterna"
                        )
                ),

                rs.getString(
                        "numeroDocumentoConsultaExterna"
                ),

                rs.getString(
                        "claveConsulta"
                ),

                instant(
                        rs,
                        "reintentoDesdeUtc"
                )
        );
    }

    private PersistOutcome persistOutcome(
            ResultSet rs
    ) throws SQLException {

        return new PersistOutcome(
                rs.getBoolean(
                        "insertado"
                ),

                rs.getBoolean(
                        "permiteCargaManual"
                ),

                nullableLong(
                        rs,
                        "entidadId"
                ),

                rs.getString(
                        "estadoConsulta"
                )
        );
    }

    /*
     * Construye el único contrato JSON utilizado por los PA
     * del módulo de identidad.
     *
     * Cuando existe ProviderResult, TODOS los datos obtenidos
     * por el proveedor se envían a SQL Server.
     *
     * Ningún dato geográfico debe perderse en esta capa.
     */
    private String payload(
            SessionIdentity identity,
            RequestMetadata metadata,
            ResolveDocument command,
            ProviderResult providerResult
    ) {

        Map<String, Object> context =
                new LinkedHashMap<>();

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

        context.put(
                "ip",
                metadata.ip()
        );

        context.put(
                "endpoint",
                metadata.endpoint()
        );

        Map<String, Object> query =
                new LinkedHashMap<>();

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

        Map<String, Object> root =
                new LinkedHashMap<>();

        root.put(
                "contexto",
                context
        );

        root.put(
                "consulta",
                query
        );

        if (providerResult != null) {

            Map<String, Object> result =
                    new LinkedHashMap<>();

            result.put(
                    "exito",
                    providerResult.exito()
            );

            result.put(
                    "encontrado",
                    providerResult.encontrado()
            );

            result.put(
                    "codigoError",
                    providerResult.codigoError()
            );

            root.put(
                    "resultado",
                    result
            );

            Map<String, Object> data =
                    providerData(
                            providerResult.datos()
                    );

            root.put(
                    "datos",
                    data
            );
        }

        try {

            return jsonMapper.writeValueAsString(
                    root
            );

        } catch (Exception exception) {

            throw new IllegalStateException(
                    "No se pudo construir la solicitud de validación.",
                    exception
            );
        }
    }

    /*
     * ProviderData contiene todo lo que el adapter HTTP de
     * Factiliza consiguió normalizar.
     *
     * El PA decide posteriormente qué campos puede persistir.
     */
    private Map<String, Object> providerData(
            ProviderData source
    ) {

        Map<String, Object> data =
                new LinkedHashMap<>();

        if (source == null) {
            return data;
        }

        data.put(
                "nombres",
                source.nombres()
        );

        data.put(
                "apellidoPaterno",
                source.apellidoPaterno()
        );

        data.put(
                "apellidoMaterno",
                source.apellidoMaterno()
        );

        data.put(
                "fechaNacimiento",
                source.fechaNacimiento() == null
                        ? null
                        : source.fechaNacimiento().toString()
        );

        data.put(
                "razonSocial",
                source.razonSocial()
        );

        data.put(
                "direccionFiscal",
                source.direccionFiscal()
        );

        data.put(
                "direccionCompleta",
                source.direccionCompleta()
        );

        data.put(
                "sexo",
                source.sexo()
        );

        data.put(
                "departamento",
                source.departamento()
        );

        data.put(
                "provincia",
                source.provincia()
        );

        data.put(
                "distrito",
                source.distrito()
        );

        data.put(
                "departamentoCodigo",
                source.departamentoCodigo()
        );

        data.put(
                "provinciaCodigo",
                source.provinciaCodigo()
        );

        data.put(
                "distritoCodigo",
                source.distritoCodigo()
        );

        data.put(
                "centroPoblado",
                source.centroPoblado()
        );

        data.put(
                "centroPobladoCodigo",
                source.centroPobladoCodigo()
        );

        data.put(
                "ubigeoReniec",
                source.ubigeoReniec()
        );

        data.put(
                "ubigeoSunat",
                source.ubigeoSunat()
        );

        data.put(
                "tipoContribuyente",
                source.tipoContribuyente()
        );

        data.put(
                "estadoContribuyente",
                source.estadoContribuyente()
        );

        data.put(
                "condicionContribuyente",
                source.condicionContribuyente()
        );

        return data;
    }

    private Long nullableLong(
            ResultSet rs,
            String column
    ) throws SQLException {

        long value =
                rs.getLong(
                        column
                );

        return rs.wasNull()
                ? null
                : value;
    }

    private Boolean nullableBoolean(
            ResultSet rs,
            String column
    ) throws SQLException {

        boolean value =
                rs.getBoolean(
                        column
                );

        return rs.wasNull()
                ? null
                : value;
    }

    private LocalDate localDate(
            ResultSet rs,
            String column
    ) throws SQLException {

        Date value =
                rs.getDate(
                        column
                );

        return value == null
                ? null
                : value.toLocalDate();
    }

    private Instant instant(
            ResultSet rs,
            String column
    ) throws SQLException {

        Timestamp value =
                rs.getTimestamp(
                        column
                );

        return value == null
                ? null
                : value.toInstant();
    }

    private <E extends Enum<E>> E enumValue(
            Class<E> type,
            String value
    ) {

        if (!hasText(value)) {
            return null;
        }

        return Enum.valueOf(
                type,
                value.trim().toUpperCase()
        );
    }

    private String trimToNull(
            String value
    ) {

        if (value == null) {
            return null;
        }

        String normalized =
                value.trim();

        return normalized.isEmpty()
                ? null
                : normalized;
    }

    private boolean hasText(
            String value
    ) {
        return value != null
                && !value.isBlank();
    }

    @FunctionalInterface
    private interface RowMapper<T> {

        T map(
                ResultSet resultSet
        ) throws SQLException;
    }
}