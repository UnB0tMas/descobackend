package com.franco.desco.infrastructure.scheduling;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

@Component
public final class CampaignExpiryScheduler {
    private static final Logger log = LoggerFactory.getLogger(CampaignExpiryScheduler.class);
    private final JdbcTemplate jdbc;
    private final AtomicBoolean running = new AtomicBoolean(false);

    public CampaignExpiryScheduler(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Scheduled(initialDelayString = "${app.campaigns.expiration-initial-delay-ms:10000}",
               fixedDelayString = "${app.campaigns.expiration-ms:60000}")
    public void expire() {
        if (!running.compareAndSet(false, true)) return;
        try {
            Integer affected = jdbc.queryForObject("EXEC comercial.PA_CampaniaVenta_Upd_Vencer", Integer.class);
            if (affected != null && affected > 0) {
                log.info("[CAMPANIAS] Campañas vencidas={}", affected);
            }
        } catch (RuntimeException ex) {
            log.error("[CAMPANIAS] No se pudo actualizar el vencimiento automático", ex);
        } finally {
            running.set(false);
        }
    }
}
