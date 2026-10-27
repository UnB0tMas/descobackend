package com.franco.desco.application.property.port.in;

import com.franco.desco.application.property.PropertyCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.property.PropertyModels;

public interface PropertyUseCase {
    AppResult<PageResult<PropertyModels.Summary>> list(ListProperties command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<PropertyModels.Detail> get(GetProperty command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(CreateProperty command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> update(UpdateProperty command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> retire(RetireProperty command, SessionIdentity identity, RequestMetadata metadata);
}
