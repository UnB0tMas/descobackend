package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.PaResultSets;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.auth.port.out.SecurityNotificationPort;
import com.franco.desco.domain.auth.SecurityNotification;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Repository
@Primary
public class SecurityNotificationSqlServerAdapter
        implements SecurityNotificationPort {

    private static final String PENDING_PROCEDURE =
            "seg.PA_Seguridad_Sel_NotificacionesPendientes";

    private static final String RESULT_PROCEDURE =
            "seg.PA_Seguridad_Upd_NotificacionResultado";

    private final SqlServerPaExecutor executor;
    private final JsonMapper jsonMapper;

    public SecurityNotificationSqlServerAdapter(
            SqlServerPaExecutor executor,
            JsonMapper jsonMapper
    ) {
        this.executor = executor;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public List<SecurityNotification> pending(
            int limit
    ) {
        int safeLimit =
                Math.max(
                        1,
                        Math.min(
                                limit <= 0 ? 50 : limit,
                                500
                        )
                );

        PaExecution execution =
                executor.execute(
                        PENDING_PROCEDURE,
                        Map.of(
                                "cantidad",
                                safeLimit
                        )
                );

        if (!execution.exitoso()
                || execution.resultSets().isEmpty()
                || execution.resultSets()
                .getFirst()
                .isEmpty()) {
            return List.of();
        }

        return execution.resultSets()
                .getFirst()
                .stream()
                .map(this::notification)
                .filter(Objects::nonNull)
                .toList();
    }

    @Override
    public void markResult(
            Long securityNotificationId,
            String result,
            String detail
    ) {
        if (securityNotificationId == null) {
            return;
        }

        String state =
                "ENVIADO".equalsIgnoreCase(result)
                        ? "ENVIADO"
                        : "FALLIDO";

        Map<String, Object> payload =
                new LinkedHashMap<>();

        payload.put(
                "notificacionSeguridadId",
                securityNotificationId
        );
        payload.put(
                "estadoEnvio",
                state
        );

        if (detail != null
                && !detail.isBlank()) {
            payload.put(
                    "proveedorMensajeId",
                    detail.trim()
            );
        }

        executor.execute(
                RESULT_PROCEDURE,
                Map.of(
                        "cJson",
                        write(payload)
                )
        );
    }

    private SecurityNotification notification(
            Map<String, Object> row
    ) {
        Long notificationId =
                PaResultSets.longValue(
                        row,
                        "notificacionSeguridadId"
                );

        if (notificationId == null) {
            return null;
        }

        return new SecurityNotification(
                notificationId,
                PaResultSets.longValue(
                        row,
                        "usuarioId"
                ),
                PaResultSets.string(
                        row,
                        "tipoNotificacion"
                ),
                PaResultSets.string(
                        row,
                        "correoDestino"
                ),
                PaResultSets.instant(
                        row,
                        "fechaCreacionUtc"
                ),
                PaResultSets.intValue(
                        row,
                        "cantidadIntentos"
                ),
                PaResultSets.uuid(
                        row,
                        "correlacionId"
                ),
                PaResultSets.string(
                        row,
                        "metadata"
                )
        );
    }

    private String write(
            Map<String, ?> payload
    ) {
        try {
            return jsonMapper.writeValueAsString(
                    payload
            );
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo preparar la notificación de seguridad.",
                    exception
            );
        }
    }
}
