package com.franco.desco.adapter.in.web.localdocument;

import com.franco.desco.domain.localdocument.LocalDocumentModels;
import org.springframework.stereotype.Component;

@Component
public class LocalDocumentWebMapper {
    public LocalDocumentResponses.FileInfo response(LocalDocumentModels.FileInfo value) {
        return new LocalDocumentResponses.FileInfo(
                value.fileId(), value.uotId(), value.uotName(), value.originalName(), value.contentType(),
                value.size(), value.category(), value.description(), value.storageKey(), value.sha256(), value.uploadedAt()
        );
    }
}
