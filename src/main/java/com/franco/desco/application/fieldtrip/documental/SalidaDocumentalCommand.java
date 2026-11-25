package com.franco.desco.application.fieldtrip.documental;

public record SalidaDocumentalCommand(
        String accion,
        Long uotId,
        Long salidaId,
        Long documentoId,
        Object datos
) {
}
