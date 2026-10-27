package com.franco.desco.adapter.in.web.resourceprogram;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

public final class ResourceProgramResponses {

    private ResourceProgramResponses() {
    }

    @Schema(name = "ResourceProgramCreatedResponse")
    public record Created(Long recursoProgramadoId) {
    }

    @Schema(name = "ResourceProgramSummaryResponse")
    public record Summary(
            Long recursoProgramadoId,
            Long campaniaVentaId,
            Long operativoVentaId,
            Long salidaCampoId,
            Long bienInventarioId,
            String bien,
            Long suministroId,
            String suministro,
            BigDecimal cantidadProgramada,
            String estadoProceso,
            Instant fechaProgramacion,
            String observacion,
            BigDecimal cantidadEjecutada,
            BigDecimal cantidadDevuelta
    ) {
    }

    @Schema(name = "ResourceProgramMovementResponse")
    public record Movement(
            Long recursoMovimientoId,
            String tipoMovimiento,
            BigDecimal cantidad,
            Instant fechaHora,
            String observacion,
            String usuario
    ) {
    }

    @Schema(name = "ResourceProgramDetailResponse")
    public record Detail(
            Long recursoProgramadoId,
            Long campaniaVentaId,
            Long operativoVentaId,
            Long salidaCampoId,
            Long bienInventarioId,
            String bien,
            String estadoBien,
            Long suministroId,
            String suministro,
            String unidadMedida,
            BigDecimal cantidadProgramada,
            String observacion,
            boolean estado,
            String estadoProceso,
            Long usuarioProgramacionId,
            Instant fechaProgramacion,
            Long usuarioCancelacionId,
            Instant fechaCancelacion,
            String motivoCancelacion,
            List<Movement> movimientos
    ) {
    }

    @Schema(name = "ResourceProgramDestinationResponse")
    public record Destination(
            String tipo,
            Long destinoId,
            Long uotId,
            String uotCodigo,
            String uotNombre,
            String codigo,
            String nombre,
            String estadoProceso,
            LocalDateTime fechaReferencia,
            String descripcion
    ) {
    }

    @Schema(name = "ResourceProgramAvailableAssetResponse")
    public record AvailableAsset(
            Long bienInventarioId,
            Long uotId,
            String uotCodigo,
            String uotNombre,
            String codigoPatrimonial,
            String nombre,
            String estadoBien,
            boolean disponible
    ) {
    }

    @Schema(name = "ResourceProgramAvailableSupplyResponse")
    public record AvailableSupply(
            Long suministroId,
            Long uotId,
            String uotCodigo,
            String uotNombre,
            String codigo,
            String nombre,
            String unidadMedida,
            BigDecimal stockActual,
            BigDecimal stockReservado,
            BigDecimal stockDisponible,
            BigDecimal stockMinimo,
            boolean requiereReposicion
    ) {
    }

    @Schema(name = "ResourceProgramAvailabilityResponse")
    public record Availability(
            List<AvailableAsset> bienes,
            List<AvailableSupply> suministros
    ) {
    }
}
