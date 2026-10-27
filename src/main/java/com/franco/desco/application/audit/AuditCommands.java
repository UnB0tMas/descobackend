package com.franco.desco.application.audit;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.time.LocalDate;

public final class AuditCommands {
    private AuditCommands() {}

    public record Filter(LocalDate fechaDesde,LocalDate fechaHasta,Long usuarioId,Integer moduloId,String accion,String esquemaEntidad,String nombreEntidad,String resultado) {}
    public record ListAudit(PageRequest<Filter> page) {}
    public record GetAudit(Long auditoriaEventoId) {}
    public record ExportAudit(Filter filtros) {}
}
