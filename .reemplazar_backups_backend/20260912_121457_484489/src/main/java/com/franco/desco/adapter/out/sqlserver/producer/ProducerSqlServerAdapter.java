package com.franco.desco.adapter.out.sqlserver.producer;

import com.franco.desco.application.producer.ProducerCommands.CreateProducer;
import com.franco.desco.application.producer.ProducerCommands.GetProducer;
import com.franco.desco.application.producer.ProducerCommands.ListProducers;
import com.franco.desco.application.producer.ProducerCommands.LocationInput;
import com.franco.desco.application.producer.ProducerCommands.RetireProducer;
import com.franco.desco.application.producer.ProducerCommands.UpdateProducer;
import com.franco.desco.application.producer.port.out.ProducerPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.producer.ProducerModels;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class ProducerSqlServerAdapter
        implements ProducerPersistencePort {

    private static final String CALL_LIST =
            "{call org.PA_Socio_Sel_Listado(?,?,?)}";
    private static final String CALL_GET =
            "{call org.PA_Socio_Sel_DetalleCompleto(?,?,?)}";
    private static final String CALL_CREATE =
            "{call org.PA_Socio_Ins_Registro(?,?,?,?,?)}";
    private static final String CALL_UPDATE =
            "{call org.PA_Socio_Upd_Registro(?,?,?)}";
    private static final String CALL_RETIRE =
            "{call org.PA_Socio_Del_Registro(?,?,?)}";

    private final JdbcTemplate jdbcTemplate;
    private final JsonMapper jsonMapper;

    public ProducerSqlServerAdapter(
            JdbcTemplate jdbcTemplate,
            JsonMapper jsonMapper
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public PersistenceResult<PageResult<ProducerModels.Summary>> list(
            ListProducers command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PageRequest<?> page = command.page();

        Map<String, Object> filters = new LinkedHashMap<>();
        if (command.page().filtros() != null) {
            filters.put("buscar", command.page().filtros().buscar());
            filters.put(
                    "asociacionId",
                    command.page().filtros().asociacionId()
            );
            filters.put(
                    "situacion",
                    command.page().filtros().situacion()
            );
        }
        filters.put("pagina", page.pagina());
        filters.put("tamanoPagina", page.tamanio());

        return executePaged(
                CALL_LIST,
                payload(identity, metadata, filters, page, null),
                page.pagina(),
                page.tamanio(),
                this::summary
        );
    }

    @Override
    public PersistenceResult<ProducerModels.Detail> get(
            GetProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> filters = new LinkedHashMap<>();
        filters.put("socioId", command.socioId());

        String json = payload(
                identity,
                metadata,
                filters,
                null,
                null
        );

        PersistenceResult<ProducerModels.Detail> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<ProducerModels.Detail>>)
                                connection -> executeDetail(connection, json)
                );

        return result == null
                ? PersistenceResult.error(
                        "SQL Server no devolvió el detalle del socio."
                )
                : result;
    }

    @Override
    public PersistenceResult<Long> create(
            CreateProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> location = location(command.ubicacion());

        Map<String, Object> person = person(
                command.tipoDocumento(),
                command.numeroDocumento(),
                command.nombres(),
                command.apellidoPaterno(),
                command.apellidoMaterno(),
                command.telefono(),
                command.correo(),
                command.fechaNacimiento(),
                location
        );

        Map<String, Object> partner = new LinkedHashMap<>();
        partner.put("fechaAlta", date(command.fechaAlta()));
        partner.put("asociacionId", command.asociacionId());
        partner.put("codigoSocio", command.codigoSocio());
        partner.put("fechaDesde", date(command.fechaDesde()));
        partner.put(
                "situacionMembresia",
                command.situacionMembresia()
        );
        partner.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("persona", person);
        extra.put("socio", partner);
        extra.put("ubicacion", location);

        return executeCreate(
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Void> update(
            UpdateProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> location = location(command.ubicacion());

        Map<String, Object> person = person(
                command.tipoDocumento(),
                command.numeroDocumento(),
                command.nombres(),
                command.apellidoPaterno(),
                command.apellidoMaterno(),
                command.telefono(),
                command.correo(),
                command.fechaNacimiento(),
                location
        );
        person.put("socioId", command.socioId());

        Map<String, Object> partner = new LinkedHashMap<>();
        partner.put("socioId", command.socioId());
        partner.put("asociacionId", command.asociacionId());
        partner.put("codigoSocio", command.codigoSocio());
        partner.put("fechaDesde", date(command.fechaDesde()));
        partner.put(
                "situacionMembresia",
                command.situacionMembresia()
        );
        partner.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("persona", person);
        extra.put("socio", partner);
        extra.put("ubicacion", location);

        return executeMutation(
                CALL_UPDATE,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Void> retire(
            RetireProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> partner = new LinkedHashMap<>();
        partner.put("socioId", command.socioId());
        partner.put("fechaRetiro", date(command.fechaRetiro()));
        partner.put("motivo", command.motivo());

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("socio", partner);

        return executeMutation(
                CALL_RETIRE,
                payload(identity, metadata, null, null, extra)
        );
    }

    private PersistenceResult<ProducerModels.Detail> executeDetail(
            Connection connection,
            String payload
    ) throws SQLException {
        ProducerHeader header = null;
        List<ProducerModels.Membership> memberships =
                new ArrayList<>();
        List<ProducerModels.Property> properties =
                new ArrayList<>();
        List<ProducerModels.Campaign> campaigns =
                new ArrayList<>();

        try (CallableStatement statement =
                     connection.prepareCall(CALL_GET)) {
            statement.setNString(1, payload);
            statement.registerOutParameter(2, Types.BIT);
            statement.registerOutParameter(3, Types.NVARCHAR);

            boolean hasResultSet = statement.execute();
            int resultSetIndex = 0;

            while (true) {
                if (hasResultSet) {
                    try (ResultSet rs = statement.getResultSet()) {
                        if (resultSetIndex == 0) {
                            if (rs.next()) {
                                header = producerHeader(rs);
                            }
                        } else if (resultSetIndex == 1) {
                            while (rs.next()) {
                                memberships.add(
                                        new ProducerModels.Membership(
                                                nullableLong(
                                                        rs,
                                                        "socio_asociacion_id"
                                                ),
                                                nullableLong(
                                                        rs,
                                                        "asociacion_id"
                                                ),
                                                rs.getString(
                                                        "asociacionNombre"
                                                ),
                                                rs.getString(
                                                        "codigo_socio"
                                                ),
                                                localDate(
                                                        rs,
                                                        "fecha_desde"
                                                ),
                                                localDate(
                                                        rs,
                                                        "fecha_hasta"
                                                ),
                                                rs.getString(
                                                        "situacion_membresia"
                                                ),
                                                rs.getBoolean("estado")
                                        )
                                );
                            }
                        } else if (resultSetIndex == 2) {
                            while (rs.next()) {
                                properties.add(
                                        new ProducerModels.Property(
                                                nullableLong(
                                                        rs,
                                                        "predio_id"
                                                ),
                                                rs.getString("codigo"),
                                                rs.getString("nombre"),
                                                localDate(
                                                        rs,
                                                        "fecha_registro"
                                                ),
                                                rs.getBoolean("estado"),
                                                rs.getString(
                                                        "tipo_titularidad"
                                                ),
                                                rs.getBigDecimal(
                                                        "porcentaje"
                                                ),
                                                localDate(
                                                        rs,
                                                        "fecha_desde"
                                                ),
                                                localDate(
                                                        rs,
                                                        "fecha_hasta"
                                                )
                                        )
                                );
                            }
                        } else if (resultSetIndex == 3) {
                            while (rs.next()) {
                                campaigns.add(
                                        new ProducerModels.Campaign(
                                                nullableLong(
                                                        rs,
                                                        "participacion_campania_socio_id"
                                                ),
                                                nullableLong(
                                                        rs,
                                                        "campania_venta_id"
                                                ),
                                                rs.getString("codigo"),
                                                rs.getString("nombre"),
                                                localDate(
                                                        rs,
                                                        "fecha_inicio"
                                                ),
                                                localDate(
                                                        rs,
                                                        "fecha_fin"
                                                ),
                                                rs.getString(
                                                        "estado_proceso"
                                                ),
                                                rs.getString(
                                                        "estado_participacion"
                                                ),
                                                localDate(
                                                        rs,
                                                        "fecha_registro"
                                                )
                                        )
                                );
                            }
                        }
                    }
                    resultSetIndex++;
                } else if (statement.getUpdateCount() == -1) {
                    break;
                }

                hasResultSet = statement.getMoreResults();
            }

            boolean successful = statement.getBoolean(2);
            String message = statement.getNString(3);

            if (!successful) {
                return PersistenceResult.error(message(message));
            }

            if (header == null) {
                return PersistenceResult.error(
                        "El socio no devolvió una ficha de detalle."
                );
            }

            ProducerModels.Detail detail =
                    new ProducerModels.Detail(
                            header.socioId(),
                            header.tipoDocumento(),
                            header.numeroDocumento(),
                            header.nombres(),
                            header.apellidoPaterno(),
                            header.apellidoMaterno(),
                            header.telefono(),
                            header.correo(),
                            header.fechaNacimiento(),
                            header.fechaAlta(),
                            header.estado(),
                            header.distritoCodigo(),
                            header.distritoNombre(),
                            header.centroPobladoId(),
                            header.centroPobladoNombre(),
                            header.referencia(),
                            memberships,
                            properties,
                            campaigns
                    );

            return PersistenceResult.ok(message(message), detail);
        }
    }

    private ProducerHeader producerHeader(
            ResultSet rs
    ) throws SQLException {
        return new ProducerHeader(
                nullableLong(rs, "socio_id"),
                rs.getString("tipo_documento"),
                rs.getString("numero_documento"),
                rs.getString("nombres"),
                rs.getString("apellido_paterno"),
                rs.getString("apellido_materno"),
                rs.getString("telefono"),
                rs.getString("correo"),
                localDate(rs, "fecha_nacimiento"),
                localDate(rs, "fecha_alta"),
                rs.getBoolean("estado"),
                rs.getString("distritoCodigo"),
                rs.getString("distritoNombre"),
                nullableLong(rs, "centroPobladoId"),
                rs.getString("centroPobladoNombre"),
                rs.getString("referencia")
        );
    }

    private ProducerModels.Summary summary(
            ResultSet rs
    ) throws SQLException {
        return new ProducerModels.Summary(
                nullableLong(rs, "socio_id"),
                rs.getString("tipo_documento"),
                rs.getString("numero_documento"),
                rs.getString("nombres"),
                rs.getString("apellido_paterno"),
                rs.getString("apellido_materno"),
                rs.getString("telefono"),
                rs.getString("correo"),
                localDate(rs, "fecha_alta"),
                rs.getBoolean("estado"),
                nullableLong(rs, "socio_asociacion_id"),
                nullableLong(rs, "asociacion_id"),
                rs.getString("codigo_socio"),
                rs.getString("situacion_membresia"),
                rs.getString("asociacionNombre")
        );
    }

    private Map<String, Object> person(
            String type,
            String number,
            String names,
            String paternal,
            String maternal,
            String phone,
            String email,
            LocalDate birthDate,
            Map<String, Object> location
    ) {
        Map<String, Object> value = new LinkedHashMap<>();
        value.put("tipoDocumento", type);
        value.put("numeroDocumento", number);
        value.put("nombres", names);
        value.put("apellidoPaterno", paternal);
        value.put("apellidoMaterno", maternal);
        value.put("telefono", phone);
        value.put("correo", email);
        value.put("fechaNacimiento", date(birthDate));
        value.put("ubicacion", location);
        return value;
    }

    private Map<String, Object> location(
            LocationInput location
    ) {
        if (location == null) {
            return null;
        }

        Map<String, Object> value = new LinkedHashMap<>();
        value.put("distritoCodigo", location.distritoCodigo());
        value.put("centroPobladoId", location.centroPobladoId());
        value.put("referencia", location.referencia());
        return value;
    }

    private <T> PersistenceResult<PageResult<T>> executePaged(
            String callSql,
            String payload,
            int page,
            int size,
            RowMapper<T> mapper
    ) {
        PersistenceResult<PageResult<T>> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<PageResult<T>>>)
                                connection -> {
                                    List<T> items = new ArrayList<>();
                                    long total = 0L;

                                    try (CallableStatement statement =
                                                 connection.prepareCall(callSql)) {
                                        statement.setNString(1, payload);
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
                                        boolean firstResultSet = true;

                                        while (true) {
                                            if (hasResultSet) {
                                                try (ResultSet rs =
                                                             statement.getResultSet()) {
                                                    if (firstResultSet) {
                                                        while (rs.next()) {
                                                            items.add(
                                                                    mapper.map(rs)
                                                            );
                                                            total = rs.getLong(
                                                                    "totalRegistros"
                                                            );
                                                        }
                                                    }
                                                }
                                                firstResultSet = false;
                                            } else if (
                                                    statement.getUpdateCount()
                                                            == -1
                                            ) {
                                                break;
                                            }

                                            hasResultSet =
                                                    statement.getMoreResults();
                                        }

                                        if (!statement.getBoolean(2)) {
                                            return PersistenceResult.error(
                                                    message(
                                                            statement
                                                                    .getNString(3)
                                                    )
                                            );
                                        }

                                        int safeSize = Math.max(1, size);
                                        int pages = total == 0
                                                ? 0
                                                : (int) Math.ceil(
                                                        (double) total
                                                                / safeSize
                                                );

                                        return PersistenceResult.ok(
                                                message(
                                                        statement.getNString(3)
                                                ),
                                                new PageResult<>(
                                                        items,
                                                        Math.max(1, page),
                                                        safeSize,
                                                        total,
                                                        pages
                                                )
                                        );
                                    }
                                }
                );

        return result == null
                ? PersistenceResult.error(
                        "SQL Server no devolvió una respuesta."
                )
                : result;
    }

    private PersistenceResult<Long> executeCreate(
            String payload
    ) {
        PersistenceResult<Long> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<Long>>)
                                connection -> {
                                    try (CallableStatement statement =
                                                 connection.prepareCall(
                                                         CALL_CREATE
                                                 )) {
                                        statement.setNString(1, payload);
                                        statement.registerOutParameter(
                                                2,
                                                Types.BIGINT
                                        );
                                        statement.registerOutParameter(
                                                3,
                                                Types.BIGINT
                                        );
                                        statement.registerOutParameter(
                                                4,
                                                Types.BIT
                                        );
                                        statement.registerOutParameter(
                                                5,
                                                Types.NVARCHAR
                                        );

                                        consume(statement);

                                        if (!statement.getBoolean(4)) {
                                            return PersistenceResult.error(
                                                    message(
                                                            statement
                                                                    .getNString(5)
                                                    )
                                            );
                                        }

                                        Long partnerId = nullableOutputLong(
                                                statement,
                                                2
                                        );

                                        return PersistenceResult.ok(
                                                message(
                                                        statement.getNString(5)
                                                ),
                                                partnerId
                                        );
                                    }
                                }
                );

        return result == null
                ? PersistenceResult.error(
                        "SQL Server no devolvió una respuesta."
                )
                : result;
    }

    private PersistenceResult<Void> executeMutation(
            String callSql,
            String payload
    ) {
        PersistenceResult<Void> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<Void>>)
                                connection -> {
                                    try (CallableStatement statement =
                                                 connection.prepareCall(callSql)) {
                                        statement.setNString(1, payload);
                                        statement.registerOutParameter(
                                                2,
                                                Types.BIT
                                        );
                                        statement.registerOutParameter(
                                                3,
                                                Types.NVARCHAR
                                        );

                                        consume(statement);

                                        if (!statement.getBoolean(2)) {
                                            return PersistenceResult.error(
                                                    message(
                                                            statement
                                                                    .getNString(3)
                                                    )
                                            );
                                        }

                                        return PersistenceResult.ok(
                                                message(
                                                        statement.getNString(3)
                                                ),
                                                null
                                        );
                                    }
                                }
                );

        return result == null
                ? PersistenceResult.error(
                        "SQL Server no devolvió una respuesta."
                )
                : result;
    }

    private void consume(
            CallableStatement statement
    ) throws SQLException {
        boolean hasResultSet = statement.execute();

        while (true) {
            if (hasResultSet) {
                try (ResultSet rs = statement.getResultSet()) {
                    while (rs.next()) {
                        // Los PA de escritura no necesitan filas aquí.
                    }
                }
            } else if (statement.getUpdateCount() == -1) {
                break;
            }

            hasResultSet = statement.getMoreResults();
        }
    }

    private String payload(
            SessionIdentity identity,
            RequestMetadata metadata,
            Map<String, Object> filters,
            PageRequest<?> page,
            Map<String, Object> extra
    ) {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("contexto", context(identity, metadata));

        if (page != null) {
            root.put("paginacion", pagination(page));
        }
        if (filters != null) {
            root.put("filtros", filters);
        }
        if (extra != null) {
            root.putAll(extra);
        }

        try {
            return jsonMapper.writeValueAsString(root);
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo construir el payload del socio.",
                    exception
            );
        }
    }

    private Map<String, Object> context(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put(
                "sesionPublicaId",
                text(identity.sesionPublicaId())
        );
        context.put(
                "correlacionId",
                text(metadata.correlacionId())
        );
        context.put(
                "solicitudId",
                text(metadata.solicitudId())
        );
        context.put(
                "claveIdempotencia",
                text(metadata.claveIdempotencia())
        );
        context.put("requestHashHex", null);
        context.put("ip", metadata.ip());
        context.put("endpoint", metadata.endpoint());
        return context;
    }

    private Map<String, Object> pagination(
            PageRequest<?> page
    ) {
        Map<String, Object> pagination = new LinkedHashMap<>();
        pagination.put("pagina", page.pagina());
        pagination.put("tamanoPagina", page.tamanio());
        pagination.put("tamano", page.tamanio());
        return pagination;
    }

    private String date(LocalDate value) {
        return value == null ? null : value.toString();
    }

    private String text(Object value) {
        return value == null ? null : value.toString();
    }

    private String message(String value) {
        return value == null || value.isBlank()
                ? "La operación no devolvió un mensaje."
                : value;
    }

    private Long nullableOutputLong(
            CallableStatement statement,
            int index
    ) throws SQLException {
        long value = statement.getLong(index);
        return statement.wasNull() ? null : value;
    }

    private Long nullableLong(
            ResultSet rs,
            String column
    ) throws SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private LocalDate localDate(
            ResultSet rs,
            String column
    ) throws SQLException {
        Date value = rs.getDate(column);
        return value == null ? null : value.toLocalDate();
    }

    private record ProducerHeader(
            Long socioId,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            LocalDate fechaAlta,
            boolean estado,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referencia
    ) {
    }

    @FunctionalInterface
    private interface RowMapper<T> {
        T map(ResultSet resultSet) throws SQLException;
    }
}
