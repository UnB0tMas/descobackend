package com.franco.desco.domain.resourceprogram;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

public final class ResourceProgramModels {

    private ResourceProgramModels() {
    }

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

    public record Movement(
            Long recursoMovimientoId,
            String tipoMovimiento,
            BigDecimal cantidad,
            Instant fechaHora,
            String observacion,
            String usuario
    ) {
    }

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
        public Detail {
            movimientos = movimientos == null
                    ? List.of()
                    : List.copyOf(movimientos);
        }
    }

    public record Destination(
            String type,
            Long destinationId,
            Long uotId,
            String uotCode,
            String uotName,
            String code,
            String name,
            String processState,
            LocalDateTime referenceDate,
            String description
    ) {
    }

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

    public record Availability(
            List<AvailableAsset> bienes,
            List<AvailableSupply> suministros
    ) {
        public Availability {
            bienes = bienes == null
                    ? List.of()
                    : List.copyOf(bienes);
            suministros = suministros == null
                    ? List.of()
                    : List.copyOf(suministros);
        }
    }
}
