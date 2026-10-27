package com.franco.desco.application.census.port.out;

import com.franco.desco.application.census.*;
import com.franco.desco.application.census.CensusCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.census.*;
import java.util.*;

public interface CensusPersistencePort {
    PersistenceResult<PageResult<CensusModels.Summary>> list(ListCensuses c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(CreateCensus c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(UpdateCensus c,SessionIdentity i,RequestMetadata m);
}
