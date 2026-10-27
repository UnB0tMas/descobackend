package com.franco.desco.adapter.out.sqlserver.property;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.property.*;
import com.franco.desco.application.property.PropertyCommands.*;
import com.franco.desco.application.property.port.out.PropertyPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.property.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class PropertySqlServerAdapter
        extends JsonPaAdapterSupport
        implements PropertyPersistencePort {

    public PropertySqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<PropertyModels.Summary>> list(ListProperties c,SessionIdentity i,RequestMetadata m) {
        return page("prod.PA_Predio_Sel_Listado", c, i, m, PropertyModels.Summary.class);
    }

    @Override
    public PersistenceResult<PropertyModels.Detail> get(GetProperty c,SessionIdentity i,RequestMetadata m) {
        return one("prod.PA_Predio_Sel_DetalleCompleto", c, i, m, PropertyModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(CreateProperty c,SessionIdentity i,RequestMetadata m) {
        return create("prod.PA_Predio_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(UpdateProperty c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_Predio_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> retire(RetireProperty c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_Predio_Del_Registro", c, i, m);
    }

}
