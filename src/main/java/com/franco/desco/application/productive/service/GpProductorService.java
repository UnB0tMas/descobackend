package com.franco.desco.application.productive.service;

import com.franco.desco.application.productive.port.out.GpProductorPersistencePort;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.productive.GpProductorModels;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
public class GpProductorService {
    private final GpProductorPersistencePort port;

    public GpProductorService(GpProductorPersistencePort port) {
        this.port = port;
    }

    public List<GpProductorModels.Productor> listar(SessionIdentity user, long uotId, String buscar) {
        return port.listar(user, uotId, buscar);
    }

    public List<GpProductorModels.Parcela> parcelas(SessionIdentity user, long uotId, long personaId) {
        return port.parcelas(user, uotId, personaId);
    }

    public long crearParcela(SessionIdentity user, long uotId, long personaId,
                             GpProductorModels.FichaParcela ficha, UUID solicitud) {
        return port.crearParcela(user, uotId, personaId, ficha, solicitud);
    }

    public long editar(SessionIdentity user, long uotId, long personaId,
                       GpProductorModels.FichaPersona ficha, UUID solicitud) {
        return port.editar(user, uotId, personaId, ficha, solicitud);
    }

    public long desactivar(SessionIdentity user, long uotId, long personaId, String motivo, UUID solicitud) {
        return port.desactivar(user, uotId, personaId, motivo, solicitud);
    }
}
