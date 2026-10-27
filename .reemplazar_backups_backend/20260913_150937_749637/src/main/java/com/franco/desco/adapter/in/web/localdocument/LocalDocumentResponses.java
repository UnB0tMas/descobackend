package com.franco.desco.adapter.in.web.localdocument;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;

public final class LocalDocumentResponses {
    private LocalDocumentResponses() {}

    @Schema(name = "LocalDocumentFileResponse", description = "Metadatos de un documento o imagen almacenado localmente.")
    public record FileInfo(
            Long archivoId,
            Long uotId,
            String uotNombre,
            String nombreOriginal,
            String mimeType,
            long tamanoBytes,
            String categoria,
            String descripcion,
            @Schema(description = "Clave interna de almacenamiento. No debe tratarse como una URL pública.")
            String storageKey,
            String sha256,
            Instant fechaCarga
    ) {}
}
