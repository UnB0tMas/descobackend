package com.franco.desco.application.e5;

public final class E5Commands {
    private E5Commands() {}
    public record Execute(String accion, Long campaniaId, Long gastoId, Long participacionId,
                          Long liquidacionId, Long pagoId, Object datos) {}
}
