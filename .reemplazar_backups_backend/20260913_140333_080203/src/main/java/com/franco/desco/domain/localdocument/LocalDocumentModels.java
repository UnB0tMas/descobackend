package com.franco.desco.domain.localdocument;

import java.time.Instant;

public final class LocalDocumentModels {
    private LocalDocumentModels() {}

    public record FileInfo(
            Long fileId,
            Long uotId,
            String uotName,
            String originalName,
            String contentType,
            long size,
            String category,
            String description,
            String storageKey,
            String sha256,
            Instant uploadedAt
    ) {}
}
