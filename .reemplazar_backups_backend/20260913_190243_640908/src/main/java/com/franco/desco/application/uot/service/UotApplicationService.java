package com.franco.desco.application.uot.service;

import com.franco.desco.application.shared.*;
import com.franco.desco.application.uot.UotCommands;
import com.franco.desco.application.uot.port.in.UotUseCase;
import com.franco.desco.application.uot.port.out.UotPersistencePort;
import com.franco.desco.domain.uot.UotModels;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UotApplicationService implements UotUseCase {
    private final UotPersistencePort persistence;

    public UotApplicationService(UotPersistencePort persistence) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<UotModels.Context> context(SessionIdentity identity) {
        return ApplicationResults.ok(persistence.context(identity), "UOT_CONTEXTO_OBTENIDO", "UOT_CONTEXTO_NO_DISPONIBLE", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<UotModels.Context> select(UotCommands.SelectContext command, SessionIdentity identity) {
        PersistenceResult<Void> result = persistence.select(command, identity);
        if (!result.exitoso()) {
            return AppResult.error(AppStatus.fromHttp(result.httpSugerido(), AppStatus.BAD_REQUEST),
                    result.codigo() == null ? "UOT_CONTEXTO_NO_ACTUALIZADO" : result.codigo(), result.mensaje());
        }
        return context(identity);
    }

    @Override
    public AppResult<List<UotModels.Unit>> list(SessionIdentity identity, Long uotId, boolean includeInactive) {
        return ApplicationResults.ok(persistence.list(identity, uotId, includeInactive), "UOT_LISTADAS", "UOT_NO_LISTADAS", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<Long> create(UotCommands.CreateUnit command, SessionIdentity identity) {
        return ApplicationResults.created(persistence.create(command, identity), "UOT_CREADA", "UOT_NO_CREADA");
    }

    @Override
    public AppResult<Void> update(UotCommands.UpdateUnit command, SessionIdentity identity) {
        return ApplicationResults.ok(persistence.update(command, identity), "UOT_ACTUALIZADA", "UOT_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<Void> assignUser(UotCommands.AssignUser command, SessionIdentity identity) {
        return ApplicationResults.ok(persistence.assignUser(command, identity), "UOT_USUARIO_ASIGNADO", "UOT_USUARIO_NO_ASIGNADO", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<Void> assignRole(UotCommands.AssignRole command, SessionIdentity identity) {
        return ApplicationResults.ok(persistence.assignRole(command, identity), "UOT_ROL_ASIGNADO", "UOT_ROL_NO_ASIGNADO", AppStatus.BAD_REQUEST);
    }
}
