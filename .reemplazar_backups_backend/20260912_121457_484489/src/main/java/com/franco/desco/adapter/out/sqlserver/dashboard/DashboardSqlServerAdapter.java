package com.franco.desco.adapter.out.sqlserver.dashboard;

import com.franco.desco.application.dashboard.port.out.DashboardPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboard.DashboardModels;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class DashboardSqlServerAdapter
        implements DashboardPersistencePort {

    private static final String CALL_SQL =
            "{call dbo.PA_Dashboard_Sel_Resumen(?,?,?)}";

    private final JdbcTemplate jdbcTemplate;
    private final JsonMapper jsonMapper;

    public DashboardSqlServerAdapter(
            JdbcTemplate jdbcTemplate,
            JsonMapper jsonMapper
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public PersistenceResult<DashboardModels.Summary> summary(
            SessionIdentity identity,
            RequestMetadata metadata,
            DashboardModels.Filter filter
    ) {
        String payload = payload(identity, metadata, filter);

        PersistenceResult<DashboardModels.Summary> result =
                jdbcTemplate.execute(
                        (ConnectionCallback<PersistenceResult<DashboardModels.Summary>>)
                                connection -> execute(
                                        connection,
                                        payload,
                                        filter
                                )
                );

        if (result == null) {
            return PersistenceResult.error(
                    "No se obtuvo respuesta al consultar el dashboard."
            );
        }

        return result;
    }

    private PersistenceResult<DashboardModels.Summary> execute(
            Connection connection,
            String payload,
            DashboardModels.Filter filter
    ) throws SQLException {
        List<DashboardModels.Indicator> indicators = new ArrayList<>();
        List<DashboardModels.Alert> alerts = new ArrayList<>();
        List<DashboardModels.Shortcut> shortcuts = new ArrayList<>();
        Map<String, MutableGraph> graphs = new LinkedHashMap<>();

        try (CallableStatement statement =
                     connection.prepareCall(CALL_SQL)) {
            statement.setNString(1, payload);
            statement.registerOutParameter(2, Types.BIT);
            statement.registerOutParameter(3, Types.NVARCHAR);

            boolean resultSetAvailable = statement.execute();
            int resultSetIndex = 0;

            while (true) {
                if (resultSetAvailable) {
                    resultSetIndex++;

                    try (ResultSet resultSet = statement.getResultSet()) {
                        switch (resultSetIndex) {
                            case 1 -> readIndicators(resultSet, indicators);
                            case 2 -> readAlerts(resultSet, alerts);
                            case 3 -> readShortcuts(resultSet, shortcuts);
                            case 4 -> readGraphDefinitions(resultSet, graphs);
                            case 5 -> readGraphPoints(resultSet, graphs);
                            default -> drain(resultSet);
                        }
                    }
                } else if (statement.getUpdateCount() == -1) {
                    break;
                }

                resultSetAvailable = statement.getMoreResults();
            }

            boolean successful = statement.getBoolean(2);
            String message = statement.getNString(3);

            if (!successful) {
                return PersistenceResult.error(
                        hasText(message)
                                ? message
                                : "No se pudo cargar el dashboard."
                );
            }

            List<DashboardModels.Graph> graphList = graphs
                    .values()
                    .stream()
                    .map(MutableGraph::domain)
                    .sorted(Comparator.comparing(
                            DashboardModels.Graph::orden,
                            Comparator.nullsLast(Integer::compareTo)
                    ))
                    .toList();

            DashboardModels.Summary summary =
                    new DashboardModels.Summary(
                            new DashboardModels.Period(
                                    filter.desde(),
                                    filter.hasta()
                            ),
                            indicators,
                            graphList,
                            alerts,
                            shortcuts
                    );

            return PersistenceResult.ok(
                    hasText(message)
                            ? message
                            : "Inicio cargado correctamente.",
                    summary
            );
        }
    }

    private String payload(
            SessionIdentity identity,
            RequestMetadata metadata,
            DashboardModels.Filter filter
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
        context.put(
                "claveIdempotencia",
                metadata.claveIdempotencia() == null
                        ? null
                        : metadata.claveIdempotencia().toString()
        );
        context.put("ip", metadata.ip());
        context.put("endpoint", metadata.endpoint());
        context.put("deviceId", metadata.deviceId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("desde", date(filter.desde()));
        data.put("hasta", date(filter.hasta()));

        Map<String, Object> root = new LinkedHashMap<>();
        root.put("contexto", context);
        root.put("datos", data);

        try {
            return jsonMapper.writeValueAsString(root);
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo construir el contexto del dashboard.",
                    exception
            );
        }
    }

    private void readIndicators(
            ResultSet resultSet,
            List<DashboardModels.Indicator> target
    ) throws SQLException {
        while (resultSet.next()) {
            target.add(
                    new DashboardModels.Indicator(
                            resultSet.getString("codigo"),
                            resultSet.getString("indicador"),
                            resultSet.getBigDecimal("valor"),
                            resultSet.getString("unidad"),
                            resultSet.getString("icono"),
                            nullableInteger(resultSet, "orden")
                    )
            );
        }
    }

    private void readAlerts(
            ResultSet resultSet,
            List<DashboardModels.Alert> target
    ) throws SQLException {
        while (resultSet.next()) {
            target.add(
                    new DashboardModels.Alert(
                            resultSet.getString("tipo"),
                            resultSet.getString("mensaje"),
                            nullableLong(resultSet, "cantidad"),
                            nullableInteger(resultSet, "orden")
                    )
            );
        }
    }

    private void readShortcuts(
            ResultSet resultSet,
            List<DashboardModels.Shortcut> target
    ) throws SQLException {
        while (resultSet.next()) {
            target.add(
                    new DashboardModels.Shortcut(
                            nullableInteger(resultSet, "moduloId"),
                            resultSet.getString("codigoModulo"),
                            resultSet.getString("nombreModulo"),
                            resultSet.getString("ruta"),
                            resultSet.getString("icono"),
                            nullableInteger(resultSet, "orden")
                    )
            );
        }
    }

    private void readGraphDefinitions(
            ResultSet resultSet,
            Map<String, MutableGraph> target
    ) throws SQLException {
        while (resultSet.next()) {
            String code = resultSet.getString("codigo");

            target.put(
                    code,
                    new MutableGraph(
                            code,
                            resultSet.getString("titulo"),
                            resultSet.getString("subtitulo"),
                            resultSet.getString("tipoGrafico"),
                            resultSet.getString("unidad"),
                            nullableInteger(resultSet, "ancho"),
                            nullableInteger(resultSet, "orden")
                    )
            );
        }
    }

    private void readGraphPoints(
            ResultSet resultSet,
            Map<String, MutableGraph> graphs
    ) throws SQLException {
        while (resultSet.next()) {
            String graphCode = resultSet.getString("codigoGrafico");
            MutableGraph graph = graphs.get(graphCode);

            if (graph == null) {
                continue;
            }

            graph.addPoint(
                    resultSet.getString("serie"),
                    new DashboardModels.GraphPoint(
                            resultSet.getString("categoria"),
                            resultSet.getBigDecimal("valor"),
                            nullableInteger(resultSet, "orden")
                    )
            );
        }
    }

    private void drain(ResultSet resultSet) throws SQLException {
        while (resultSet.next()) {
            // El conjunto adicional se consume para liberar el CallableStatement.
        }
    }

    private Integer nullableInteger(
            ResultSet resultSet,
            String column
    ) throws SQLException {
        int value = resultSet.getInt(column);
        return resultSet.wasNull()
                ? null
                : value;
    }

    private Long nullableLong(
            ResultSet resultSet,
            String column
    ) throws SQLException {
        long value = resultSet.getLong(column);
        return resultSet.wasNull()
                ? null
                : value;
    }

    private String date(LocalDate value) {
        return value == null
                ? null
                : value.toString();
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private static final class MutableGraph {

        private final String code;
        private final String title;
        private final String subtitle;
        private final String type;
        private final String unit;
        private final Integer width;
        private final Integer order;
        private final Map<String, List<DashboardModels.GraphPoint>> series =
                new LinkedHashMap<>();

        private MutableGraph(
                String code,
                String title,
                String subtitle,
                String type,
                String unit,
                Integer width,
                Integer order
        ) {
            this.code = code;
            this.title = title;
            this.subtitle = subtitle;
            this.type = type;
            this.unit = unit;
            this.width = width;
            this.order = order;
        }

        private void addPoint(
                String seriesName,
                DashboardModels.GraphPoint point
        ) {
            String normalizedName = hasSeriesName(seriesName)
                    ? seriesName
                    : "Valor";

            series.computeIfAbsent(
                    normalizedName,
                    key -> new ArrayList<>()
            ).add(point);
        }

        private DashboardModels.Graph domain() {
            List<DashboardModels.GraphSeries> domainSeries = series
                    .entrySet()
                    .stream()
                    .map(entry -> new DashboardModels.GraphSeries(
                            entry.getKey(),
                            entry.getValue()
                                    .stream()
                                    .sorted(Comparator.comparing(
                                            DashboardModels.GraphPoint::orden,
                                            Comparator.nullsLast(
                                                    Integer::compareTo
                                            )
                                    ))
                                    .toList()
                    ))
                    .toList();

            return new DashboardModels.Graph(
                    code,
                    title,
                    subtitle,
                    type,
                    unit,
                    width,
                    order,
                    domainSeries
            );
        }

        private static boolean hasSeriesName(String value) {
            return value != null && !value.isBlank();
        }
    }
}
