package com.franco.desco.domain.inventory;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class InventoryModels {
    private InventoryModels() {}

    public record AssetSummary(
            Long bienInventarioId, Long empresaId, String empresa, Long tipoBienId, String tipoBien,
            String codigoPatrimonial, String nombre, String marca, String modelo, String serie,
            String estadoBien, boolean vehiculo, String placa, String tipoVehiculo, BigDecimal kilometrajeKm
    ) {}

    public record Resource(
            Long recursoProgramadoId, String estadoProceso, BigDecimal cantidadProgramada,
            Instant fechaProgramacion, Long campaniaVentaId, Long operativoVentaId, Long salidaCampoId
    ) {}

    public record Movement(
            Long recursoMovimientoId, String tipoMovimiento, BigDecimal cantidad, Instant fechaHora, String observacion
    ) {}

    public record AssetDetail(
            Long bienInventarioId, Long empresaId, String empresa, Long tipoBienId, String tipoBien,
            String codigoPatrimonial, String nombre, String marca, String modelo, String serie,
            String estadoBien, boolean estado, String placa, String tipoVehiculo, BigDecimal kilometrajeKm,
            List<Resource> recursos, List<Movement> movimientos
    ) {
        public AssetDetail {
            recursos = recursos == null ? List.of() : List.copyOf(recursos);
            movimientos = movimientos == null ? List.of() : List.copyOf(movimientos);
        }
    }

    public record Supply(
            Long suministroId, String codigo, String nombre, String unidadMedida, boolean estado, BigDecimal stock
    ) {}

    public record SupplyMovement(
            Long suministroMovimientoId, Long suministroId, String codigo, String nombre, String unidadMedida,
            Long recursoProgramadoId, String tipoMovimiento, BigDecimal cantidad, Instant fechaHora,
            String documentoReferencia, String observacion, String usuario
    ) {}
}
