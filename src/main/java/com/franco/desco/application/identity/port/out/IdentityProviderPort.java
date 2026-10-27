package com.franco.desco.application.identity.port.out;

import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;

public interface IdentityProviderPort {
    ProviderResult query(
            DocumentType documentType,
            String documentNumber
    );
}
