package com.franco.desco.adapter.in.web.incident;

import com.franco.desco.application.incident.IncidentCommands;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.incident.IncidentModels;
import org.springframework.stereotype.Component;

@Component
public class IncidentWebMapper {
    public IncidentCommands.ListIncidents list(int pagina, int tamano, Long operativoVentaId, Long entregaSocioId, String estado, String tipo, String severidad) {
        return new IncidentCommands.ListIncidents(new PageRequest<>(
                pagina, tamano,
                new IncidentCommands.Filter(operativoVentaId, entregaSocioId, estado, tipo, severidad),
                null, null
        ));
    }

    public IncidentCommands.Create command(IncidentRequests.Create r) {
        return new IncidentCommands.Create(r.operativoVentaId(), r.entregaSocioId(), r.tipoIncidencia(), r.pesoAfectadoKg(), r.severidad(), r.descripcion());
    }

    public IncidentCommands.Review command(Long id, IncidentRequests.Review r) {
        return new IncidentCommands.Review(id, r.pesoAfectadoKg(), r.severidad(), r.descripcion());
    }

    public IncidentResponses.Summary response(IncidentModels.Summary x) {
        return new IncidentResponses.Summary(
                x.incidenciaId(), x.operativoVentaId(), x.operativo(), x.entregaSocioId(), x.codigoLote(),
                x.tipoIncidencia(), x.fechaHora(), x.pesoAfectadoKg(), x.severidad(), x.descripcion(), x.estadoIncidencia()
        );
    }

    public IncidentResponses.Detail response(IncidentModels.Detail x) {
        return new IncidentResponses.Detail(
                response(x.incidencia()),
                x.archivos().stream().map(a -> new IncidentResponses.Attachment(
                        a.archivoId(), a.nombreOriginal(), a.mimeType(), a.secureUrl(), a.categoria(), a.descripcion()
                )).toList()
        );
    }
}
