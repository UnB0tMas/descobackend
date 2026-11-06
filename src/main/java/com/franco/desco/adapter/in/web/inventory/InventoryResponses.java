package com.franco.desco.adapter.in.web.inventory;
import io.swagger.v3.oas.annotations.media.Schema;import java.math.BigDecimal;import java.time.Instant;import java.util.List;
public final class InventoryResponses{private InventoryResponses(){}
 @Schema(name="InventoryAssetSummaryResponse") public record AssetSummary(Long bienInventarioId,Long empresaId,String empresa,Long tipoBienId,String tipoBien,String codigoPatrimonial,String nombre,String marca,String modelo,String serie,String estadoBien,boolean vehiculo,String placa,String tipoVehiculo,BigDecimal kilometrajeKm){}
 public record Resource(Long recursoProgramadoId,String estadoProceso,BigDecimal cantidadProgramada,Instant fechaProgramacion,Long campaniaVentaId,Long operativoVentaId,Long salidaCampoId){}
 public record Movement(Long recursoMovimientoId,String tipoMovimiento,BigDecimal cantidad,Instant fechaHora,String observacion){}
 @Schema(name="InventoryAssetDetailResponse") public record AssetDetail(Long bienInventarioId,Long empresaId,String empresa,Long tipoBienId,String tipoBien,String codigoPatrimonial,String nombre,String marca,String modelo,String serie,String estadoBien,boolean estado,String placa,String tipoVehiculo,BigDecimal kilometrajeKm,String color,List<Resource> recursos,List<Movement> movimientos){}
 @Schema(name="SupplySummaryResponse") public record Supply(Long suministroId,String codigo,String nombre,String unidadMedida,boolean estado,BigDecimal stock){}
 public record SupplyMovement(Long suministroMovimientoId,Long suministroId,String codigo,String nombre,String unidadMedida,Long recursoProgramadoId,String tipoMovimiento,BigDecimal cantidad,Instant fechaHora,String documentoReferencia,String observacion,String usuario){}
 public record Created(Long id){}
}
