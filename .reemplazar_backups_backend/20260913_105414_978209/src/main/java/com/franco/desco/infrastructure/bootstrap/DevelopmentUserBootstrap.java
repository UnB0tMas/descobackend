package com.franco.desco.infrastructure.bootstrap;

import com.franco.desco.application.auth.port.out.PasswordHashPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;

@Component
@Profile("!prod & !production")
public class DevelopmentUserBootstrap implements ApplicationRunner {

    private static final Logger log =
            LoggerFactory.getLogger(DevelopmentUserBootstrap.class);

    private static final String DEVELOPMENT_COMPANY_RUC =
            "20999999999";

    /*
     * Política de seguridad mínima requerida por los PA de autenticación.
     *
     * Estos valores son una baseline de DESARROLLO. Cumplen los CHECK
     * existentes de seg.PoliticaSeguridad y permiten probar validación de
     * correo, recuperación de contraseña y segundo factor.
     */
    private static final String GENERAL_SECURITY_POLICY_CODE =
            "GENERAL";

    private static final List<LoginSeed> LOGIN_SEEDS = List.of(
            new LoginSeed(
                    "admin",
                    "Desco.Admin.2026!",
                    "ADMINISTRADOR",
                    "tresdynx@gmail.com",
                    "DEV-ADMIN-2026",
                    "Administrador",
                    "DESCO",
                    "DEV-ADMIN"
            ),
            new LoginSeed(
                    "tecnico",
                    "Desco.Tecnico.2026!",
                    "TECNICO_CAMPO",
                    "francolopezjesus23@gmail.com",
                    "DEV-TECNICO-2026",
                    "Tecnico",
                    "Campo",
                    "DEV-TECNICO"
            ),
            new LoginSeed(
                    "coordinador",
                    "Desco.Coord.2026!",
                    "COORDINADOR_COMERCIAL",
                    "fitcenterica@gmail.com",
                    "DEV-COORD-2026",
                    "Coordinador",
                    "Comercial",
                    "DEV-COORD"
            )
    );

    private final JdbcTemplate jdbcTemplate;
    private final PasswordHashPort passwordHash;
    private final TransactionTemplate transactionTemplate;

    @Value("${app.bootstrap-users.enabled:true}")
    private boolean enabled;

    public DevelopmentUserBootstrap(
            JdbcTemplate jdbcTemplate,
            PasswordHashPort passwordHash,
            PlatformTransactionManager transactionManager
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.passwordHash = passwordHash;
        this.transactionTemplate =
                new TransactionTemplate(transactionManager);
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!enabled) {
            log.info(
                    "Bootstrap de usuarios de desarrollo deshabilitado."
            );
            return;
        }

        transactionTemplate.executeWithoutResult(status -> {
            ensureGeneralSecurityPolicy();

            long companyId = resolveCompanyId();

            LoginSeed administratorSeed = LOGIN_SEEDS.getFirst();
            long administratorRoleId =
                    requireRole(administratorSeed.roleCode());

            long administratorEmployeeId =
                    resolveEmployee(
                            administratorSeed,
                            companyId
                    );

            long administratorUserId =
                    upsertUser(
                            administratorEmployeeId,
                            administratorSeed,
                            null
                    );

            ensureRole(
                    administratorUserId,
                    administratorRoleId,
                    administratorUserId
            );

            grantAllActivePermissions(
                    administratorRoleId,
                    administratorUserId
            );

            for (int index = 1; index < LOGIN_SEEDS.size(); index++) {
                LoginSeed seed = LOGIN_SEEDS.get(index);

                long roleId = requireRole(seed.roleCode());
                long employeeId =
                        resolveEmployee(
                                seed,
                                companyId
                        );

                long userId =
                        upsertUser(
                                employeeId,
                                seed,
                                administratorUserId
                        );

                ensureRole(
                        userId,
                        roleId,
                        administratorUserId
                );
            }
        });

        log.warn(
                "Bootstrap de usuarios de desarrollo aplicado. "
                        + "Cuentas de prueba disponibles: admin, tecnico "
                        + "y coordinador. No habilitar "
                        + "app.bootstrap-users.enabled en producción."
        );
    }

    /**
     * Garantiza que exista una política GENERAL vigente para el entorno
     * de desarrollo.
     *
     * Los PA de seguridad consultan esta fila antes de emitir un OTP. Si no
     * existe, devuelven debeEnviar=false y el backend no invoca SMTP.
     *
     * El método es idempotente: si ya existe una política GENERAL activa,
     * abierta y vigente, no inserta otra.
     */
    private void ensureGeneralSecurityPolicy() {
        Integer currentPolicies =
                jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*)
                        FROM seg.PoliticaSeguridad WITH (UPDLOCK, HOLDLOCK)
                        WHERE codigo = ?
                          AND estado = 1
                          AND fecha_hasta IS NULL
                          AND fecha_desde <= SYSUTCDATETIME()
                        """,
                        Integer.class,
                        GENERAL_SECURITY_POLICY_CODE
                );

        if (currentPolicies != null && currentPolicies > 0) {
            return;
        }

        jdbcTemplate.update(
                """
                INSERT INTO seg.PoliticaSeguridad
                (
                    codigo,
                    max_intentos_login,
                    minutos_bloqueo_login,
                    max_intentos_codigo,
                    segundos_minimos_reenvio,
                    minutos_expiracion_validacion,
                    minutos_expiracion_recuperacion,
                    minutos_expiracion_segundo_factor,
                    minutos_access_token,
                    dias_refresh_token,
                    dias_dispositivo_reconocido,
                    fecha_desde,
                    fecha_hasta,
                    estado
                )
                VALUES
                (
                    ?,
                    5,
                    15,
                    5,
                    60,
                    15,
                    15,
                    5,
                    15,
                    7,
                    30,
                    SYSUTCDATETIME(),
                    NULL,
                    1
                )
                """,
                GENERAL_SECURITY_POLICY_CODE
        );

        log.warn(
                "Se creó la política de seguridad GENERAL para desarrollo. "
                        + "No usar esta semilla como configuración definitiva "
                        + "de producción sin revisión funcional."
        );
    }

    private long resolveCompanyId() {
        Optional<Long> existingActive =
                jdbcTemplate.query(
                        """
                        SELECT TOP (1) empresa_id
                        FROM org.Empresa
                        WHERE estado = 1
                        ORDER BY empresa_id
                        """,
                        (rs, rowNum) ->
                                rs.getLong("empresa_id")
                ).stream().findFirst();

        if (existingActive.isPresent()) {
            return existingActive.get();
        }

        Optional<Long> developmentCompany =
                jdbcTemplate.query(
                        """
                        SELECT empresa_id
                        FROM org.Empresa
                        WHERE ruc = ?
                        """,
                        (rs, rowNum) ->
                                rs.getLong("empresa_id"),
                        DEVELOPMENT_COMPANY_RUC
                ).stream().findFirst();

        if (developmentCompany.isPresent()) {
            long companyId = developmentCompany.get();

            jdbcTemplate.update(
                    """
                    UPDATE org.Empresa
                    SET razon_social =
                            N'DESCO - Entorno de desarrollo',
                        nombre_comercial =
                            N'DESCO Desarrollo',
                        correo = ?,
                        estado = 1
                    WHERE empresa_id = ?
                    """,
                    LOGIN_SEEDS.getFirst().email(),
                    companyId
            );

            return companyId;
        }

        jdbcTemplate.update(
                """
                INSERT INTO org.Empresa
                (
                    ruc,
                    razon_social,
                    nombre_comercial,
                    telefono,
                    correo,
                    ubicacion_id,
                    fecha_creacion,
                    estado
                )
                VALUES
                (
                    ?,
                    N'DESCO - Entorno de desarrollo',
                    N'DESCO Desarrollo',
                    NULL,
                    ?,
                    NULL,
                    SYSUTCDATETIME(),
                    1
                )
                """,
                DEVELOPMENT_COMPANY_RUC,
                LOGIN_SEEDS.getFirst().email()
        );

        return Objects.requireNonNull(
                jdbcTemplate.queryForObject(
                        """
                        SELECT empresa_id
                        FROM org.Empresa
                        WHERE ruc = ?
                        """,
                        Long.class,
                        DEVELOPMENT_COMPANY_RUC
                )
        );
    }

    private long resolveEmployee(
            LoginSeed seed,
            long companyId
    ) {
        Optional<Long> employeeByUsername =
                jdbcTemplate.query(
                        """
                        SELECT U.persona_id
                        FROM seg.Usuario U
                        WHERE LOWER(U.nombre_usuario) =
                              LOWER(?)
                        """,
                        (rs, rowNum) ->
                                rs.getLong("persona_id"),
                        seed.username()
                ).stream().findFirst();

        if (employeeByUsername.isPresent()) {
            long employeeId = employeeByUsername.get();

            reactivatePersonEmail(
                    employeeId,
                    seed.email()
            );

            ensureEmployeeExists(
                    employeeId,
                    companyId,
                    seed.employeeCode()
            );

            return employeeId;
        }

        Optional<Long> developmentPerson =
                jdbcTemplate.query(
                        """
                        SELECT persona_id
                        FROM org.Persona
                        WHERE tipo_documento = 'OTRO'
                          AND numero_documento = ?
                        """,
                        (rs, rowNum) ->
                                rs.getLong("persona_id"),
                        seed.documentNumber()
                ).stream().findFirst();

        long personId;

        if (developmentPerson.isPresent()) {
            personId = developmentPerson.get();

            jdbcTemplate.update(
                    """
                    UPDATE org.Persona
                    SET nombres = ?,
                        apellido_paterno = ?,
                        apellido_materno = NULL,
                        correo = ?,
                        estado = 1
                    WHERE persona_id = ?
                    """,
                    seed.givenNames(),
                    seed.paternalSurname(),
                    seed.email(),
                    personId
            );
        } else {
            jdbcTemplate.update(
                    """
                    INSERT INTO org.Persona
                    (
                        tipo_documento,
                        numero_documento,
                        nombres,
                        apellido_paterno,
                        apellido_materno,
                        telefono,
                        correo,
                        fecha_nacimiento,
                        estado,
                        fecha_creacion
                    )
                    VALUES
                    (
                        'OTRO',
                        ?,
                        ?,
                        ?,
                        NULL,
                        NULL,
                        ?,
                        NULL,
                        1,
                        SYSUTCDATETIME()
                    )
                    """,
                    seed.documentNumber(),
                    seed.givenNames(),
                    seed.paternalSurname(),
                    seed.email()
            );

            personId = Objects.requireNonNull(
                    jdbcTemplate.queryForObject(
                            """
                            SELECT persona_id
                            FROM org.Persona
                            WHERE tipo_documento = 'OTRO'
                              AND numero_documento = ?
                            """,
                            Long.class,
                            seed.documentNumber()
                    )
            );
        }

        ensureEmployeeExists(
                personId,
                companyId,
                seed.employeeCode()
        );

        return personId;
    }

    private void reactivatePersonEmail(
            long personId,
            String email
    ) {
        jdbcTemplate.update(
                """
                UPDATE org.Persona
                SET correo = ?,
                    estado = 1
                WHERE persona_id = ?
                """,
                email,
                personId
        );
    }

    private void ensureEmployeeExists(
            long employeeId,
            long companyId,
            String employeeCode
    ) {
        Integer exists =
                jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*)
                        FROM org.Empleado
                        WHERE empleado_id = ?
                        """,
                        Integer.class,
                        employeeId
                );

        if (exists != null && exists > 0) {
            jdbcTemplate.update(
                    """
                    UPDATE org.Empleado
                    SET estado = 1,
                        fecha_cese = NULL
                    WHERE empleado_id = ?
                    """,
                    employeeId
            );
            return;
        }

        String availableEmployeeCode =
                nextAvailableEmployeeCode(
                        companyId,
                        employeeCode
                );

        jdbcTemplate.update(
                """
                INSERT INTO org.Empleado
                (
                    empleado_id,
                    empresa_id,
                    codigo_empleado,
                    fecha_ingreso,
                    fecha_cese,
                    estado
                )
                VALUES
                (
                    ?,
                    ?,
                    ?,
                    CONVERT(date, SYSUTCDATETIME()),
                    NULL,
                    1
                )
                """,
                employeeId,
                companyId,
                availableEmployeeCode
        );
    }

    private String nextAvailableEmployeeCode(
            long companyId,
            String preferredCode
    ) {
        String candidate = preferredCode;
        int suffix = 1;

        while (employeeCodeExists(
                companyId,
                candidate
        )) {
            candidate =
                    preferredCode
                            + "-"
                            + suffix++;
        }

        return candidate;
    }

    private boolean employeeCodeExists(
            long companyId,
            String code
    ) {
        Integer count =
                jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*)
                        FROM org.Empleado
                        WHERE empresa_id = ?
                          AND codigo_empleado = ?
                        """,
                        Integer.class,
                        companyId,
                        code
                );

        return count != null && count > 0;
    }

    private long requireRole(String code) {
        List<Long> ids =
                jdbcTemplate.query(
                        """
                        SELECT rol_id
                        FROM seg.Rol
                        WHERE codigo = ?
                          AND estado = 1
                        """,
                        (rs, rowNum) ->
                                rs.getLong("rol_id"),
                        code
                );

        if (ids.isEmpty()) {
            throw new IllegalStateException(
                    "No existe el rol activo requerido: "
                            + code
            );
        }

        return ids.getFirst();
    }

    private long upsertUser(
            long employeeId,
            LoginSeed seed,
            Long actorUserId
    ) {
        assertUsernameAvailable(
                employeeId,
                seed.username()
        );

        Optional<UserRow> existing =
                findUserByEmployee(employeeId);

        long userId;

        if (existing.isEmpty()) {
            String encodedPassword =
                    passwordHash.encode(seed.password());

            jdbcTemplate.update(
                    """
                    INSERT INTO seg.Usuario
                    (
                        persona_id,
                        nombre_usuario,
                        password_hash,
                        estado,
                        fecha_creacion,
                        intentos_fallidos,
                        fecha_ultimo_intento_fallido,
                        bloqueado_hasta,
                        ultimo_acceso_correcto,
                        fecha_cambio_password,
                        requiere_cambio_password,
                        segundo_factor_habilitado,
                        token_version,
                        estado_cuenta
                    )
                    VALUES
                    (
                        ?,
                        ?,
                        ?,
                        1,
                        SYSUTCDATETIME(),
                        0,
                        NULL,
                        NULL,
                        NULL,
                        SYSUTCDATETIME(),
                        0,
                        0,
                        1,
                        'ACTIVA'
                    )
                    """,
                    employeeId,
                    seed.username(),
                    encodedPassword
            );

            userId =
                    Objects.requireNonNull(
                            jdbcTemplate.queryForObject(
                                    """
                                    SELECT usuario_id
                                    FROM seg.Usuario
                                    WHERE persona_id = ?
                                    """,
                                    Long.class,
                                    employeeId
                            )
                    );

            insertPasswordHistory(
                    userId,
                    encodedPassword,
                    actorUserId == null
                            ? userId
                            : actorUserId
            );
        } else {
            UserRow current = existing.get();
            userId = current.userId();

            boolean samePassword =
                    current.passwordHash() != null
                            && !current.passwordHash().isBlank()
                            && passwordHash.matches(
                                    seed.password(),
                                    current.passwordHash()
                            );

            if (samePassword) {
                reactivateUser(
                        userId,
                        seed.username()
                );
            } else {
                String encodedPassword =
                        passwordHash.encode(seed.password());

                closeCurrentPasswordHistory(
                        userId
                );

                jdbcTemplate.update(
                        """
                        UPDATE seg.Usuario
                        SET nombre_usuario = ?,
                            password_hash = ?,
                            estado = 1,
                            estado_cuenta = 'ACTIVA',
                            intentos_fallidos = 0,
                            fecha_ultimo_intento_fallido = NULL,
                            bloqueado_hasta = NULL,
                            fecha_cambio_password =
                                SYSUTCDATETIME(),
                            requiere_cambio_password = 0,
                            token_version =
                                CASE
                                    WHEN token_version IS NULL
                                         OR token_version < 1
                                    THEN 1
                                    ELSE token_version + 1
                                END
                        WHERE usuario_id = ?
                        """,
                        seed.username(),
                        encodedPassword,
                        userId
                );

                insertPasswordHistory(
                        userId,
                        encodedPassword,
                        actorUserId == null
                                ? userId
                                : actorUserId
                );
            }
        }

        ensureSecurityEmail(
                userId,
                seed.email(),
                actorUserId == null
                        ? userId
                        : actorUserId
        );

        return userId;
    }

    private void reactivateUser(
            long userId,
            String username
    ) {
        jdbcTemplate.update(
                """
                UPDATE seg.Usuario
                SET nombre_usuario = ?,
                    estado = 1,
                    estado_cuenta = 'ACTIVA',
                    intentos_fallidos = 0,
                    fecha_ultimo_intento_fallido = NULL,
                    bloqueado_hasta = NULL,
                    requiere_cambio_password = 0,
                    token_version =
                        CASE
                            WHEN token_version IS NULL
                                 OR token_version < 1
                            THEN 1
                            ELSE token_version
                        END
                WHERE usuario_id = ?
                """,
                username,
                userId
        );
    }

    private Optional<UserRow> findUserByEmployee(
            long employeeId
    ) {
        return jdbcTemplate.query(
                """
                SELECT usuario_id,
                       password_hash
                FROM seg.Usuario
                WHERE persona_id = ?
                """,
                (rs, rowNum) ->
                        new UserRow(
                                rs.getLong("usuario_id"),
                                rs.getString("password_hash")
                        ),
                employeeId
        ).stream().findFirst();
    }

    private void assertUsernameAvailable(
            long employeeId,
            String username
    ) {
        Integer conflicts =
                jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*)
                        FROM seg.Usuario
                        WHERE LOWER(nombre_usuario) =
                              LOWER(?)
                          AND persona_id <> ?
                        """,
                        Integer.class,
                        username,
                        employeeId
                );

        if (conflicts != null && conflicts > 0) {
            throw new IllegalStateException(
                    "El nombre de usuario de desarrollo "
                            + "ya pertenece a otra cuenta: "
                            + username
            );
        }
    }

    private void ensureSecurityEmail(
            long userId,
            String email,
            long actorUserId
    ) {
        String normalized =
                email.trim()
                        .toLowerCase(Locale.ROOT);

        Integer alreadyCurrent =
                jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*)
                        FROM seg.UsuarioCorreoSeguridad
                        WHERE usuario_id = ?
                          AND correo_normalizado = ?
                          AND estado = 1
                          AND es_principal = 1
                          AND es_verificado = 1
                          AND fecha_hasta IS NULL
                        """,
                        Integer.class,
                        userId,
                        normalized
                );

        if (alreadyCurrent != null
                && alreadyCurrent > 0) {
            jdbcTemplate.update(
                    """
                    UPDATE seg.UsuarioCorreoSeguridad
                    SET correo = ?,
                        fecha_verificacion =
                            COALESCE(
                                fecha_verificacion,
                                SYSUTCDATETIME()
                            )
                    WHERE usuario_id = ?
                      AND correo_normalizado = ?
                      AND estado = 1
                      AND es_principal = 1
                    """,
                    normalized,
                    userId,
                    normalized
            );
            return;
        }

        jdbcTemplate.update(
                """
                UPDATE seg.UsuarioCorreoSeguridad
                SET es_principal = 0,
                    fecha_hasta =
                        COALESCE(
                            fecha_hasta,
                            SYSUTCDATETIME()
                        ),
                    motivo_cambio =
                        COALESCE(
                            motivo_cambio,
                            N'Reemplazado por bootstrap de desarrollo.'
                        ),
                    estado = 0
                WHERE usuario_id = ?
                  AND estado = 1
                """,
                userId
        );

        jdbcTemplate.update(
                """
                INSERT INTO seg.UsuarioCorreoSeguridad
                (
                    usuario_id,
                    correo,
                    correo_normalizado,
                    es_principal,
                    es_verificado,
                    fecha_verificacion,
                    fecha_desde,
                    fecha_hasta,
                    creado_por_usuario_id,
                    motivo_cambio,
                    estado
                )
                VALUES
                (
                    ?,
                    ?,
                    ?,
                    1,
                    1,
                    SYSUTCDATETIME(),
                    SYSUTCDATETIME(),
                    NULL,
                    ?,
                    N'Correo de prueba verificado por bootstrap de desarrollo.',
                    1
                )
                """,
                userId,
                normalized,
                normalized,
                actorUserId
        );
    }

    private void closeCurrentPasswordHistory(
            long userId
    ) {
        jdbcTemplate.update(
                """
                UPDATE seg.HistorialPassword
                SET fecha_hasta =
                        COALESCE(
                            fecha_hasta,
                            SYSUTCDATETIME()
                        ),
                    estado = 0
                WHERE usuario_id = ?
                  AND estado = 1
                  AND fecha_hasta IS NULL
                """,
                userId
        );
    }

    private void insertPasswordHistory(
            long userId,
            String encodedPassword,
            long actorUserId
    ) {
        jdbcTemplate.update(
                """
                INSERT INTO seg.HistorialPassword
                (
                    usuario_id,
                    password_hash,
                    fecha_desde,
                    fecha_hasta,
                    cambiado_por_usuario_id,
                    motivo,
                    estado
                )
                VALUES
                (
                    ?,
                    ?,
                    SYSUTCDATETIME(),
                    NULL,
                    ?,
                    N'Credencial de bootstrap para desarrollo.',
                    1
                )
                """,
                userId,
                encodedPassword,
                actorUserId
        );
    }

    private void ensureRole(
            long userId,
            long roleId,
            long actorUserId
    ) {
        Integer active =
                jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*)
                        FROM seg.UsuarioRol
                        WHERE usuario_id = ?
                          AND rol_id = ?
                          AND estado = 1
                          AND fecha_desde <=
                              SYSUTCDATETIME()
                          AND (
                                fecha_hasta IS NULL
                                OR fecha_hasta >=
                                   SYSUTCDATETIME()
                              )
                        """,
                        Integer.class,
                        userId,
                        roleId
                );

        if (active != null && active > 0) {
            return;
        }

        jdbcTemplate.update(
                """
                INSERT INTO seg.UsuarioRol
                (
                    usuario_id,
                    rol_id,
                    fecha_desde,
                    fecha_hasta,
                    estado,
                    asignado_por_usuario_id,
                    retirado_por_usuario_id,
                    motivo_retiro
                )
                VALUES
                (
                    ?,
                    ?,
                    SYSUTCDATETIME(),
                    NULL,
                    1,
                    ?,
                    NULL,
                    NULL
                )
                """,
                userId,
                roleId,
                actorUserId
        );
    }

    private void grantAllActivePermissions(
            long administratorRoleId,
            long administratorUserId
    ) {
        jdbcTemplate.update(
                """
                UPDATE RP
                SET RP.estado = 1,
                    RP.fecha_retiro = NULL,
                    RP.retirado_por_usuario_id = NULL,
                    RP.motivo_retiro = NULL,
                    RP.fecha_asignacion =
                        COALESCE(
                            RP.fecha_asignacion,
                            SYSUTCDATETIME()
                        ),
                    RP.asignado_por_usuario_id =
                        COALESCE(
                            RP.asignado_por_usuario_id,
                            ?
                        )
                FROM seg.RolPermiso RP
                INNER JOIN seg.Permiso P
                        ON P.permiso_id =
                           RP.permiso_id
                INNER JOIN seg.Modulo M
                        ON M.modulo_id =
                           P.modulo_id
                WHERE RP.rol_id = ?
                  AND P.estado = 1
                  AND M.estado = 1
                """,
                administratorUserId,
                administratorRoleId
        );

        jdbcTemplate.update(
                """
                INSERT INTO seg.RolPermiso
                (
                    rol_id,
                    permiso_id,
                    estado,
                    fecha_asignacion,
                    asignado_por_usuario_id,
                    fecha_retiro,
                    retirado_por_usuario_id,
                    motivo_retiro
                )
                SELECT
                    ?,
                    P.permiso_id,
                    1,
                    SYSUTCDATETIME(),
                    ?,
                    NULL,
                    NULL,
                    NULL
                FROM seg.Permiso P
                INNER JOIN seg.Modulo M
                        ON M.modulo_id =
                           P.modulo_id
                WHERE P.estado = 1
                  AND M.estado = 1
                  AND NOT EXISTS
                      (
                          SELECT 1
                          FROM seg.RolPermiso RP
                          WHERE RP.rol_id = ?
                            AND RP.permiso_id =
                                P.permiso_id
                      )
                """,
                administratorRoleId,
                administratorUserId,
                administratorRoleId
        );

        Integer missing =
                jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*)
                        FROM seg.Permiso P
                        INNER JOIN seg.Modulo M
                                ON M.modulo_id =
                                   P.modulo_id
                        WHERE P.estado = 1
                          AND M.estado = 1
                          AND NOT EXISTS
                              (
                                  SELECT 1
                                  FROM seg.RolPermiso RP
                                  WHERE RP.rol_id = ?
                                    AND RP.permiso_id =
                                        P.permiso_id
                                    AND RP.estado = 1
                              )
                        """,
                        Integer.class,
                        administratorRoleId
                );

        if (missing != null && missing > 0) {
            throw new IllegalStateException(
                    "No se pudieron habilitar todos los permisos "
                            + "del administrador de desarrollo. "
                            + "Faltantes: "
                            + missing
            );
        }
    }

    private record LoginSeed(
            String username,
            String password,
            String roleCode,
            String email,
            String documentNumber,
            String givenNames,
            String paternalSurname,
            String employeeCode
    ) {
    }

    private record UserRow(
            long userId,
            String passwordHash
    ) {
    }
}
