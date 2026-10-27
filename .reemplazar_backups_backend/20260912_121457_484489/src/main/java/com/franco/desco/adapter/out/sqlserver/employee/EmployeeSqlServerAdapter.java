package com.franco.desco.adapter.out.sqlserver.employee;

import com.franco.desco.application.employee.EmployeeCommands.CreateEmployee;
import com.franco.desco.application.employee.EmployeeCommands.GetEmployee;
import com.franco.desco.application.employee.EmployeeCommands.ListEmployees;
import com.franco.desco.application.employee.EmployeeCommands.LocationInput;
import com.franco.desco.application.employee.EmployeeCommands.RetireEmployee;
import com.franco.desco.application.employee.EmployeeCommands.UpdateEmployee;
import com.franco.desco.application.employee.port.out.EmployeePersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.employee.EmployeeModels;
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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class EmployeeSqlServerAdapter
        implements EmployeePersistencePort {

    private static final String CALL_LIST =
            "{call org.PA_Empleado_Sel_Listado(?,?,?)}";
    private static final String CALL_GET =
            "{call org.PA_Empleado_Sel_Detalle(?,?,?)}";
    private static final String CALL_CREATE =
            "{call org.PA_Empleado_Ins_Registro(?,?,?,?)}";
    private static final String CALL_UPDATE =
            "{call org.PA_Empleado_Upd_Registro(?,?,?)}";
    private static final String CALL_RETIRE =
            "{call org.PA_Empleado_Del_Registro(?,?,?)}";

    private final JdbcTemplate jdbcTemplate;
    private final JsonMapper jsonMapper;

    public EmployeeSqlServerAdapter(
            JdbcTemplate jdbcTemplate,
            JsonMapper jsonMapper
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public PersistenceResult<PageResult<EmployeeModels.Summary>> list(
            ListEmployees command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PageRequest<?> page = command.page();

        Map<String, Object> filters = new LinkedHashMap<>();
        if (page.filtros() != null) {
            filters.put("empresaId", command.page().filtros().empresaId());
            filters.put("areaId", command.page().filtros().areaId());
            filters.put("activo", command.page().filtros().activo());
        }

        return executePaged(
                CALL_LIST,
                payload(identity, metadata, filters, page, null, null),
                page.pagina(),
                page.tamanio(),
                this::summary
        );
    }

    @Override
    public PersistenceResult<EmployeeModels.Detail> get(
            GetEmployee command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> employee = new LinkedHashMap<>();
        employee.put("empleadoId", command.empleadoId());

        String json = payload(
                identity,
                metadata,
                null,
                null,
                "empleado",
                employee
        );

        PersistenceResult<EmployeeModels.Detail> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<EmployeeModels.Detail>>)
                                connection -> executeDetail(connection, json)
                );

        return result == null
                ? PersistenceResult.error("SQL Server no devolvió el detalle del empleado.")
                : result;
    }

    @Override
    public PersistenceResult<Long> create(
            CreateEmployee command,
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

        Map<String, Object> employee = new LinkedHashMap<>(person);
        employee.put("empresaId", command.empresaId());
        employee.put("codigoEmpleado", command.codigoEmpleado());
        employee.put("fechaIngreso", date(command.fechaIngreso()));
        employee.put("areaId", command.areaId());
        employee.put("cargo", command.cargo());
        employee.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("persona", person);
        extra.put("empleado", employee);
        extra.put("ubicacion", location);

        return executeCreate(
                CALL_CREATE,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Void> update(
            UpdateEmployee command,
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

        Map<String, Object> employee = new LinkedHashMap<>(person);
        employee.put("empleadoId", command.empleadoId());
        employee.put("empresaId", command.empresaId());
        employee.put("codigoEmpleado", command.codigoEmpleado());
        employee.put("fechaIngreso", date(command.fechaIngreso()));
        employee.put("areaId", command.areaId());
        employee.put("cargo", command.cargo());
        employee.put(
                "fechaAsignacionArea",
                date(command.fechaAsignacionArea())
        );
        employee.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("empleadoId", command.empleadoId());
        extra.put("persona", person);
        extra.put("empleado", employee);
        extra.put("ubicacion", location);

        return executeMutation(
                CALL_UPDATE,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Void> retire(
            RetireEmployee command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> employee = new LinkedHashMap<>();
        employee.put("empleadoId", command.empleadoId());
        employee.put("motivo", command.motivo());
        employee.put("fechaCese", date(command.fechaCese()));

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("empleadoId", command.empleadoId());
        extra.put("motivo", command.motivo());
        extra.put("fechaCese", date(command.fechaCese()));
        extra.put("empleado", employee);

        return executeMutation(
                CALL_RETIRE,
                payload(identity, metadata, null, null, extra)
        );
    }

    private PersistenceResult<EmployeeModels.Detail> executeDetail(
            Connection connection,
            String payload
    ) throws SQLException {
        EmployeeHeader header = null;
        List<EmployeeModels.AreaHistory> areas = new ArrayList<>();
        EmployeeModels.UserBrief user = null;
        List<EmployeeModels.RoleBrief> roles = new ArrayList<>();

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
                                header = employeeHeader(rs);
                            }
                        } else if (resultSetIndex == 1) {
                            while (rs.next()) {
                                areas.add(new EmployeeModels.AreaHistory(
                                        nullableLong(rs, "empleadoAreaId"),
                                        nullableLong(rs, "areaId"),
                                        rs.getString("area"),
                                        rs.getString("cargo"),
                                        localDate(rs, "fechaDesde"),
                                        localDate(rs, "fechaHasta"),
                                        rs.getBoolean("estado")
                                ));
                            }
                        } else if (resultSetIndex == 2) {
                            if (rs.next()) {
                                user = new EmployeeModels.UserBrief(
                                        nullableLong(rs, "usuarioId"),
                                        rs.getString("nombreUsuario"),
                                        rs.getString("estadoCuenta"),
                                        instant(rs, "ultimoAccesoCorrecto"),
                                        rs.getBoolean("segundoFactorHabilitado")
                                );
                            }
                        } else if (resultSetIndex == 3) {
                            while (rs.next()) {
                                roles.add(new EmployeeModels.RoleBrief(
                                        nullableLong(rs, "rolId"),
                                        rs.getString("codigo"),
                                        rs.getString("nombre"),
                                        instant(rs, "fechaDesde"),
                                        instant(rs, "fechaHasta"),
                                        rs.getBoolean("estado")
                                ));
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
                        "El empleado no devolvió una ficha de detalle."
                );
            }

            EmployeeModels.Detail detail =
                    new EmployeeModels.Detail(
                            header.empleadoId(),
                            header.empresaId(),
                            header.empresa(),
                            header.codigoEmpleado(),
                            header.fechaIngreso(),
                            header.fechaCese(),
                            header.estado(),
                            header.tipoDocumento(),
                            header.numeroDocumento(),
                            header.nombres(),
                            header.apellidoPaterno(),
                            header.apellidoMaterno(),
                            header.telefono(),
                            header.correo(),
                            header.fechaNacimiento(),
                            header.distritoCodigo(),
                            header.distritoNombre(),
                            header.centroPobladoId(),
                            header.centroPobladoNombre(),
                            header.referencia(),
                            areas,
                            user,
                            roles
                    );

            return PersistenceResult.ok(message(message), detail);
        }
    }

    private EmployeeHeader employeeHeader(
            ResultSet rs
    ) throws SQLException {
        return new EmployeeHeader(
                nullableLong(rs, "empleado_id"),
                nullableLong(rs, "empresa_id"),
                rs.getString("empresa"),
                rs.getString("codigo_empleado"),
                localDate(rs, "fecha_ingreso"),
                localDate(rs, "fecha_cese"),
                rs.getBoolean("estado"),
                rs.getString("tipoDocumento"),
                rs.getString("numeroDocumento"),
                rs.getString("nombres"),
                rs.getString("apellidoPaterno"),
                rs.getString("apellidoMaterno"),
                rs.getString("telefono"),
                rs.getString("correo"),
                localDate(rs, "fechaNacimiento"),
                rs.getString("distritoCodigo"),
                rs.getString("distritoNombre"),
                nullableLong(rs, "centroPobladoId"),
                rs.getString("centroPobladoNombre"),
                rs.getString("referencia")
        );
    }

    private EmployeeModels.Summary summary(
            ResultSet rs
    ) throws SQLException {
        return new EmployeeModels.Summary(
                nullableLong(rs, "empleadoId"),
                nullableLong(rs, "empresaId"),
                rs.getString("empresa"),
                rs.getString("codigoEmpleado"),
                localDate(rs, "fechaIngreso"),
                localDate(rs, "fechaCese"),
                rs.getBoolean("estado"),
                rs.getString("tipoDocumento"),
                rs.getString("numeroDocumento"),
                rs.getString("nombres"),
                rs.getString("apellidoPaterno"),
                rs.getString("apellidoMaterno"),
                rs.getString("telefono"),
                rs.getString("correo"),
                nullableLong(rs, "areaId"),
                rs.getString("area"),
                rs.getString("cargo"),
                nullableLong(rs, "usuarioId"),
                rs.getString("nombreUsuario"),
                rs.getString("estadoCuenta")
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
            String callSql,
            String payload
    ) {
        PersistenceResult<Long> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<Long>>)
                                connection -> {
                                    try (CallableStatement statement =
                                                 connection.prepareCall(callSql)) {
                                        statement.setNString(1, payload);
                                        statement.registerOutParameter(
                                                2,
                                                Types.BIGINT
                                        );
                                        statement.registerOutParameter(
                                                3,
                                                Types.BIT
                                        );
                                        statement.registerOutParameter(
                                                4,
                                                Types.NVARCHAR
                                        );

                                        consume(statement);

                                        if (!statement.getBoolean(3)) {
                                            return PersistenceResult.error(
                                                    message(
                                                            statement
                                                                    .getNString(4)
                                                    )
                                            );
                                        }

                                        Long id = nullableOutputLong(
                                                statement,
                                                2
                                        );

                                        return PersistenceResult.ok(
                                                message(
                                                        statement.getNString(4)
                                                ),
                                                id
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
                        // El PA de escritura no necesita datos tabulares.
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
            String objectName,
            Map<String, Object> objectValue
    ) {
        Map<String, Object> root = root(identity, metadata);

        if (page != null) {
            root.put("paginacion", pagination(page));
        }
        if (filters != null) {
            root.put("filtros", filters);
        }
        if (objectName != null) {
            root.put(objectName, objectValue);
        }

        return json(root);
    }

    private String payload(
            SessionIdentity identity,
            RequestMetadata metadata,
            Map<String, Object> filters,
            PageRequest<?> page,
            Map<String, Object> extra
    ) {
        Map<String, Object> root = root(identity, metadata);

        if (page != null) {
            root.put("paginacion", pagination(page));
        }
        if (filters != null) {
            root.put("filtros", filters);
        }
        if (extra != null) {
            root.putAll(extra);
        }

        return json(root);
    }

    private Map<String, Object> root(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("contexto", context(identity, metadata));
        return root;
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

    private String json(
            Map<String, Object> value
    ) {
        try {
            return jsonMapper.writeValueAsString(value);
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo construir el payload del empleado.",
                    exception
            );
        }
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

    private Instant instant(
            ResultSet rs,
            String column
    ) throws SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toInstant();
    }

    private record EmployeeHeader(
            Long empleadoId,
            Long empresaId,
            String empresa,
            String codigoEmpleado,
            LocalDate fechaIngreso,
            LocalDate fechaCese,
            boolean estado,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
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
