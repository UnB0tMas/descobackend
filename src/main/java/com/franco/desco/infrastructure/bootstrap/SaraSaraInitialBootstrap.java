package com.franco.desco.infrastructure.bootstrap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;

/** Inicialización única de las cuentas operativas de Sara Sara en DESCO_DB (DEV). */
@Component
@Order(35)
@ConditionalOnProperty(prefix = "desco.bootstrap.sara", name = "enabled", havingValue = "true", matchIfMissing = true)
public class SaraSaraInitialBootstrap implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(SaraSaraInitialBootstrap.class);
    private static final String KEY = "SARA_SARA_OPERACION_2026_V1";
    private final JdbcTemplate jdbc;
    public SaraSaraInitialBootstrap(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void run(ApplicationArguments args) throws Exception {
        String database = jdbc.queryForObject("SELECT DB_NAME()", String.class);
        if (!"DESCO_DB".equalsIgnoreCase(database)) {
            log.warn("[BOOTSTRAP] Sara Sara omitido: base actual={}, se requiere DESCO_DB.", database);
            return;
        }
        // Spring puede tener autoCommit desactivado sin una transacción física
        // en SQL Server. El bloqueo Transaction requiere @@TRANCOUNT > 0.
        // Se mantiene el commit/rollback bajo control de Spring, igual que
        // en SqlIdempotencyCoordinator.
        Integer transactionCount = jdbc.queryForObject("SELECT @@TRANCOUNT", Integer.class);
        if (transactionCount == null) {
            throw new IllegalStateException("No se pudo comprobar la transacción SQL de Sara Sara.");
        }
        if (transactionCount == 0) {
            jdbc.execute("BEGIN TRANSACTION");
        }
        Integer lock = jdbc.queryForObject("""
            SET NOCOUNT ON;
            DECLARE @resultado INT;
            EXEC @resultado = sys.sp_getapplock @Resource = N'DESCO:BOOTSTRAP:SARA:2026',
                @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 15000,
                @DbPrincipal = 'public';
            SELECT @resultado;
            """, Integer.class);
        if (lock == null || lock < 0) {
            throw new IllegalStateException("No se pudo reservar la inicialización de Sara Sara. Código SQL Server: " + lock);
        }
        Integer initialized = jdbc.queryForObject("""
            SELECT COUNT(1) FROM config.CargaInicial WITH (UPDLOCK, HOLDLOCK)
            WHERE codigo = ?
            """, Integer.class, KEY);
        if (initialized != null && initialized > 0) {
            log.info("[BOOTSTRAP] Sara Sara: carga inicial ya registrada en DESCO_DB.");
            return;
        }
        // La credencial inicial procede del hash Argon2 vigente de admin.
        // El SQL la resuelve dentro de la misma transacción y no expone la clave.
        String sql = new ClassPathResource("db/bootstrap/sara-sara-inicial.sql")
                .getContentAsString(StandardCharsets.UTF_8);
        jdbc.execute(sql);
        jdbc.update("INSERT config.CargaInicial(codigo) VALUES (?)", KEY);
        log.info("[BOOTSTRAP] Sara Sara: cuentas técnico, APAPPSS y comprador configuradas. Administrador conservado.");
    }
}
