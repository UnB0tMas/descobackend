package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlValues;
import com.franco.desco.application.auth.port.out.SecurityNotificationPort;
import com.franco.desco.domain.auth.SecurityNotification;
import org.springframework.jdbc.core.ColumnMapRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class SecurityNotificationSqlServerAdapter
        implements SecurityNotificationPort {

    private final SqlServerPaExecutor executor;
    private final SimpleJdbcCall pendingCall;
    private final SimpleJdbcCall markResultCall;

    public SecurityNotificationSqlServerAdapter(
            SqlServerPaFactory factory,
            SqlServerPaExecutor executor
    ) {
        this.executor = executor;

        this.pendingCall = factory.call(
                        "seg",
                        "PA_Seguridad_Sel_NotificacionesPendientes"
                )
                .returningResultSet(
                        "notificaciones",
                        new ColumnMapRowMapper()
                );

        this.markResultCall = factory.call(
                "seg",
                "PA_Seguridad_Upd_NotificacionResultado"
        );
    }

    @Override
    public List<SecurityNotification> pending(
            int limit
    ) {
        Map<String, Object> result =
                executor.execute(
                        pendingCall,
                        Map.of(
                                "nCantidad",
                                limit
                        )
                );

        return rows(
                result,
                "notificaciones"
        ).stream()
                .map(row ->
                        new SecurityNotification(
                                SqlValues.longValue(
                                        row,
                                        "notificacionSeguridadId"
                                ),
                                SqlValues.longValue(
                                        row,
                                        "usuarioId"
                                ),
                                SqlValues.string(
                                        row,
                                        "tipoNotificacion"
                                ),
                                SqlValues.string(
                                        row,
                                        "correoDestino"
                                ),
                                SqlValues.instant(
                                        row,
                                        "fechaCreacionUtc"
                                ),
                                SqlValues.intValue(
                                        row,
                                        "cantidadIntentos"
                                ),
                                SqlValues.uuid(
                                        row,
                                        "correlacionId"
                                ),
                                SqlValues.string(
                                        row,
                                        "metadata"
                                )
                        )
                )
                .toList();
    }

    @Override
    public void markResult(
            Long notificationId,
            String status,
            String providerMessageId
    ) {
        Map<String, Object> payload =
                new LinkedHashMap<>();

        payload.put(
                "notificacionSeguridadId",
                notificationId
        );
        payload.put(
                "estadoEnvio",
                status
        );
        payload.put(
                "proveedorMensajeId",
                providerMessageId
        );

        executor.executeJson(
                markResultCall,
                payload
        );
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> rows(
            Map<String, Object> result,
            String key
    ) {
        Object value =
                SqlValues.value(
                        result,
                        key
                );

        if (value instanceof List<?> list) {
            return (List<Map<String, Object>>) list;
        }

        return List.of();
    }
}
