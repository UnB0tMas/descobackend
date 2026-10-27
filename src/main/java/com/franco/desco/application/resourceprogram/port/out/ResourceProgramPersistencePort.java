package com.franco.desco.application.resourceprogram.port.out;

import com.franco.desco.application.resourceprogram.*;
import com.franco.desco.application.resourceprogram.ResourceProgramCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.resourceprogram.*;
import java.util.*;

public interface ResourceProgramPersistencePort {
    PersistenceResult<PageResult<ResourceProgramModels.Summary>> list(ResourceProgramCommands.ListResources c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<ResourceProgramModels.Detail> get(ResourceProgramCommands.Get c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<ResourceProgramModels.Availability> availability(SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> program(ResourceProgramCommands.Program c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(ResourceProgramCommands.Update c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> assign(ResourceProgramCommands.Assign c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> returnResource(ResourceProgramCommands.ReturnResource c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> consume(ResourceProgramCommands.Consume c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> cancel(ResourceProgramCommands.Cancel c,SessionIdentity i,RequestMetadata m);
}
