package com.franco.desco.adapter.out.sqlserver.report;

import com.franco.desco.adapter.out.sqlserver.shared.PaAdapterSupport;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.PaResultSets;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlValues;
import com.franco.desco.application.report.ReportCommands;
import com.franco.desco.application.report.port.out.ReportPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.report.ReportModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Component
public class ReportSqlServerAdapter
        implements ReportPersistencePort {

    private static final String SECTION_1 = "section1";
    private static final String SECTION_2 = "section2";
    private static final String SECTION_3 = "section3";

    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall catalog;
    private final SimpleJdbcCall data;
    private final SimpleJdbcCall export;

    public ReportSqlServerAdapter(
            SqlServerPaFactory factory,
            SqlServerPaExecutor executor,
            PaPayloadFactory payloadFactory
    ) {
        this.executor = executor;
        this.payloadFactory = payloadFactory;

        this.catalog = factory.callWithResultSets(
                "reporte",
                "PA_Reporte_Sel_Catalogo",
                "items"
        );

        /*
         * PA_Reporte_Sel_Datos es polimórfico:
         * TECNICO       -> 3 ResultSets
         * PLANIFICACION -> 2 ResultSets
         * COMERCIAL     -> 2 ResultSets
         * FINANCIERO    -> 1 ResultSet
         *
         * Se registran tres salidas para conservar el contrato completo.
         */
        this.data = factory.callWithResultSets(
                "reporte",
                "PA_Reporte_Sel_Datos",
                SECTION_1,
                SECTION_2,
                SECTION_3
        );

        this.export = factory.callWithResultSets(
                "reporte",
                "PA_Reporte_Sel_Exportacion",
                SECTION_1,
                SECTION_2,
                SECTION_3
        );
    }

    @Override
    public PersistenceResult<List<ReportModels.CatalogItem>> catalog(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PaResultSets resultSets = executor.executeJsonMultiResult(
                catalog,
                payloadFactory.forQuery(
                        identity,
                        metadata,
                        Map.of()
                )
        );

        if (!PaAdapterSupport.success(resultSets.raw())) {
            return PersistenceResult.error(
                    PaAdapterSupport.message(
                            resultSets.raw(),
                            "No se pudo obtener el catálogo de reportes."
                    )
            );
        }

        List<ReportModels.CatalogItem> items =
                resultSets.rows("items")
                        .stream()
                        .map(row ->
                                new ReportModels.CatalogItem(
                                        SqlValues.string(row, "codigo"),
                                        SqlValues.string(row, "nombre"),
                                        SqlValues.string(row, "grupo"),
                                        SqlValues.string(row, "descripcion")
                                )
                        )
                        .toList();

        return PersistenceResult.ok(
                PaAdapterSupport.message(
                        resultSets.raw(),
                        "Catálogo de reportes obtenido correctamente."
                ),
                items
        );
    }

    @Override
    public PersistenceResult<ReportModels.Data> data(
            ReportCommands.GetData command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return execute(
                data,
                command.filtros(),
                identity,
                metadata,
                "No se pudo consultar el reporte."
        );
    }

    @Override
    public PersistenceResult<ReportModels.Data> export(
            ReportCommands.ExportData command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return execute(
                export,
                command.filtros(),
                identity,
                metadata,
                "No se pudo preparar la exportación."
        );
    }

    private PersistenceResult<ReportModels.Data> execute(
            SimpleJdbcCall call,
            ReportCommands.Filters filters,
            SessionIdentity identity,
            RequestMetadata metadata,
            String fallbackMessage
    ) {
        PaResultSets resultSets = executor.executeJsonMultiResult(
                call,
                payloadFactory.forQuery(
                        identity,
                        metadata,
                        Map.of(
                                "filtros",
                                map(
                                        "reporte", filters.reporte(),
                                        "fechaDesde", filters.fechaDesde(),
                                        "fechaHasta", filters.fechaHasta(),
                                        "campaniaVentaId", filters.campaniaVentaId(),
                                        "operativoVentaId", filters.operativoVentaId(),
                                        "zonaProductivaId", filters.zonaProductivaId()
                                )
                        )
                )
        );

        if (!PaAdapterSupport.success(resultSets.raw())) {
            return PersistenceResult.error(
                    PaAdapterSupport.message(
                            resultSets.raw(),
                            fallbackMessage
                    )
            );
        }

        String reportCode = normalize(filters.reporte());

        ReportModels.Data report = new ReportModels.Data(
                reportCode,
                sections(reportCode, resultSets)
        );

        return PersistenceResult.ok(
                PaAdapterSupport.message(
                        resultSets.raw(),
                        "Reporte obtenido correctamente."
                ),
                report
        );
    }

    private List<ReportModels.Section> sections(
            String reportCode,
            PaResultSets resultSets
    ) {
        return switch (reportCode) {
            case "TECNICO" -> List.of(
                    section("RESUMEN", resultSets.rows(SECTION_1)),
                    section("CASOS_FITOSANITARIOS", resultSets.rows(SECTION_2)),
                    section("EVALUACIONES", resultSets.rows(SECTION_3))
            );

            case "PLANIFICACION" -> List.of(
                    section("SALIDAS", resultSets.rows(SECTION_1)),
                    section("RECURSOS", resultSets.rows(SECTION_2))
            );

            case "COMERCIAL" -> List.of(
                    section("OPERATIVOS", resultSets.rows(SECTION_1)),
                    section("JABAS", resultSets.rows(SECTION_2))
            );

            case "FINANCIERO" -> List.of(
                    section("CAMPANIAS", resultSets.rows(SECTION_1))
            );

            default -> genericSections(resultSets);
        };
    }

    private List<ReportModels.Section> genericSections(
            PaResultSets resultSets
    ) {
        List<ReportModels.Section> sections = new ArrayList<>();
        appendIfPresent(sections, "SECCION_1", resultSets.rows(SECTION_1));
        appendIfPresent(sections, "SECCION_2", resultSets.rows(SECTION_2));
        appendIfPresent(sections, "SECCION_3", resultSets.rows(SECTION_3));
        return List.copyOf(sections);
    }

    private void appendIfPresent(
            List<ReportModels.Section> target,
            String code,
            List<Map<String, Object>> rows
    ) {
        if (rows != null && !rows.isEmpty()) {
            target.add(section(code, rows));
        }
    }

    private ReportModels.Section section(
            String code,
            List<Map<String, Object>> rows
    ) {
        return new ReportModels.Section(code, rows);
    }

    private String normalize(String reportCode) {
        return reportCode == null
                ? ""
                : reportCode.trim().toUpperCase(Locale.ROOT);
    }

    private static Map<String, Object> map(
            Object... values
    ) {
        Map<String, Object> result = new LinkedHashMap<>();

        for (int index = 0; index < values.length; index += 2) {
            Object value = values[index + 1];

            if (value != null) {
                result.put(
                        (String) values[index],
                        value
                );
            }
        }

        return result;
    }
}
