package com.franco.desco.adapter.out.sqlserver.report;

import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.PaResultSets;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.report.port.out.TemporaryReportPort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Repository
public class TemporaryReportSqlServerAdapter implements TemporaryReportPort {
    private static final String CONFIRM = "reporte.PA_ReporteTemporal_ConfirmarDescarga";
    private static final String PURGE = "reporte.PA_ReporteTemporal_Purgar";

    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloads;

    public TemporaryReportSqlServerAdapter(SqlServerPaExecutor executor, PaPayloadFactory payloads) {
        this.executor = executor;
        this.payloads = payloads;
    }

    @Override
    public PersistenceResult<String> confirm(String type, long id, SessionIdentity identity, RequestMetadata metadata) {
        PaExecution result = executor.execute(CONFIRM, Map.of(
                "cAccion", type,
                "cJson", payloads.mutation(identity, metadata, Map.of("id", id))));
        return result.toPersistence(PaResultSets.string(result.outputs(), "datos"));
    }

    @Override
    public List<String> purgeExpired(int batchSize) {
        PaExecution result = executor.execute(PURGE, Map.of("nLote", batchSize));
        if (!result.exitoso()) {
            throw new IllegalStateException("Falló la limpieza de reportes temporales.");
        }
        List<String> keys = new ArrayList<>();
        for (List<Map<String, Object>> rows : result.resultSets()) {
            for (Map<String, Object> row : rows) {
                String key = PaResultSets.string(row, "clave");
                if (key != null) {
                    keys.add(key);
                }
            }
        }
        return keys;
    }
}
