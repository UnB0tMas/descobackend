package com.franco.desco.application.producer.port.out;

import com.franco.desco.application.producer.*;
import com.franco.desco.application.producer.ProducerCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.producer.*;
import java.util.*;

public interface ProducerPersistencePort {
    PersistenceResult<PageResult<ProducerModels.Summary>> list(ListProducers c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<ProducerModels.Detail> get(GetProducer c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Long> create(CreateProducer c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> update(UpdateProducer c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> retire(RetireProducer c, SessionIdentity i, RequestMetadata m);
}
