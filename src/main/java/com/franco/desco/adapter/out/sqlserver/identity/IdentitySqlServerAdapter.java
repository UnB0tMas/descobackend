package com.franco.desco.adapter.out.sqlserver.identity;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.application.identity.port.out.IdentityPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.identity.IdentityModels.LocalResolution;
import com.franco.desco.domain.identity.IdentityModels.PersistOutcome;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import com.franco.desco.domain.identity.IdentityModels.Reservation;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class IdentitySqlServerAdapter
        implements IdentityPersistencePort {

    private final SqlServerPaExecutor executor;
    private final DatabaseRecordMapper mapper;
    private final JsonMapper jsonMapper;

    public IdentitySqlServerAdapter(
            SqlServerPaExecutor executor,
            DatabaseRecordMapper mapper,
            JsonMapper jsonMapper
    ) {
        this.executor = executor;
        this.mapper = mapper;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public PersistenceResult<LocalResolution> resolveLocal(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return one(
                "integracion.PA_Identidad_Sel_ResolverDocumento",
                request(
                        command,
                        identity,
                        metadata,
                        null
                ),
                LocalResolution.class
        );
    }

    @Override
    public PersistenceResult<Reservation> reserveExternalQuery(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return one(
                "integracion.PA_Identidad_Ins_ReservarConsultaExterna",
                request(
                        command,
                        identity,
                        metadata,
                        null
                ),
                Reservation.class
        );
    }

    @Override
    public PersistenceResult<PersistOutcome> registerExternalResult(
            ResolveDocument command,
            ProviderResult providerResult,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> result =
                new LinkedHashMap<>();

        result.put(
                "exito",
                providerResult != null
                        && providerResult.exito()
        );
        result.put(
                "encontrado",
                providerResult != null
                        && providerResult.encontrado()
        );
        result.put(
                "codigoError",
                providerResult == null
                        ? "NO_RESULT"
                        : providerResult.codigoError()
        );
        result.put(
                "datos",
                providerResult == null
                        ? null
                        : providerResult.datos()
        );

        return one(
                "integracion.PA_Identidad_Upd_ResultadoConsultaExterna",
                request(
                        command,
                        identity,
                        metadata,
                        result
                ),
                PersistOutcome.class
        );
    }

    private <T> PersistenceResult<T> one(
            String procedure,
            Map<String, Object> payload,
            Class<T> type
    ) {
        PaExecution execution =
                execute(
                        procedure,
                        payload
                );

        if (!execution.exitoso()) {
            return execution.toPersistence(null);
        }

        return execution.toPersistence(
                mapper.aggregate(
                        execution.resultSets(),
                        type
                )
        );
    }

    private Map<String, Object> request(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata,
            Map<String, Object> result
    ) {
        Map<String, Object> root =
                new LinkedHashMap<>();

        Map<String, Object> context =
                new LinkedHashMap<>();

        context.put(
                "sesionPublicaId",
                identity.sesionPublicaId()
        );
        context.put(
                "correlacionId",
                metadata.correlacionId()
        );
        context.put(
                "solicitudId",
                metadata.solicitudId()
        );
        context.put(
                "ip",
                metadata.ip()
        );
        context.put(
                "endpoint",
                metadata.endpoint()
        );

        Map<String, Object> query =
                new LinkedHashMap<>();

        query.put(
                "entidadObjetivo",
                command.entidadObjetivo().name()
        );
        query.put(
                "tipoDocumento",
                command.tipoDocumento().name()
        );
        query.put(
                "numeroDocumento",
                command.numeroDocumento()
        );

        root.put("contexto", context);
        root.put("consulta", query);

        if (result != null) {
            root.put("resultado", result);
        }

        return root;
    }

    private PaExecution execute(
            String procedure,
            Map<String, Object> payload
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
                    "No se pudo preparar la validación de identidad.",
                    exception
            );
        }
    }
}
