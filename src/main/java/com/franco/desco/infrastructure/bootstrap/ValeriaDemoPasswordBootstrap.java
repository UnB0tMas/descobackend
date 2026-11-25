package com.franco.desco.infrastructure.bootstrap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

/** Restablece únicamente la cuenta demo de Valeria en bases DESCO de desarrollo. */
@Component
@Order(40)
@ConditionalOnProperty(prefix = "desco.demo.pos", name = "enabled", havingValue = "true", matchIfMissing = false)
public class ValeriaDemoPasswordBootstrap implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(ValeriaDemoPasswordBootstrap.class);
    private static final String LOGIN = "pos_sarasara_01";
    private static final String DOCUMENTO_DEMO = "DESCO-POS-DEMO-01";
    private static final String PASSWORD_DEV = "ValeriaDemo#2026!";

    private final JdbcTemplate jdbc;
    private final PasswordEncoder encoder;

    public ValeriaDemoPasswordBootstrap(JdbcTemplate jdbc, PasswordEncoder encoder) {
        this.jdbc = jdbc;
        this.encoder = encoder;
    }

    static boolean esBaseDevPermitida(String database) {
        if (database == null) {
            return false;
        }
        String nombre = database.trim().toLowerCase(Locale.ROOT);
        return "desco_db_dev".equals(nombre) || "desco_db_dev2".equals(nombre);
    }

    private record Credencial(
            long usuarioId, String passwordHash, boolean activo, String estadoCuenta,
            boolean requiereCambio, boolean segundoFactor, boolean omitirSegundoFactor,
            int intentosFallidos, boolean bloqueado
    ) {}

    private List<Credencial> consultarCuenta() {
        return jdbc.query("""
                SELECT U.usuario_id, U.password_hash, U.estado, U.estado_cuenta,
                       U.requiere_cambio_password, U.segundo_factor_habilitado,
                       U.omitir_segundo_factor_pruebas, U.intentos_fallidos, U.bloqueado_hasta
                FROM seg.Usuario U
                INNER JOIN org.Persona P ON P.persona_id = U.persona_id
                INNER JOIN org.Empleado E ON E.empleado_id = U.persona_id
                WHERE U.nombre_usuario = ? AND P.numero_documento = ?
                """, (rs, i) -> new Credencial(
                        rs.getLong("usuario_id"), rs.getString("password_hash"),
                        rs.getBoolean("estado"), rs.getString("estado_cuenta"),
                        rs.getBoolean("requiere_cambio_password"),
                        rs.getBoolean("segundo_factor_habilitado"),
                        rs.getBoolean("omitir_segundo_factor_pruebas"),
                        rs.getInt("intentos_fallidos"), rs.getTimestamp("bloqueado_hasta") != null
                ), LOGIN, DOCUMENTO_DEMO);
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        String base = jdbc.queryForObject("SELECT DB_NAME()", String.class);
        if (!esBaseDevPermitida(base)) {
            log.info("[VALERIA DEMO] Inicialización omitida: base no autorizada.");
            return;
        }

        List<Credencial> usuarios = consultarCuenta();
        if (usuarios.size() != 1) {
            throw new IllegalStateException("[VALERIA DEMO] No se encontró una cuenta demo única y válida.");
        }
        Credencial actual = usuarios.getFirst();
        boolean claveValida = actual.passwordHash() != null
                && encoder.matches(PASSWORD_DEV, actual.passwordHash());
        boolean requiereReparacion = !actual.activo()
                || !"ACTIVA".equals(actual.estadoCuenta())
                || actual.requiereCambio() || actual.segundoFactor()
                || !actual.omitirSegundoFactor() || actual.intentosFallidos() != 0
                || actual.bloqueado();

        if (!claveValida || requiereReparacion) {
            String nuevoHash = claveValida ? actual.passwordHash() : encoder.encode(PASSWORD_DEV);
            if (!encoder.matches(PASSWORD_DEV, nuevoHash)) {
                throw new IllegalStateException("[VALERIA DEMO] Error al generar la credencial de desarrollo.");
            }
            int actualizados = jdbc.update("""
                    UPDATE U
                       SET password_hash = ?, estado = 1, estado_cuenta = 'ACTIVA',
                           U.fecha_cambio_password = SYSUTCDATETIME(),
                           U.requiere_cambio_password = 0, segundo_factor_habilitado = 0,
                           U.omitir_segundo_factor_pruebas = 1, intentos_fallidos = 0,
                           U.fecha_ultimo_intento_fallido = NULL, bloqueado_hasta = NULL,
                           token_version = U.token_version + 1
                    FROM seg.Usuario U
                    INNER JOIN org.Persona P ON P.persona_id = U.persona_id
                    WHERE U.usuario_id = ? AND U.nombre_usuario = ? AND P.numero_documento = ?
                    """, nuevoHash, actual.usuarioId(), LOGIN, DOCUMENTO_DEMO);
            if (actualizados != 1) {
                throw new IllegalStateException("[VALERIA DEMO] No se pudo actualizar la cuenta de prueba.");
            }
        }

        List<Credencial> verificados = consultarCuenta();
        if (verificados.size() != 1 || !encoder.matches(PASSWORD_DEV, verificados.getFirst().passwordHash())
                || !verificados.getFirst().activo()
                || !"ACTIVA".equals(verificados.getFirst().estadoCuenta())
                || verificados.getFirst().bloqueado()) {
            throw new IllegalStateException("[VALERIA DEMO] La credencial no quedó verificada.");
        }
        log.info("[VALERIA DEMO] Cuenta verificada. base={} usuario={} actualizado={}",
                base, LOGIN, !claveValida || requiereReparacion);
    }
}
