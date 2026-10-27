package com.franco.desco.adapter.in.web.document;

import com.franco.desco.application.document.DocumentCommands;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.document.DocumentModels;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class DocumentWebMapper {

    public DocumentCommands.ListDocuments list(int page, int size, String tipoEvidencia, String origenCaptura,
                                                Long usuarioId, String contextoTipo, Long contextoId,
                                                Instant fechaDesde, Instant fechaHasta) {
        return new DocumentCommands.ListDocuments(new PageRequest<>(page, size,
                new DocumentCommands.Filter(tipoEvidencia, origenCaptura, usuarioId, contextoTipo, contextoId, fechaDesde, fechaHasta),
                null, null));
    }

    public DocumentCommands.RegisterDocument command(DocumentRequests.Register r) {
        DocumentRequests.Link v = r.vinculo();
        return new DocumentCommands.RegisterDocument(
                r.nombreOriginal(), r.mimeType(), r.cloudinaryPublicId(), r.secureUrl(), r.tamanoBytes(),
                r.tipoEvidencia(), r.categoria(), r.origenCaptura(), r.descripcion(), r.fechaCaptura(),
                r.latitudCaptura(), r.longitudCaptura(),
                new DocumentCommands.Link(v.predioId(), v.salidaCampoId(), v.visitaTecnicaId(), v.casoFitosanitarioId(),
                        v.tratamientoId(), v.entregaSocioId(), v.incidenciaOperativaId(), v.ajustePrecioSocioId(),
                        v.gastoCampaniaId(), v.liquidacionSocioId(), v.pagoSocioId(), v.cobroCompradorId(),
                        v.socioId(), v.empleadoId(), v.parcelaId(), v.parcelaCultivoId(), v.censoPlantasId(),
                        v.evaluacionAgronomicaId(), v.seguimientoFitosanitarioId(), v.disponibilidadProduccionId(),
                        v.campaniaVentaId(), v.precioComercialId(), v.participacionCampaniaSocioId(), v.operativoVentaId(),
                        v.jabaAsignacionId(), v.jabaDevolucionId(), v.bienInventarioId(), v.recursoProgramadoId())
        );
    }

    public DocumentResponses.Summary response(DocumentModels.Summary v) {
        return new DocumentResponses.Summary(v.archivoId(), v.nombreOriginal(), v.mimeType(), v.secureUrl(), v.tamanoBytes(),
                v.categoria(), v.tipoEvidencia(), v.origenCaptura(), v.descripcion(), v.fechaCaptura(), v.latitudCaptura(),
                v.longitudCaptura(), v.fechaCarga(), v.usuarioId(), v.nombreUsuario(), v.tipoContexto(), v.contextoId());
    }

    public DocumentResponses.Detail response(DocumentModels.Detail v) {
        return new DocumentResponses.Detail(v.archivoId(), v.nombreOriginal(), v.mimeType(), v.cloudinaryPublicId(), v.secureUrl(),
                v.tamanoBytes(), v.categoria(), v.tipoEvidencia(), v.origenCaptura(), v.descripcion(), v.fechaCaptura(),
                v.latitudCaptura(), v.longitudCaptura(), v.fechaCarga(), v.usuarioId(), v.nombreUsuario(),
                v.vinculos().stream().map(x -> new DocumentResponses.Link(x.archivoVinculoId(), x.tipoContexto(), x.contextoId())).toList());
    }
}
