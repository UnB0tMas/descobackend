package com.franco.desco.application.uot.port.out;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.UotCommands;
import com.franco.desco.domain.uot.UotModels;

import java.util.List;

public interface UotPersistencePort {
    PersistenceResult<UotModels.Context> context(SessionIdentity identity);
    PersistenceResult<Void> select(UotCommands.SelectContext command, SessionIdentity identity);
    PersistenceResult<List<UotModels.Unit>> list(SessionIdentity identity, Long uotId, boolean includeInactive);
    PersistenceResult<Long> create(UotCommands.CreateUnit command, SessionIdentity identity);
    PersistenceResult<Void> update(UotCommands.UpdateUnit command, SessionIdentity identity);
    PersistenceResult<Void> assignUser(UotCommands.AssignUser command, SessionIdentity identity);
    PersistenceResult<Void> assignRole(UotCommands.AssignRole command, SessionIdentity identity);
    boolean hasPermission(SessionIdentity identity, String permissionCode);
    boolean hasPermission(SessionIdentity identity, Long uotId, String permissionCode);
    boolean hasAccess(SessionIdentity identity, Long uotId);
}
