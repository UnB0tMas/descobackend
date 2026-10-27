package com.franco.desco.adapter.in.web.uot;

import com.franco.desco.application.uot.UotCommands;
import com.franco.desco.domain.uot.UotModels;
import org.springframework.stereotype.Component;

@Component
public class UotWebMapper {
    public UotCommands.SelectContext command(UotRequests.SelectContext request) {
        String mode = request.modo().trim().toUpperCase();
        return new UotCommands.SelectContext(mode, "GENERAL".equals(mode) ? null : request.uotId());
    }

    public UotCommands.CreateUnit command(UotRequests.Create request, java.util.UUID idempotencyKey) {
        return new UotCommands.CreateUnit(request.uotPadreId(), request.ubicacionId(), request.codigo(), request.nombre(), request.descripcion(), idempotencyKey);
    }

    public UotCommands.UpdateUnit command(Long id, UotRequests.Update request) {
        return new UotCommands.UpdateUnit(id, request.uotPadreId(), request.ubicacionId(), request.nombre(), request.descripcion(), request.estado());
    }

    public UotResponses.Unit response(UotModels.Unit value) {
        return new UotResponses.Unit(value.uotId(), value.parentUotId(), value.locationId(), value.code(), value.name(), value.description(),
                value.root(), value.startDate(), value.endDate(), value.active(), value.assigned(), value.defaultUnit());
    }

    public UotResponses.Context response(UotModels.Context value) {
        return new UotResponses.Context(value.mode(), value.selectedUotId(), value.selectionRequired(), value.generalModeAllowed(),
                value.memberships().stream().map(m -> new UotResponses.Membership(m.userUotId(), m.uotId(), m.code(), m.name(), m.defaultUnit(), m.roles())).toList());
    }
}
