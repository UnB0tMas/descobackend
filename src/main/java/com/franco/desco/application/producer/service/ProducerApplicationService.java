package com.franco.desco.application.producer.service;

import com.franco.desco.application.producer.ProducerCommands.*;
import com.franco.desco.application.producer.port.in.ProducerUseCase;
import com.franco.desco.application.producer.port.out.ProducerPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.producer.ProducerModels;

public final class ProducerApplicationService implements ProducerUseCase {
    private final ProducerPersistencePort persistence;
    public ProducerApplicationService(ProducerPersistencePort persistence) { this.persistence = persistence; }
    public AppResult<PageResult<ProducerModels.Summary>> list(ListProducers c, SessionIdentity i, RequestMetadata m) { return ApplicationResults.ok(persistence.list(c,i,m),"PRODUCTORES_LISTADOS","PRODUCTORES_NO_LISTADOS",AppStatus.BAD_REQUEST); }
    public AppResult<ProducerModels.Detail> get(GetProducer c, SessionIdentity i, RequestMetadata m) { return ApplicationResults.ok(persistence.get(c,i,m),"PRODUCTOR_OBTENIDO","PRODUCTOR_NO_DISPONIBLE",AppStatus.NOT_FOUND); }
    public AppResult<Long> create(CreateProducer c, SessionIdentity i, RequestMetadata m) { return ApplicationResults.created(persistence.create(c,i,m),"PRODUCTOR_CREADO","PRODUCTOR_NO_CREADO"); }
    public AppResult<Void> update(UpdateProducer c, SessionIdentity i, RequestMetadata m) { return ApplicationResults.ok(persistence.update(c,i,m),"PRODUCTOR_ACTUALIZADO","PRODUCTOR_NO_ACTUALIZADO",AppStatus.BAD_REQUEST); }
    public AppResult<Void> retire(RetireProducer c, SessionIdentity i, RequestMetadata m) { return ApplicationResults.ok(persistence.retire(c,i,m),"PRODUCTOR_RETIRADO","PRODUCTOR_NO_RETIRADO",AppStatus.BAD_REQUEST); }
}
