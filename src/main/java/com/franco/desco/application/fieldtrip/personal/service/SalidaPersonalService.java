package com.franco.desco.application.fieldtrip.personal.service;

import com.franco.desco.application.fieldtrip.personal.SalidaPersonalQuery;
import com.franco.desco.application.fieldtrip.personal.port.in.SalidaPersonalUseCase;
import com.franco.desco.application.fieldtrip.personal.port.out.SalidaPersonalPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.fieldtrip.SalidaPersonalModels;
import org.springframework.stereotype.Service;

@Service
public class SalidaPersonalService implements SalidaPersonalUseCase {
    private final SalidaPersonalPersistencePort persistence;

    public SalidaPersonalService(SalidaPersonalPersistencePort persistence) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<SalidaPersonalModels.Lista> listar(SalidaPersonalQuery query,
            SessionIdentity identity, RequestMetadata metadata) {
        if (query.uotId() == null || query.uotId() < 1
                || query.pagina() == null || query.pagina() < 1
                || query.tamano() == null || query.tamano() < 1 || query.tamano() > 100)
            return AppResult.error(AppStatus.BAD_REQUEST, "SALIDA_PERSONAL_FILTROS",
                    "Revise los filtros de búsqueda.");
        return outcome(persistence.consultar(query, identity, metadata, SalidaPersonalModels.Lista.class));
    }

    @Override
    public AppResult<SalidaPersonalModels.Detalle> detalle(SalidaPersonalQuery query,
            SessionIdentity identity, RequestMetadata metadata) {
        if (query.uotId() == null || query.uotId() < 1
                || query.salidaId() == null || query.salidaId() < 1)
            return AppResult.error(AppStatus.BAD_REQUEST, "SALIDA_PERSONAL_IDENTIFICADOR",
                    "Seleccione una salida válida.");
        return outcome(persistence.consultar(query, identity, metadata, SalidaPersonalModels.Detalle.class));
    }

    private <T> AppResult<T> outcome(PersistenceResult<T> result) {
        return new AppResult<>(result.exitoso(), result.codigo(), result.mensaje(), result.datos(),
                AppStatus.fromHttp(result.httpSugerido(), AppStatus.BAD_REQUEST));
    }
}
