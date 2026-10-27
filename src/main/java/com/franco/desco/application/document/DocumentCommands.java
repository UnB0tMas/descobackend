package com.franco.desco.application.document;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;
import java.time.Instant;

public final class DocumentCommands {
    private DocumentCommands() {}

    public record Filter(
            String tipoEvidencia,
            String origenCaptura,
            Long usuarioId,
            String contextoTipo,
            Long contextoId,
            Instant fechaDesde,
            Instant fechaHasta
    ) {}

    public record ListDocuments(PageRequest<Filter> page) {}
    public record GetDocument(Long archivoId) {}

    public record RegisterDocument(
            String nombreOriginal,
            String mimeType,
            String cloudinaryPublicId,
            String secureUrl,
            Long tamanoBytes,
            String tipoEvidencia,
            String categoria,
            String origenCaptura,
            String descripcion,
            Instant fechaCaptura,
            BigDecimal latitudCaptura,
            BigDecimal longitudCaptura,
            Link vinculo
    ) {}

    public record Link(
            Long predioId,
            Long salidaCampoId,
            Long visitaTecnicaId,
            Long casoFitosanitarioId,
            Long tratamientoId,
            Long entregaSocioId,
            Long incidenciaOperativaId,
            Long ajustePrecioSocioId,
            Long gastoCampaniaId,
            Long liquidacionSocioId,
            Long pagoSocioId,
            Long cobroCompradorId,
            Long socioId,
            Long empleadoId,
            Long parcelaId,
            Long parcelaCultivoId,
            Long censoPlantasId,
            Long evaluacionAgronomicaId,
            Long seguimientoFitosanitarioId,
            Long disponibilidadProduccionId,
            Long campaniaVentaId,
            Long precioComercialId,
            Long participacionCampaniaSocioId,
            Long operativoVentaId,
            Long jabaAsignacionId,
            Long jabaDevolucionId,
            Long bienInventarioId,
            Long recursoProgramadoId
    ) {}

    public record RetireDocument(Long archivoId, String motivo) {}
}
