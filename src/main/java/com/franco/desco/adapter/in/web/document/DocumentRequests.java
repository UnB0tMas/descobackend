package com.franco.desco.adapter.in.web.document;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.Instant;

public final class DocumentRequests {
    private DocumentRequests() {}

    @Schema(name = "DocumentRegisterRequest")
    public record Register(
            @NotBlank @Size(max = 260) String nombreOriginal,
            @NotBlank @Size(max = 150) String mimeType,
            @NotBlank @Size(max = 300) String cloudinaryPublicId,
            @NotBlank @Size(max = 1200) String secureUrl,
            @NotNull @PositiveOrZero Long tamanoBytes,
            @NotBlank @Size(max = 50) String tipoEvidencia,
            @Size(max = 80) String categoria,
            @NotBlank @Size(max = 40) String origenCaptura,
            @Size(max = 1000) String descripcion,
            Instant fechaCaptura,
            BigDecimal latitudCaptura,
            BigDecimal longitudCaptura,
            @NotNull @Valid Link vinculo
    ) {}

    @Schema(name = "DocumentLinkRequest")
    public record Link(
            Long predioId, Long salidaCampoId, Long visitaTecnicaId, Long casoFitosanitarioId,
            Long tratamientoId, Long entregaSocioId, Long incidenciaOperativaId, Long ajustePrecioSocioId,
            Long gastoCampaniaId, Long liquidacionSocioId, Long pagoSocioId, Long cobroCompradorId,
            Long socioId, Long empleadoId, Long parcelaId, Long parcelaCultivoId, Long censoPlantasId,
            Long evaluacionAgronomicaId, Long seguimientoFitosanitarioId, Long disponibilidadProduccionId,
            Long campaniaVentaId, Long precioComercialId, Long participacionCampaniaSocioId,
            Long operativoVentaId, Long jabaAsignacionId, Long jabaDevolucionId,
            Long bienInventarioId, Long recursoProgramadoId
    ) {}

    @Schema(name = "DocumentRetireRequest")
    public record Retire(@NotBlank @Size(max = 300) String motivo) {}
}
