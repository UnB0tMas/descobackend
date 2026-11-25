package com.franco.desco.application.productive.summary;

import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.stereotype.Service;

@Service
public class GpResumenService {
    private final GpResumenPort port;

    public GpResumenService(GpResumenPort port) {
        this.port = port;
    }

    public GpResumenDto consultar(SessionIdentity usuario, long uotId, long actividadId,
                                 String periodo, String tipoEvento) {
        return port.consultar(usuario, uotId, actividadId, periodo, tipoEvento);
    }
}
