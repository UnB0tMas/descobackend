package com.franco.desco.application.productive.port.out;

import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.productive.GpProductorModels;
import java.util.List;
import java.util.UUID;

public interface GpProductorPersistencePort {
    List<GpProductorModels.Productor> listar(SessionIdentity identity, long uotId, String buscar);
    List<GpProductorModels.Parcela> parcelas(SessionIdentity identity, long uotId, long personaId);
    long crearParcela(SessionIdentity identity, long uotId, long personaId,
                      GpProductorModels.FichaParcela ficha, UUID solicitud);
    long editar(SessionIdentity identity, long uotId, long personaId,
                GpProductorModels.FichaPersona ficha, UUID solicitud);
    long desactivar(SessionIdentity identity, long uotId, long personaId, String motivo, UUID solicitud);
}
