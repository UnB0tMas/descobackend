package com.franco.desco.application.correspondence;

import com.franco.desco.adapter.out.sqlserver.correspondence.CorrespondenceSqlServerRepository;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** La transición confirmada en SQL es la única fuente de verdad. */
@Service
public final class CorrespondenceService {
    private static final Logger LOG = LoggerFactory.getLogger(CorrespondenceService.class);
    private static final Set<String> NOTIFY_ACTIONS=Set.of(
            "ENVIAR","ATENDER","ABRIR","ABRIR_HILO","ANULAR","FINALIZAR","CONFORMAR","RECORDAR");
    private final CorrespondenceSqlServerRepository repository;
    private final CorrespondenceEvents events;

    public CorrespondenceService(CorrespondenceSqlServerRepository repository, CorrespondenceEvents events) {
        this.repository=repository;
        this.events=events;
    }

    public <T> AppResult<T> execute(String action,Object data,SessionIdentity identity,
                                    RequestMetadata metadata,Class<T> type) {
        AppResult<T> result=repository.execute(action,data,identity,metadata,type);
        if(result.exitoso() && NOTIFY_ACTIONS.contains(action)) {
            Long id=extractId(data,"documentoId");
            if(id==null && result.datos() instanceof Map<?,?> body) id=asLong(body.get("documentoId"));
            notifyDocumentChanged(id, extractId(data,"uotId"), action, identity, metadata);
        }
        return result;
    }

    /** Reutiliza la audiencia autorizada de correspondencia tras confirmar una operación. */
    public void notifyDocumentChanged(Long documentId, Long uotId, String action,
                                      SessionIdentity identity, RequestMetadata metadata) {
        if (documentId == null || documentId <= 0) return;
        try {
            Map<String, Object> request = new HashMap<>();
            request.put("documentoId", documentId);
            if (uotId != null) request.put("uotId", uotId);
            request.put("tipoAviso", action);
            AppResult<Object> audience = repository.execute("AVISOS", request, identity, metadata, Object.class);
            if (!audience.exitoso()) {
                LOG.warn("Aviso documental no publicado. Documento {}, acción {}, código {}",
                        documentId, action, audience.codigo());
                return;
            }
            if (audience.datos() instanceof List<?> users) {
                Set<Long> recipients = new java.util.HashSet<>();
                for (Object item : users) {
                    Long userId = extractId(item, "usuarioId");
                    if (userId != null && userId > 0 && recipients.add(userId)) {
                        events.changed(userId);
                    }
                }
            }
        } catch (RuntimeException ex) {
            // Un aviso fallido no debe convertir una operación ya confirmada en un error de guardado.
            LOG.warn("No se pudo publicar el aviso documental. Documento {}, acción {}",
                    documentId, action, ex);
        }
    }

    private static Long extractId(Object data,String key) {
        return data instanceof Map<?,?> params?asLong(params.get(key)):null;
    }

    private static Long asLong(Object value) {
        if(value instanceof Number number) return number.longValue();
        if(value instanceof String text) try {return Long.parseLong(text);}catch(NumberFormatException ignored) {}
        return null;
    }
}
