package com.franco.desco.application.producer.port.out;

import com.franco.desco.application.producer.ProducerCommands.CreateProducer;
import com.franco.desco.application.producer.ProducerCommands.GetProducer;
import com.franco.desco.application.producer.ProducerCommands.ListProducers;
import com.franco.desco.application.producer.ProducerCommands.RetireProducer;
import com.franco.desco.application.producer.ProducerCommands.UpdateProducer;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.producer.ProducerModels;

public interface ProducerPersistencePort {

    PersistenceResult<PageResult<ProducerModels.Summary>> list(
            ListProducers command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<ProducerModels.Detail> get(
            GetProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Long> create(
            CreateProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> update(
            UpdateProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> retire(
            RetireProducer command,
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
