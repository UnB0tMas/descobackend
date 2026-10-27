package com.franco.desco.application.cultivation.port.out;

import com.franco.desco.application.cultivation.*;
import com.franco.desco.application.cultivation.CultivationCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.cultivation.*;
import java.util.*;

public interface CultivationPersistencePort {
    PersistenceResult<PageResult<CultivationModels.Summary>> list(ListCultivations c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<CultivationModels.Detail> get(GetCultivation c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> createPlot(CreatePlot c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> updatePlot(UpdatePlot c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> createCrop(CreateCrop c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> updateCrop(UpdateCrop c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> finishCrop(FinishCrop c,SessionIdentity i,RequestMetadata m);
}
