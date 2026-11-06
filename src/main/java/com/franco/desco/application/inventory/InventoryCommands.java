package com.franco.desco.application.inventory;

import com.franco.desco.application.shared.pagination.PageRequest;

import java.math.BigDecimal;

public final class InventoryCommands {

    private InventoryCommands() {
    }

    public record AssetFilter(
            Long empresaId,
            Long tipoBienId,
            String estadoBien
    ) {
    }

    public record ListAssets(
            PageRequest<AssetFilter> page
    ) {
    }

    public record GetAsset(
            Long bienInventarioId
    ) {
    }

    public record CreateAsset(
            Long empresaId,
            Long tipoBienId,
            String codigoPatrimonial,
            String nombre,
            String marca,
            String modelo,
            String serie
    ) {
    }

    public record UpdateAsset(
            Long bienInventarioId,
            String nombre,
            String marca,
            String modelo,
            String serie,
            String estadoBien
    ) {
    }

    public record RetireAsset(
            Long bienInventarioId,
            String motivo
    ) {
    }

    public record RegisterVehicle(
            Long bienInventarioId,
            String placa,
            String tipoVehiculo,
            BigDecimal kilometrajeKm,
            String color
    ) {
    }

    public record UpdateMileage(
            Long vehiculoId,
            BigDecimal kilometrajeKm
    ) {
    }

    public record ListSupplies(
            PageRequest<Void> page
    ) {
    }

    public record CreateSupply(
            String codigo,
            String nombre,
            String unidadMedida,
            BigDecimal stockInicial
    ) {
    }

    public record UpdateSupply(
            Long suministroId,
            String nombre,
            String unidadMedida
    ) {
    }

    public record ListSupplyMovements(
            Long suministroId
    ) {
    }

    public record AdjustSupply(
            Long suministroId,
            String tipoMovimiento,
            BigDecimal cantidad,
            String documentoReferencia,
            String observacion
    ) {
    }

    public record AnnulSupplyMovement(
            Long suministroMovimientoId,
            String motivo
    ) {
    }
}
