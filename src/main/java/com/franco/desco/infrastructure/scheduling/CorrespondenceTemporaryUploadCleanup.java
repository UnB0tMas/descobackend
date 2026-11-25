package com.franco.desco.infrastructure.scheduling;

import com.franco.desco.infrastructure.storage.LocalFileDeleteQueue;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

/** Retira solo cargas documentarias sin envío y sin borrador vigente. */
@Component
public final class CorrespondenceTemporaryUploadCleanup {
    private static final Logger log = LoggerFactory.getLogger(CorrespondenceTemporaryUploadCleanup.class);
    private final JdbcTemplate jdbc;
    private final LocalFileDeleteQueue deletes;
    private final AtomicBoolean running = new AtomicBoolean(false);

    public CorrespondenceTemporaryUploadCleanup(JdbcTemplate jdbc, LocalFileDeleteQueue deletes) {
        this.jdbc=jdbc;
        this.deletes=deletes;
    }

    @Scheduled(initialDelayString="${app.correspondence.cleanup-initial-delay-ms:300000}",
               fixedDelayString="${app.correspondence.cleanup-delay-ms:86400000}")
    public void cleanup() {
        if (!running.compareAndSet(false,true)) return;
        try {
            List<String> keys=jdbc.query("EXEC doc.PA_Correspondencia_LimpiarTemporales",
                    (rs,row)->rs.getString(1));
            for (String key:keys) deletes.enqueue(key);
        } catch (DataAccessException exception) {
            log.error("[CORRESPONDENCIA] No fue posible retirar las cargas temporales",exception);
        } finally {
            running.set(false);
        }
    }
}
