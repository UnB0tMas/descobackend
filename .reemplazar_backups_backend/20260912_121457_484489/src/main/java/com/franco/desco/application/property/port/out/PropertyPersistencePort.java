package com.franco.desco.application.property.port.out;

import com.franco.desco.application.property.PropertyCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.property.PropertyModels;

public interface PropertyPersistencePort {
    PersistenceResult<PageResult<PropertyModels.Summary>> list(ListProperties command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<PropertyModels.Detail> get(GetProperty command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> create(CreateProperty command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> update(UpdateProperty command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> retire(RetireProperty command, SessionIdentity identity, RequestMetadata metadata);
}
