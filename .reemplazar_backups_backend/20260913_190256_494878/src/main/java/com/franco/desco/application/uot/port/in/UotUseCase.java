package com.franco.desco.application.uot.port.in;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.UotCommands;
import com.franco.desco.domain.uot.UotModels;

import java.util.List;

public interface UotUseCase {
    AppResult<UotModels.Context> context(SessionIdentity identity);
    AppResult<UotModels.Context> select(UotCommands.SelectContext command, SessionIdentity identity);
    AppResult<List<UotModels.Unit>> list(SessionIdentity identity, Long uotId, boolean includeInactive);
    AppResult<Long> create(UotCommands.CreateUnit command, SessionIdentity identity);
    AppResult<Void> update(UotCommands.UpdateUnit command, SessionIdentity identity);
    AppResult<Void> assignUser(UotCommands.AssignUser command, SessionIdentity identity);
    AppResult<Void> assignRole(UotCommands.AssignRole command, SessionIdentity identity);
}
