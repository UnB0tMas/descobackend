package com.franco.desco.application.caja;

public interface CajaArqueoRepository {
    CajaArqueoResult ejecutar(String accion, long usuarioId, long uotId, long sesionId,
                              java.math.BigDecimal declarado, String observacion);
    record CajaArqueoResult(boolean exitoso, String codigo, String mensaje, int http, String json) {}
}
