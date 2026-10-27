package com.franco.desco.application.property.service;

import com.franco.desco.application.property.PropertyCommands.*;
import com.franco.desco.application.property.port.in.PropertyUseCase;
import com.franco.desco.application.property.port.out.PropertyPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.property.PropertyModels;

public final class PropertyApplicationService implements PropertyUseCase {
    private final PropertyPersistencePort persistence;
    public PropertyApplicationService(PropertyPersistencePort persistence){this.persistence=persistence;}
    public AppResult<PageResult<PropertyModels.Summary>> list(ListProperties c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(persistence.list(c,i,m),"PREDIOS_LISTADOS","PREDIOS_NO_LISTADOS",AppStatus.BAD_REQUEST);}
    public AppResult<PropertyModels.Detail> get(GetProperty c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(persistence.get(c,i,m),"PREDIO_OBTENIDO","PREDIO_NO_DISPONIBLE",AppStatus.NOT_FOUND);}
    public AppResult<Long> create(CreateProperty c,SessionIdentity i,RequestMetadata m){return ApplicationResults.created(persistence.create(c,i,m),"PREDIO_CREADO","PREDIO_NO_CREADO");}
    public AppResult<Void> update(UpdateProperty c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(persistence.update(c,i,m),"PREDIO_ACTUALIZADO","PREDIO_NO_ACTUALIZADO",AppStatus.BAD_REQUEST);}
    public AppResult<Void> retire(RetireProperty c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(persistence.retire(c,i,m),"PREDIO_RETIRADO","PREDIO_NO_RETIRADO",AppStatus.BAD_REQUEST);}
}
