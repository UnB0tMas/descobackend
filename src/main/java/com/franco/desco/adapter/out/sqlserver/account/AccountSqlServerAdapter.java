package com.franco.desco.adapter.out.sqlserver.account;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.account.port.out.AccountPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.account.AccountModels;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Repository
public final class AccountSqlServerAdapter
        implements AccountPersistencePort {

    private final SqlServerPaExecutor executor;
    private final DatabaseRecordMapper mapper;
    private final JsonMapper jsonMapper;

    public AccountSqlServerAdapter(
            SqlServerPaExecutor executor,
            DatabaseRecordMapper mapper,
            JsonMapper jsonMapper
    ) {
        this.executor = executor;
        this.mapper = mapper;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public PersistenceResult<List<AccountModels.SessionInfo>> sessions(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PaExecution execution =
                json(
                        "seg.PA_Sesion_Sel_Listado",
                        base(identity, metadata)
                );

        return listResult(
                execution,
                AccountModels.SessionInfo.class
        );
    }

    @Override
    public PersistenceResult<Void> closeSession(
            SessionIdentity identity,
            RequestMetadata metadata,
            UUID targetSessionPublicId
    ) {
        Map<String, Object> payload =
                base(identity, metadata);

        payload.put(
                "sesionActualPublicaId",
                identity.sesionPublicaId()
        );
        payload.put(
                "sesionObjetivoPublicaId",
                targetSessionPublicId
        );

        return json(
                "seg.PA_Sesion_Upd_Cerrar",
                payload
        ).toPersistence(null);
    }

    @Override
    public PersistenceResult<Void> closeOtherSessions(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return json(
                "seg.PA_Sesion_Upd_CerrarOtras",
                base(identity, metadata)
        ).toPersistence(null);
    }

    @Override
    public PersistenceResult<List<AccountModels.DeviceInfo>> devices(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PaExecution execution =
                json(
                        "seg.PA_Dispositivo_Sel_Listado",
                        base(identity, metadata)
                );

        return listResult(
                execution,
                AccountModels.DeviceInfo.class
        );
    }

    @Override
    public PersistenceResult<Void> recognizeDevice(
            SessionIdentity identity,
            RequestMetadata metadata,
            Long deviceUserId,
            String action
    ) {
        Map<String, Object> payload =
                base(identity, metadata);

        payload.put(
                "dispositivoUsuarioId",
                deviceUserId
        );
        payload.put("accion", action);

        return json(
                "seg.PA_Dispositivo_Upd_Reconocimiento",
                payload
        ).toPersistence(null);
    }

    @Override
    public PersistenceResult<String> currentPasswordHash(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        PaExecution execution =
                json(
                        "seg.PA_Usuario_Sel_CredencialActual",
                        base(identity, metadata)
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        return execution.toPersistence(
                stringOutput(
                        execution,
                        "passwordHash"
                )
        );
    }

    @Override
    public PersistenceResult<Void> changePassword(
            SessionIdentity identity,
            RequestMetadata metadata,
            String newPasswordHash
    ) {
        Map<String, Object> payload =
                base(identity, metadata);

        payload.put(
                "nuevoPasswordHash",
                newPasswordHash
        );

        return json(
                "seg.PA_Usuario_Upd_CambiarPassword",
                payload
        ).toPersistence(null);
    }

    @Override
    public PersistenceResult<AccountModels.EmailChangeIssue> requestEmailChange(
            SessionIdentity identity,
            RequestMetadata metadata,
            String newEmail,
            String otpHmacHex
    ) {
        Map<String, Object> payload =
                base(identity, metadata);

        payload.put(
                "nuevoCorreo",
                newEmail
        );
        payload.put(
                "codigoHmacHex",
                otpHmacHex
        );

        PaExecution execution =
                json(
                        "seg.PA_Usuario_Ins_SolicitarCambioCorreo",
                        payload
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        AccountModels.EmailChangeIssue issue =
                new AccountModels.EmailChangeIssue(
                        longOutput(
                                execution,
                                "usuarioCorreoSeguridadId"
                        ),
                        longOutput(
                                execution,
                                "codigoUnSoloUsoId"
                        ),
                        longOutput(
                                execution,
                                "notificacionSeguridadId"
                        ),
                        stringOutput(
                                execution,
                                "correoDestino"
                        ),
                        booleanOutput(
                                execution,
                                "debeEnviar"
                        )
                );

        return execution.toPersistence(issue);
    }

    @Override
    public PersistenceResult<Void> confirmEmailChange(
            SessionIdentity identity,
            RequestMetadata metadata,
            String otpHmacHex
    ) {
        Map<String, Object> payload =
                base(identity, metadata);

        payload.put(
                "codigoHmacHex",
                otpHmacHex
        );

        return json(
                "seg.PA_Usuario_Upd_ConfirmarCambioCorreo",
                payload
        ).toPersistence(null);
    }

    private Map<String, Object> base(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> payload =
                new LinkedHashMap<>();

        payload.put(
                "usuarioId",
                identity.usuarioId()
        );
        payload.put(
                "sesionPublicaId",
                identity.sesionPublicaId()
        );
        payload.put(
                "sesionActualPublicaId",
                identity.sesionPublicaId()
        );
        payload.put(
                "tokenVersion",
                identity.tokenVersion()
        );
        payload.put(
                "ip",
                metadata == null
                        ? null
                        : metadata.ip()
        );
        payload.put(
                "correlacionId",
                metadata == null
                        ? null
                        : metadata.correlacionId()
        );

        return payload;
    }

    private <T> PersistenceResult<List<T>> listResult(
            PaExecution execution,
            Class<T> targetType
    ) {
        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        List<Map<String, Object>> rows =
                execution.resultSets().isEmpty()
                        ? List.of()
                        : execution.resultSets()
                        .getFirst();

        return execution.toPersistence(
                mapper.rows(
                        rows,
                        targetType
                )
        );
    }

    private PaExecution json(
            String procedure,
            Map<String, ?> payload
    ) {
        try {
            return executor.execute(
                    procedure,
                    Map.of(
                            "cJson",
                            jsonMapper.writeValueAsString(
                                    payload
                            )
                    )
            );
        } catch (Exception exception) {
            if (exception
                    instanceof com.franco.desco.adapter.out.sqlserver.shared.PaExecutionException) {
                throw exception;
            }

            throw new IllegalStateException(
                    "No se pudo preparar la operación de cuenta.",
                    exception
            );
        }
    }

    private Object output(
            PaExecution execution,
            String key
    ) {
        String normalized =
                normalize(key);

        for (Map.Entry<String, Object> entry
                : execution.outputs().entrySet()) {

            if (normalize(
                    entry.getKey()
            ).equals(normalized)) {
                return entry.getValue();
            }
        }

        return null;
    }

    private String stringOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        return value == null
                ? null
                : value.toString().trim();
    }

    private Long longOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        return value instanceof Number number
                ? number.longValue()
                : null;
    }

    private boolean booleanOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        if (value instanceof Boolean bool) {
            return bool;
        }

        return value instanceof Number number
                && number.intValue() != 0;
    }

    private String normalize(String value) {
        return value == null
                ? ""
                : value
                .replace("_", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }
}
