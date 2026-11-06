package com.franco.desco.application.e4;

public final class E4Commands {
    private E4Commands() {}
    public record Execute(String accion, Long campaniaId, Long operativoSocioId,
                          Long asignacionId, Long unidadId, Long entregaId, Object datos) {}
}
