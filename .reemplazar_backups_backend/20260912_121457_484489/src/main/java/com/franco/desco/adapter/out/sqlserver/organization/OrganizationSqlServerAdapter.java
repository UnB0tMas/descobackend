package com.franco.desco.adapter.out.sqlserver.organization;

import com.franco.desco.application.organization.OrganizationCommands.CreateArea;
import com.franco.desco.application.organization.OrganizationCommands.CreateAssociation;
import com.franco.desco.application.organization.OrganizationCommands.CreateCompany;
import com.franco.desco.application.organization.OrganizationCommands.GetOrganization;
import com.franco.desco.application.organization.OrganizationCommands.ListAreas;
import com.franco.desco.application.organization.OrganizationCommands.ListOrganizations;
import com.franco.desco.application.organization.OrganizationCommands.LocationInput;
import com.franco.desco.application.organization.OrganizationCommands.UpdateArea;
import com.franco.desco.application.organization.OrganizationCommands.UpdateAssociation;
import com.franco.desco.application.organization.OrganizationCommands.UpdateCompany;
import com.franco.desco.application.organization.port.out.OrganizationPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.organization.OrganizationModels;
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
public class OrganizationSqlServerAdapter
        implements OrganizationPersistencePort {

    private static final String CALL_LIST =
            "{call org.PA_Empresa_Sel_Listado(?,?,?)}";
    private static final String CALL_GET =
            "{call org.PA_Empresa_Sel_Detalle(?,?,?)}";
    private static final String CALL_CREATE_COMPANY =
            "{call org.PA_Empresa_Ins_Registro(?,?,?,?)}";
    private static final String CALL_UPDATE_COMPANY =
            "{call org.PA_Empresa_Upd_Registro(?,?,?)}";
    private static final String CALL_CREATE_ASSOCIATION =
            "{call org.PA_Asociacion_Ins_Registro(?,?,?,?)}";
    private static final String CALL_UPDATE_ASSOCIATION =
            "{call org.PA_Asociacion_Upd_Registro(?,?,?)}";
    private static final String CALL_LIST_AREAS =
            "{call org.PA_Area_Sel_Listado(?,?,?)}";
    private static final String CALL_CREATE_AREA =
            "{call org.PA_Area_Ins_Registro(?,?,?,?)}";
    private static final String CALL_UPDATE_AREA =
            "{call org.PA_Area_Upd_Registro(?,?,?)}";

    private final JdbcTemplate jdbcTemplate;
    private final JsonMapper jsonMapper;

    public OrganizationSqlServerAdapter(
            JdbcTemplate jdbcTemplate,
            JsonMapper jsonMapper
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public PersistenceResult<PageResult<OrganizationModels.Summary>> list(
            ListOrganizations command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PageRequest<?> page = command.page();

        return executePaged(
                CALL_LIST,
                payload(identity, metadata, null, page, null),
                page.pagina(),
                page.tamanio(),
                this::summary
        );
    }

    @Override
    public PersistenceResult<OrganizationModels.Detail> get(
            GetOrganization command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> organization = new LinkedHashMap<>();
        organization.put("empresaId", command.empresaId());

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("organizacion", organization);

        String json = payload(
                identity,
                metadata,
                null,
                null,
                extra
        );

        PersistenceResult<OrganizationModels.Detail> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<OrganizationModels.Detail>>)
                                connection -> executeDetail(connection, json)
                );

        return result == null
                ? PersistenceResult.error(
                        "SQL Server no devolvió el detalle de la organización."
                )
                : result;
    }

    @Override
    public PersistenceResult<Long> createCompany(
            CreateCompany command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> location = location(command.ubicacion());

        Map<String, Object> company = new LinkedHashMap<>();
        company.put("ruc", command.ruc());
        company.put("razonSocial", command.razonSocial());
        company.put(
                "nombreComercial",
                command.nombreComercial()
        );
        company.put("telefono", command.telefono());
        company.put("correo", command.correo());
        company.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("empresa", company);
        extra.put("ubicacion", location);

        return executeCreate(
                CALL_CREATE_COMPANY,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Void> updateCompany(
            UpdateCompany command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> location = location(command.ubicacion());

        Map<String, Object> company = new LinkedHashMap<>();
        company.put("empresaId", command.empresaId());
        company.put("razonSocial", command.razonSocial());
        company.put(
                "nombreComercial",
                command.nombreComercial()
        );
        company.put("telefono", command.telefono());
        company.put("correo", command.correo());
        company.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("empresa", company);
        extra.put("ubicacion", location);

        return executeMutation(
                CALL_UPDATE_COMPANY,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Long> createAssociation(
            CreateAssociation command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> location = location(command.ubicacion());

        Map<String, Object> association = new LinkedHashMap<>();
        association.put("ruc", command.ruc());
        association.put("razonSocial", command.razonSocial());
        association.put(
                "nombreComercial",
                command.nombreComercial()
        );
        association.put("telefono", command.telefono());
        association.put("correo", command.correo());
        association.put(
                "fechaConstitucion",
                date(command.fechaConstitucion())
        );
        association.put(
                "numeroPartida",
                command.numeroPartida()
        );
        association.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("asociacion", association);
        extra.put("ubicacion", location);

        return executeCreate(
                CALL_CREATE_ASSOCIATION,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Void> updateAssociation(
            UpdateAssociation command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> location = location(command.ubicacion());

        Map<String, Object> association = new LinkedHashMap<>();
        association.put(
                "asociacionId",
                command.asociacionId()
        );
        association.put(
                "empresaId",
                command.asociacionId()
        );
        association.put("razonSocial", command.razonSocial());
        association.put(
                "nombreComercial",
                command.nombreComercial()
        );
        association.put("telefono", command.telefono());
        association.put("correo", command.correo());
        association.put(
                "fechaConstitucion",
                date(command.fechaConstitucion())
        );
        association.put(
                "numeroPartida",
                command.numeroPartida()
        );
        association.put("ubicacion", location);

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("asociacion", association);
        extra.put("ubicacion", location);

        return executeMutation(
                CALL_UPDATE_ASSOCIATION,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<PageResult<OrganizationModels.Area>> listAreas(
            ListAreas command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PageRequest<?> page = command.page();

        Map<String, Object> filters = new LinkedHashMap<>();
        if (command.page().filtros() != null) {
            filters.put(
                    "empresaId",
                    command.page().filtros().empresaId()
            );
        }

        return executePaged(
                CALL_LIST_AREAS,
                payload(identity, metadata, filters, page, null),
                page.pagina(),
                page.tamanio(),
                this::area
        );
    }

    @Override
    public PersistenceResult<Long> createArea(
            CreateArea command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> area = new LinkedHashMap<>();
        area.put("empresaId", command.empresaId());
        area.put("areaPadreId", command.areaPadreId());
        area.put("codigo", command.codigo());
        area.put("nombre", command.nombre());

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("area", area);

        return executeCreate(
                CALL_CREATE_AREA,
                payload(identity, metadata, null, null, extra)
        );
    }

    @Override
    public PersistenceResult<Void> updateArea(
            UpdateArea command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> area = new LinkedHashMap<>();
        area.put("areaId", command.areaId());
        area.put("areaPadreId", command.areaPadreId());
        area.put("nombre", command.nombre());

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("area", area);

        return executeMutation(
                CALL_UPDATE_AREA,
                payload(identity, metadata, null, null, extra)
        );
    }

    private PersistenceResult<OrganizationModels.Detail> executeDetail(
            Connection connection,
            String payload
    ) throws SQLException {
        OrganizationHeader header = null;
        List<AreaSeed> areaSeeds = new ArrayList<>();
        List<OrganizationModels.EmployeeLite> employees =
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
                                header = organizationHeader(rs);
                            }
                        } else if (resultSetIndex == 1) {
                            while (rs.next()) {
                                areaSeeds.add(
                                        new AreaSeed(
                                                nullableLong(
                                                        rs,
                                                        "areaId"
                                                ),
                                                nullableLong(
                                                        rs,
                                                        "areaPadreId"
                                                ),
                                                rs.getString("codigo"),
                                                rs.getString("nombre"),
                                                rs.getBoolean("estado")
                                        )
                                );
                            }
                        } else if (resultSetIndex == 2) {
                            while (rs.next()) {
                                employees.add(
                                        new OrganizationModels.EmployeeLite(
                                                nullableLong(
                                                        rs,
                                                        "empleadoId"
                                                ),
                                                rs.getString(
                                                        "codigoEmpleado"
                                                ),
                                                rs.getString(
                                                        "numeroDocumento"
                                                ),
                                                rs.getString("empleado")
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
                        "La organización no devolvió una ficha de detalle."
                );
            }

            List<OrganizationModels.Area> areas =
                    areas(
                            areaSeeds,
                            header.summary()
                    );

            OrganizationModels.Detail detail =
                    new OrganizationModels.Detail(
                            header.summary(),
                            header.distritoCodigo(),
                            header.distritoNombre(),
                            header.centroPobladoId(),
                            header.centroPobladoNombre(),
                            header.referencia(),
                            header.altitudM(),
                            header.posicionWkt(),
                            header.posicionSrid(),
                            areas,
                            employees
                    );

            return PersistenceResult.ok(message(message), detail);
        }
    }

    private OrganizationHeader organizationHeader(
            ResultSet rs
    ) throws SQLException {
        LocalDate foundation =
                localDate(rs, "fechaConstitucion");
        String registration =
                rs.getString("numeroPartida");

        boolean association = associationFlag(
                rs,
                foundation,
                registration
        );

        OrganizationModels.Summary summary =
                new OrganizationModels.Summary(
                        nullableLong(rs, "empresa_id"),
                        rs.getString("ruc"),
                        rs.getString("razon_social"),
                        rs.getString("nombre_comercial"),
                        rs.getString("telefono"),
                        rs.getString("correo"),
                        instant(rs, "fecha_creacion"),
                        rs.getBoolean("estado"),
                        association,
                        foundation,
                        registration
                );

        return new OrganizationHeader(
                summary,
                rs.getString("distritoCodigo"),
                rs.getString("distritoNombre"),
                nullableLong(rs, "centroPobladoId"),
                rs.getString("centroPobladoNombre"),
                rs.getString("referencia"),
                rs.getBigDecimal("altitudM"),
                rs.getString("posicionWkt"),
                nullableInteger(rs, "posicionSrid")
        );
    }

    private OrganizationModels.Summary summary(
            ResultSet rs
    ) throws SQLException {
        return new OrganizationModels.Summary(
                nullableLong(rs, "empresaId"),
                rs.getString("ruc"),
                rs.getString("razonSocial"),
                rs.getString("nombreComercial"),
                rs.getString("telefono"),
                rs.getString("correo"),
                instant(rs, "fechaCreacion"),
                rs.getBoolean("estado"),
                rs.getBoolean("esAsociacion"),
                localDate(rs, "fechaConstitucion"),
                rs.getString("numeroPartida")
        );
    }

    private OrganizationModels.Area area(
            ResultSet rs
    ) throws SQLException {
        return new OrganizationModels.Area(
                nullableLong(rs, "areaId"),
                nullableLong(rs, "empresaId"),
                rs.getString("empresa"),
                nullableLong(rs, "areaPadreId"),
                rs.getString("areaPadre"),
                rs.getString("codigo"),
                rs.getString("nombre"),
                rs.getBoolean("estado")
        );
    }

    private List<OrganizationModels.Area> areas(
            List<AreaSeed> seeds,
            OrganizationModels.Summary organization
    ) {
        Map<Long, String> names = new LinkedHashMap<>();

        for (AreaSeed seed : seeds) {
            if (seed.areaId() != null) {
                names.put(seed.areaId(), seed.nombre());
            }
        }

        List<OrganizationModels.Area> result =
                new ArrayList<>();

        for (AreaSeed seed : seeds) {
            result.add(
                    new OrganizationModels.Area(
                            seed.areaId(),
                            organization.empresaId(),
                            organization.razonSocial(),
                            seed.areaPadreId(),
                            seed.areaPadreId() == null
                                    ? null
                                    : names.get(seed.areaPadreId()),
                            seed.codigo(),
                            seed.nombre(),
                            seed.estado()
                    )
            );
        }

        return result;
    }

    private boolean associationFlag(
            ResultSet rs,
            LocalDate foundation,
            String registration
    ) {
        try {
            boolean value = rs.getBoolean("esAsociacion");
            if (!rs.wasNull()) {
                return value;
            }
        } catch (SQLException ignored) {
            // El PA geográfico vigente no expone aún esta columna.
        }

        return foundation != null
                || (registration != null && !registration.isBlank());
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
                        // No se necesitan filas para estas escrituras.
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
                    "No se pudo construir el payload de organizaciones.",
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

    private Integer nullableInteger(
            ResultSet rs,
            String column
    ) throws SQLException {
        int value = rs.getInt(column);
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

    private record OrganizationHeader(
            OrganizationModels.Summary summary,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referencia,
            java.math.BigDecimal altitudM,
            String posicionWkt,
            Integer posicionSrid
    ) {
    }

    private record AreaSeed(
            Long areaId,
            Long areaPadreId,
            String codigo,
            String nombre,
            boolean estado
    ) {
    }

    @FunctionalInterface
    private interface RowMapper<T> {
        T map(ResultSet resultSet) throws SQLException;
    }
}
