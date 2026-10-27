package com.franco.desco.application.fieldtrip.port.out;

import com.franco.desco.application.fieldtrip.*;
import com.franco.desco.application.fieldtrip.FieldTripCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.fieldtrip.*;
import java.util.*;

public interface FieldTripPersistencePort {
    PersistenceResult<PageResult<FieldTripModels.Summary>> list(FieldTripCommands.ListTrips c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<FieldTripModels.Detail> get(FieldTripCommands.GetTrip c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> program(FieldTripCommands.Program c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(FieldTripCommands.Update c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> cancel(FieldTripCommands.Cancel c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> finish(FieldTripCommands.Finish c,SessionIdentity i,RequestMetadata m);
}
