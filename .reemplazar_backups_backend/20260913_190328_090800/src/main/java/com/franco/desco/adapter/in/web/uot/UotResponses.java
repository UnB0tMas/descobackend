package com.franco.desco.adapter.in.web.uot;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.util.List;

public final class UotResponses {
    private UotResponses() {}
    @Schema(name="UotUnitResponse")
    public record Unit(Long uotId,Long uotPadreId,Long ubicacionId,String codigo,String nombre,String descripcion,boolean esRaiz,LocalDate fechaInicio,LocalDate fechaFin,boolean estado,boolean asignada,boolean predeterminada){}
    @Schema(name="UotMembershipResponse",description="Membresía con roles efectivos exclusivamente de esta UOT.")
    public record Membership(Long usuarioUotId,Long uotId,String codigo,String nombre,boolean predeterminada,List<String> roles){}
    @Schema(name="UotContextResponse")
    public record Context(@Schema(allowableValues={"ESPECIFICA","GENERAL"}) String modo,Long uotSeleccionadaId,boolean requiereSeleccion,boolean permiteModoGeneral,List<Membership> uots){}
    @Schema(name="UotCreatedResponse") public record Created(Long uotId){}
    @Schema(name="UotDeactivationImpactResponse")
    public record DeactivationImpact(Long uotId,int uotIncluidas,int usuariosActivos,int usuariosExclusivos,int empleadosActivos,int areasActivas,int organizacionesActivas,int prediosActivos,int almacenesActivos,int productosConStock,int stockReservado,int suministrosConStock,int suministrosReservados,int bienesActivos,int ventasAbiertas,int campaniasAbiertas,int operativosAbiertos,int salidasAbiertas,int recursosAbiertos,boolean puedeDeshabilitar,List<String> bloqueos){}
    @Schema(name="UotResourceTransferResponse")
    public record ResourceTransfer(Long movimientoSalidaId,Long movimientoEntradaId,int productosTransferidos,int bienesTransferidos,int suministrosTransferidos){}
}
