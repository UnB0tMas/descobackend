package com.franco.desco.adapter.in.web.supply;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;

public final class SupplyResponses {
    private SupplyResponses() {}
    @Schema(name="SupplySummaryResponse")
    public record Summary(Long suministroId,Long uotId,String uotCodigo,String uotNombre,String codigo,String nombre,String unidadMedida,boolean estado,BigDecimal stock,BigDecimal stockActual,BigDecimal stockReservado,BigDecimal stockDisponible,BigDecimal stockMinimo,boolean requiereReposicion){}
    @Schema(name="SupplyMovementResponse")
    public record Movement(Long suministroMovimientoId,Long suministroId,Long uotId,String uotCodigo,String uotNombre,String codigo,String nombre,String unidadMedida,Long recursoProgramadoId,String tipoMovimiento,BigDecimal cantidad,Instant fechaHora,String documentoReferencia,String observacion,String usuario,BigDecimal saldo){}
    @Schema(name="SupplyCreatedResponse") public record Created(Long suministroId){}
    @Schema(name="SupplyMovementCreatedResponse") public record MovementCreated(Long suministroMovimientoId){}
}
