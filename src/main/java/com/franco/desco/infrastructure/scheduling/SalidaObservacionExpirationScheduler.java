package com.franco.desco.infrastructure.scheduling;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public final class SalidaObservacionExpirationScheduler {
    private static final Logger LOG = LoggerFactory.getLogger(SalidaObservacionExpirationScheduler.class);
    private static final String PROCEDURE = "campo.PA_SalidaDocumental_Upd_VencerObservaciones";
    private final JdbcTemplate jdbc;

    public SalidaObservacionExpirationScheduler(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Scheduled(initialDelayString = "${app.salidas.observacion.initial-delay-ms:30000}",
               fixedDelayString = "${app.salidas.observacion.delay-ms:60000}")
    public void expire() {
        long start = System.nanoTime();
        try {
            jdbc.execute("EXEC " + PROCEDURE);
        } catch (RuntimeException exception) {
            LOG.error(">> PA ERROR SQL/TECNICO | {} | VENCER | duraciónMs={}", PROCEDURE,
                    (System.nanoTime() - start) / 1_000_000, exception);
        }
    }
}
