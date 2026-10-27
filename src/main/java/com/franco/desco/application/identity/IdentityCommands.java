package com.franco.desco.application.identity;

import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.Target;

public final class IdentityCommands {

    private IdentityCommands() {
    }

    public record ResolveDocument(
            Target entidadObjetivo,
            DocumentType tipoDocumento,
            String numeroDocumento
    ) {
    }
}
