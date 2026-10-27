package com.franco.desco.application.producer.port.in;

import com.franco.desco.application.producer.ProducerCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.producer.ProducerModels;

public interface ProducerUseCase {
    AppResult<PageResult<ProducerModels.Summary>> list(ListProducers command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<ProducerModels.Detail> get(GetProducer command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(CreateProducer command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> update(UpdateProducer command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> retire(RetireProducer command, SessionIdentity identity, RequestMetadata metadata);
}
