package com.franco.desco.application.report.service;

import com.franco.desco.application.report.port.out.TemporaryReportPort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.infrastructure.storage.LocalBinaryStorage;
import com.franco.desco.infrastructure.storage.LocalFileDeleteQueue;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;

@Service
public class TemporaryReportService {
    private static final Logger LOG = LoggerFactory.getLogger(TemporaryReportService.class);
    private final TemporaryReportPort reports;
    private final LocalBinaryStorage storage;
    private final LocalFileDeleteQueue deleteQueue;

    public TemporaryReportService(TemporaryReportPort reports, LocalBinaryStorage storage,
                                  LocalFileDeleteQueue deleteQueue) {
        this.reports = reports;
        this.storage = storage;
        this.deleteQueue = deleteQueue;
    }

    public PersistenceResult<Void> confirm(String type, long id, SessionIdentity identity, RequestMetadata metadata) {
        if (id <= 0 || !("EXCEL".equals(type) || "ESPECIAL".equals(type))) {
            return PersistenceResult.error("REPORTE_INVALIDO", "El archivo no está disponible.", 400);
        }
        PersistenceResult<String> result = reports.confirm(type, id, identity, metadata);
        if (!result.exitoso()) {
            return PersistenceResult.error(result.codigo(), result.mensaje(), result.httpSugerido());
        }
        if (!expectedKey(type, id, result.datos())) {
            LOG.error("Clave inesperada al confirmar reporte tipo={} id={}", type, id);
            return PersistenceResult.error("REPORTE_ARCHIVO_INVALIDO", "No se pudo completar la solicitud.", 500);
        }
        removeFile(result.datos());
        return PersistenceResult.ok("REPORTE_DESCARGADO", "Descarga confirmada.", 200, null);
    }

    public void purgeExpired() {
        for (String key : reports.purgeExpired(200)) {
            if (validKey(key)) {
                removeFile(key);
            } else {
                LOG.error("Clave inválida recibida en la limpieza de reportes temporales.");
            }
        }
    }

    private boolean expectedKey(String type, long id, String key) {
        if ("EXCEL".equals(type)) {
            return ("exports/" + id + ".xlsx").equals(key);
        }
        return key != null && (key.equals("reports-special/" + id + ".xlsx")
                || key.equals("reports-special/" + id + ".pdf")
                || key.equals("reports-special/" + id + ".docx"));
    }

    private boolean validKey(String key) {
        return key != null && (key.matches("exports/[0-9]+\\.xlsx")
                || key.matches("reports-special/[0-9]+\\.(xlsx|pdf|docx)"));
    }

    private void removeFile(String key) {
        // La cola es persistente: si el disco falla, se reintenta sin recuperar el registro.
        deleteQueue.enqueue(key);
        try {
            storage.delete(key);
        } catch (IOException | IllegalArgumentException exception) {
            LOG.warn("Eliminación de archivo temporal pendiente: {}", key, exception);
        }
    }
}
