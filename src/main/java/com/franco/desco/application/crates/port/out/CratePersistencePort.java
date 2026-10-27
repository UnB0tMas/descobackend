package com.franco.desco.application.crates.port.out;

import com.franco.desco.application.crates.*;
import com.franco.desco.application.crates.CrateCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.crates.*;
import java.util.*;

public interface CratePersistencePort {
    PersistenceResult<PageResult<CrateModels.Summary>> list(CrateCommands.ListCrates c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<CrateModels.Balance> balance(CrateCommands.Balance c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<List<CrateModels.History>> history(CrateCommands.History c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> receive(CrateCommands.Receive c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> assign(CrateCommands.Assign c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> returnCrates(CrateCommands.ReturnCrates c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> annul(CrateCommands.Annul c,SessionIdentity i,RequestMetadata m);
}
