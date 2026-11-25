package com.franco.desco.application.productive.summary;

import com.franco.desco.application.shared.SessionIdentity;

public interface GpResumenPort {
    GpResumenDto consultar(SessionIdentity usuario, long uotId, long actividadId,
                           String periodo, String tipoEvento);
}
