package com.franco.desco.application.report.service;

import com.franco.desco.application.report.port.out.ReportJobEventScopePort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/** Canal temporal por usuario y UOT, compartido por todos los informes en preparación. */
@Service
public class ReportJobEventService {
    private static final long TIMEOUT_MS = 300_000L;
    private final ReportJobEventScopePort scopes;
    private final Map<Scope, Set<SseEmitter>> listeners = new ConcurrentHashMap<>();

    private record Scope(long usuarioId, long uotId) {}

    public ReportJobEventService(ReportJobEventScopePort scopes) {
        this.scopes = scopes;
    }

    public SseEmitter subscribe(SessionIdentity identity) {
        Long uotId = scopes.findSpecificUot(identity.usuarioId(), identity.sesionPublicaId());
        if (uotId == null) {
            throw new org.springframework.security.access.AccessDeniedException("Acceso no autorizado.");
        }
        Scope scope = new Scope(identity.usuarioId(), uotId);
        SseEmitter emitter = new SseEmitter(TIMEOUT_MS);
        listeners.computeIfAbsent(scope, key -> ConcurrentHashMap.newKeySet()).add(emitter);
        Runnable cleanup = () -> remove(scope, emitter);
        emitter.onCompletion(cleanup);
        emitter.onTimeout(cleanup);
        emitter.onError(error -> cleanup.run());
        try {
            emitter.send(SseEmitter.event().name("conectado").data("{}"));
        } catch (IOException | RuntimeException exception) {
            cleanup.run();
        }
        return emitter;
    }

    public void completed(long usuarioId, long uotId, long trabajoId, String tipo, String estado) {
        if (usuarioId <= 0 || uotId <= 0 || trabajoId <= 0 ||
                !("LISTO".equals(estado) || "ERROR".equals(estado))) {
            return;
        }
        Scope scope = new Scope(usuarioId, uotId);
        Set<SseEmitter> subscribers = listeners.get(scope);
        if (subscribers == null) return;
        Map<String, Object> data = Map.of("id", trabajoId, "tipo", tipo, "estado", estado);
        for (SseEmitter emitter : subscribers) {
            try {
                emitter.send(SseEmitter.event().name("finalizado").data(data));
            } catch (IOException | RuntimeException exception) {
                remove(scope, emitter);
            }
        }
    }

    /** Mantiene los canales vivos sin consultas a la base de datos. */
    @Scheduled(fixedDelay = 25_000L)
    public void keepAlive() {
        listeners.forEach((scope, subscribers) -> subscribers.forEach(emitter -> {
            try {
                emitter.send(SseEmitter.event().comment("activo"));
            } catch (IOException | RuntimeException exception) {
                remove(scope, emitter);
            }
        }));
    }

    private void remove(Scope scope, SseEmitter emitter) {
        listeners.computeIfPresent(scope, (key, current) -> {
            current.remove(emitter);
            return current.isEmpty() ? null : current;
        });
    }
}
