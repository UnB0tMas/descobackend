package com.franco.desco.application.property.port.out;

import com.franco.desco.application.property.*;
import com.franco.desco.application.property.PropertyCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.property.*;
import java.util.*;

public interface PropertyPersistencePort {
    PersistenceResult<PageResult<PropertyModels.Summary>> list(ListProperties c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<PropertyModels.Detail> get(GetProperty c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(CreateProperty c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(UpdateProperty c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> retire(RetireProperty c,SessionIdentity i,RequestMetadata m);
}
