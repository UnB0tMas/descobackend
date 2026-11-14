package com.franco.desco.adapter.out.persistence.planta.clinical;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface E3ClinicalOperation {
    String key();
    PersistenceResult<Object> execute(long uotId,long convenioId,long predioId,Long parcelaCultivoId,long plantaId,
       Long episodioId,Object datos,SessionIdentity identity,RequestMetadata metadata);
}
