package com.franco.desco.application.fieldtrip.port.in;
import com.franco.desco.application.fieldtrip.FieldTripCommands;import com.franco.desco.application.shared.*;import com.franco.desco.application.shared.pagination.PageResult;import com.franco.desco.domain.fieldtrip.FieldTripModels;
public interface FieldTripUseCase{
 AppResult<PageResult<FieldTripModels.Summary>> list(FieldTripCommands.ListTrips c,SessionIdentity i,RequestMetadata m);AppResult<FieldTripModels.Detail> get(FieldTripCommands.GetTrip c,SessionIdentity i,RequestMetadata m);AppResult<Long> program(FieldTripCommands.Program c,SessionIdentity i,RequestMetadata m);AppResult<Void> update(FieldTripCommands.Update c,SessionIdentity i,RequestMetadata m);AppResult<Void> cancel(FieldTripCommands.Cancel c,SessionIdentity i,RequestMetadata m);AppResult<Void> finish(FieldTripCommands.Finish c,SessionIdentity i,RequestMetadata m);
}
