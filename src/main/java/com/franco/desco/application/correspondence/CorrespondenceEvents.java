package com.franco.desco.application.correspondence;

import org.springframework.stereotype.Component;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import java.io.IOException;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/** Un canal SSE por usuario, sin publicar datos documentales ni notificar a terceros. */
@Component
public final class CorrespondenceEvents {
    private final ConcurrentHashMap<Long,Set<SseEmitter>> clients=new ConcurrentHashMap<>();

    public SseEmitter subscribe(Long userId) {
        if(userId==null) throw new IllegalArgumentException("Sesión no disponible.");
        SseEmitter emitter=new SseEmitter(0L);
        Set<SseEmitter> viewers=clients.computeIfAbsent(userId,key->ConcurrentHashMap.newKeySet());
        viewers.add(emitter);
        Runnable cleanup=()->{
            viewers.remove(emitter);
            if(viewers.isEmpty()) clients.remove(userId,viewers);
        };
        emitter.onCompletion(cleanup);
        emitter.onTimeout(cleanup);
        emitter.onError(error->cleanup.run());
        try {
            emitter.send(SseEmitter.event().name("conectado").data("ok"));
        } catch(IOException | IllegalStateException error) {
            cleanup.run();
            emitter.complete();
        }
        return emitter;
    }

    // Mantener viva la conexion para evitar expiraciones de proxies. No consulta SQL.
    @Scheduled(fixedDelay = 15000L)
    public void heartbeat() {
        for (Long userId : clients.keySet()) {
            send(userId, null);
        }
    }

    public void changed(Long userId) {
        send(userId, "actualizar");
    }

    private void send(Long userId, String eventName) {
        Set<SseEmitter> viewers=clients.get(userId);
        if(viewers==null)return;
        for(SseEmitter emitter:viewers) {
            try {
                if (eventName == null) emitter.send(SseEmitter.event().comment("keepalive"));
                else emitter.send(SseEmitter.event().name(eventName).data("ok"));
            } catch(IOException | IllegalStateException error) {
                viewers.remove(emitter);
                emitter.complete();
            }
        }
        if(viewers.isEmpty()) clients.remove(userId,viewers);
    }
}
