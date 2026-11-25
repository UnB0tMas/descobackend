package com.franco.desco.application.fieldtrip.personal;

public record SalidaPersonalQuery(String accion, Long uotId, Long salidaId,
        String buscar, String estado, Integer pagina, Integer tamano) {}
