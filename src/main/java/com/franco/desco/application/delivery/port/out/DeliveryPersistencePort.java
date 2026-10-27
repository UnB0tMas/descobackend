package com.franco.desco.application.delivery.port.out;

import com.franco.desco.application.delivery.*;
import com.franco.desco.application.delivery.DeliveryCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.delivery.*;
import java.util.*;

public interface DeliveryPersistencePort {
    PersistenceResult<PageResult<DeliveryModels.Summary>> list(DeliveryCommands.ListDeliveries c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<DeliveryModels.Detail> get(DeliveryCommands.Get c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(DeliveryCommands.Create c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> updatePreliminary(DeliveryCommands.UpdatePreliminary c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> confirm(DeliveryCommands.Confirm c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> annul(DeliveryCommands.Annul c,SessionIdentity i,RequestMetadata m);
}
