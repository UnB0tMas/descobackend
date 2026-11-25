package com.franco.desco.application.report.port.out;

import java.util.UUID;

/** Resuelve el ámbito autorizado de una sesión sin confiar en parámetros del cliente. */
public interface ReportJobEventScopePort {
    Long findSpecificUot(long usuarioId, UUID sesionPublicaId);
}
