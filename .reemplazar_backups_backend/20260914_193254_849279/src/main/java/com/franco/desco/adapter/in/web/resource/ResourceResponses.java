package com.franco.desco.adapter.in.web.resource;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class ResourceResponses {

    private ResourceResponses() {
    }

    @Schema(name = "ResourceAssetResponse")
    public record Asset(
            Long bienInventarioId,
            Long uotId,
            String uotCodigo,
            String uotNombre,
            Integer tipoBienId,
            String tipoBien,
            String codigoPatrimonial,
            String nombre,
            String marca,
            String modelo,
            String serie,
            String estadoBien,
            LocalDate fechaAdquisicion,
            BigDecimal montoAdquisicion,
            String monedaAdquisicion,
            Long proveedorPersonaId,
            Long proveedorEmpresaId,
            String observacion,
            Long archivoPrincipalId,
            int incidentesAbiertos,
            boolean estado
    ) {
    }

    @Schema(name = "ResourceAssetHistoryResponse")
    public record AssetHistory(
            Long bienEstadoHistorialId,
            String estadoBien,
            LocalDateTime fechaDesde,
            LocalDateTime fechaHasta,
            String motivo,
            Long usuarioId
    ) {
    }

    @Schema(name = "ResourceAssetIncidentResponse")
    public record AssetIncident(
            Long bienIncidenteId,
            String tipoIncidente,
            LocalDateTime fechaHora,
            String descripcion,
            BigDecimal costoEstimado,
            BigDecimal costoReal,
            String estadoIncidente,
            Long usuarioReportaId,
            LocalDateTime fechaCierre,
            String solucion
    ) {
    }

    @Schema(name = "ResourceAssetDetailResponse")
    public record AssetDetail(
            Asset bien,
            List<AssetHistory> historial,
            List<AssetIncident> incidentes,
            List<Long> archivosImagen
    ) {
    }

    @Schema(name = "ResourceProductResponse")
    public record Product(
            Long productoId,
            String codigo,
            String nombre,
            String descripcion,
            String unidadMedida,
            String categoria,
            boolean requiereLote,
            boolean controlaVencimiento,
            BigDecimal precioVenta,
            String moneda,
            Long productoPrecioId,
            Long archivoPrincipalId,
            boolean estado
    ) {
    }

    @Schema(name = "ResourceProductPriceHistoryResponse")
    public record PriceHistory(
            Long productoPrecioId,
            Long productoId,
            String productoCodigo,
            String producto,
            Long uotId,
            String uotCodigo,
            String uotNombre,
            BigDecimal precioVenta,
            String moneda,
            Integer version,
            LocalDateTime fechaDesde,
            LocalDateTime fechaHasta,
            boolean vigente,
            Long usuarioId,
            String nombreUsuario
    ) {
    }

    @Schema(name = "ResourceWarehouseResponse")
    public record Warehouse(
            Long almacenId,
            Long uotPropietariaId,
            String uotPropietaria,
            Long ubicacionId,
            String codigo,
            String nombre,
            String descripcion,
            String tipoAcceso,
            boolean permiteEntrada,
            boolean permiteSalida,
            boolean estado
    ) {
    }

    @Schema(name = "ResourceStockResponse")
    public record Stock(
            Long almacenId,
            String almacen,
            Long productoId,
            String producto,
            String unidadMedida,
            BigDecimal stockActual,
            BigDecimal stockReservado,
            BigDecimal stockDisponible,
            BigDecimal stockMinimo,
            LocalDateTime fechaActualizacion
    ) {
    }

    @Schema(name = "ResourceKardexResponse")
    public record Kardex(
            Long movimientoInventarioId,
            LocalDateTime fechaHora,
            Long uotId,
            String uotNombre,
            Long almacenId,
            String almacen,
            String tipoMovimiento,
            String naturaleza,
            String documentoReferencia,
            Long productoId,
            String producto,
            BigDecimal cantidad,
            BigDecimal costoUnitario,
            String moneda,
            String lote,
            LocalDate fechaVencimiento,
            Long usuarioId,
            String observacion
    ) {
    }

    @Schema(name = "ResourceCodeSuggestionResponse")
    public record CodeSuggestion(
            Long uotId,
            String tipo,
            String codigo
    ) {
    }

    @Schema(name = "ResourceWarehouseProductConfiguredResponse")
    public record WarehouseProductConfigured(
            Long almacenId,
            Long productoId,
            Long movimientoInventarioId,
            BigDecimal stockActual,
            BigDecimal stockMinimo
    ) {
    }

    @Schema(name = "ResourceAssetCreatedResponse")
    public record AssetCreated(Long bienInventarioId) {
    }

    @Schema(name = "ResourceAssetIncidentCreatedResponse")
    public record IncidentCreated(Long bienIncidenteId) {
    }

    @Schema(name = "ResourceProductCreatedResponse")
    public record ProductCreated(Long productoId) {
    }

    @Schema(name = "ResourceProductPriceCreatedResponse")
    public record PriceCreated(Long productoPrecioId) {
    }

    @Schema(name = "ResourceWarehouseCreatedResponse")
    public record WarehouseCreated(Long almacenId) {
    }

    @Schema(name = "ResourceMovementCreatedResponse")
    public record MovementCreated(Long movimientoInventarioId) {
    }
}
