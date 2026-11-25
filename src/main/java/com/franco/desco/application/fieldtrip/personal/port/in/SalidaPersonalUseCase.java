package com.franco.desco.application.fieldtrip.personal.port.in;

import com.franco.desco.application.fieldtrip.personal.SalidaPersonalQuery;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.fieldtrip.SalidaPersonalModels;

public interface SalidaPersonalUseCase {
    AppResult<SalidaPersonalModels.Lista> listar(SalidaPersonalQuery query,
            SessionIdentity identity, RequestMetadata metadata);
    AppResult<SalidaPersonalModels.Detalle> detalle(SalidaPersonalQuery query,
            SessionIdentity identity, RequestMetadata metadata);
}
