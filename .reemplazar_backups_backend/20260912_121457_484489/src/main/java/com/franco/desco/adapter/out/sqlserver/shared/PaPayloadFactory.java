package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.port.out.RequestHashPort;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

@Component
public class PaPayloadFactory {

    private final RequestHashPort requestHashPort;

    public PaPayloadFactory(
            RequestHashPort requestHashPort
    ) {
        this.requestHashPort = requestHashPort;
    }

    public Map<String, Object> forQuery(
            SessionIdentity identity,
            RequestMetadata metadata,
            Map<String, Object> businessPayload
    ) {
        requireContext(identity, metadata);

        Map<String, Object> payload =
                businessPayload(businessPayload);

        payload.put(
                "contexto",
                context(
                        identity,
                        metadata,
                        null,
                        null
                )
        );

        return payload;
    }

    public Map<String, Object> forWrite(
            SessionIdentity identity,
            RequestMetadata metadata,
            Object requestBody,
            Map<String, Object> businessPayload
    ) {
        requireContext(identity, metadata);

        UUID idempotencyKey =
                metadata.claveIdempotencia();

        if (idempotencyKey == null) {
            throw new IllegalArgumentException(
                    "La clave de idempotencia es obligatoria para esta operación."
            );
        }

        Map<String, Object> payload =
                businessPayload(businessPayload);

        payload.put(
                "contexto",
                context(
                        identity,
                        metadata,
                        idempotencyKey,
                        requestHashPort.hashObject(
                                requestBody
                        )
                )
        );

        return payload;
    }

    private Map<String, Object> context(
            SessionIdentity identity,
            RequestMetadata metadata,
            UUID idempotencyKey,
            String requestHashHex
    ) {
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
                metadata.solicitudId() == null
                        ? UUID.randomUUID()
                        : metadata.solicitudId()
        );
        context.put("ip", metadata.ip());
        context.put("endpoint", metadata.endpoint());

        if (idempotencyKey != null) {
            context.put(
                    "claveIdempotencia",
                    idempotencyKey
            );
            context.put(
                    "requestHashHex",
                    requestHashHex
            );
        }

        return context;
    }

    private Map<String, Object> businessPayload(
            Map<String, Object> source
    ) {
        Map<String, Object> payload =
                source == null
                        ? new LinkedHashMap<>()
                        : new LinkedHashMap<>(source);

        if (payload.containsKey("contexto")) {
            throw new IllegalArgumentException(
                    "El payload funcional no debe definir el contexto técnico."
            );
        }

        return payload;
    }

    private void requireContext(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Objects.requireNonNull(
                identity,
                "La identidad de sesión es obligatoria."
        );
        Objects.requireNonNull(
                identity.sesionPublicaId(),
                "La sesión pública es obligatoria."
        );
        Objects.requireNonNull(
                metadata,
                "Los metadatos de solicitud son obligatorios."
        );
        Objects.requireNonNull(
                metadata.correlacionId(),
                "La correlación es obligatoria."
        );
    }
}
