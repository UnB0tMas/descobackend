package com.franco.desco.adapter.in.web.producer;

import com.franco.desco.application.producer.ProducerCommands;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.producer.ProducerModels;
import org.springframework.stereotype.Component;

@Component
public class ProducerWebMapper {

    public ProducerCommands.ListProducers list(
            int pagina,
            int tamano,
            String buscar,
            Long asociacionId,
            String situacion
    ) {
        return new ProducerCommands.ListProducers(
                new PageRequest<>(
                        pagina,
                        tamano,
                        new ProducerCommands.Filter(
                                buscar,
                                asociacionId,
                                situacion
                        ),
                        null,
                        null
                )
        );
    }

    public ProducerCommands.CreateProducer command(
            ProducerRequests.Create request
    ) {
        return new ProducerCommands.CreateProducer(
                request.tipoDocumento(),
                request.numeroDocumento(),
                request.nombres(),
                request.apellidoPaterno(),
                request.apellidoMaterno(),
                request.telefono(),
                request.correo(),
                request.fechaNacimiento(),
                request.fechaAlta(),
                request.asociacionId(),
                null, // código generado por SQL Server
                request.fechaDesde(),
                request.situacionMembresia(),
                location(request.ubicacion())
        );
    }

    public ProducerCommands.UpdateProducer command(
            Long socioId,
            ProducerRequests.Update request
    ) {
        return new ProducerCommands.UpdateProducer(
                socioId,
                request.tipoDocumento(),
                request.numeroDocumento(),
                request.nombres(),
                request.apellidoPaterno(),
                request.apellidoMaterno(),
                request.telefono(),
                request.correo(),
                request.fechaNacimiento(),
                request.asociacionId(),
                null, // código generado por SQL Server
                request.fechaDesde(),
                request.situacionMembresia(),
                location(request.ubicacion())
        );
    }

    public ProducerResponses.Summary response(
            ProducerModels.Summary value
    ) {
        return new ProducerResponses.Summary(
                value.socioId(),
                value.tipoDocumento(),
                value.numeroDocumento(),
                value.nombres(),
                value.apellidoPaterno(),
                value.apellidoMaterno(),
                value.telefono(),
                value.correo(),
                value.fechaAlta(),
                value.estado(),
                value.socioAsociacionId(),
                value.asociacionId(),
                value.codigoSocio(),
                value.situacionMembresia(),
                value.asociacionNombre()
        );
    }

    public ProducerResponses.Detail response(
            ProducerModels.Detail value
    ) {
        return new ProducerResponses.Detail(
                value.socioId(),
                value.tipoDocumento(),
                value.numeroDocumento(),
                value.nombres(),
                value.apellidoPaterno(),
                value.apellidoMaterno(),
                value.telefono(),
                value.correo(),
                value.fechaNacimiento(),
                value.fechaAlta(),
                value.estado(),
                value.distritoCodigo(),
                value.distritoNombre(),
                value.centroPobladoId(),
                value.centroPobladoNombre(),
                value.referencia(),
                value.afiliaciones()
                        .stream()
                        .map(item ->
                                new ProducerResponses.Membership(
                                        item.socioAsociacionId(),
                                        item.asociacionId(),
                                        item.asociacionNombre(),
                                        item.codigoSocio(),
                                        item.fechaDesde(),
                                        item.fechaHasta(),
                                        item.situacionMembresia(),
                                        item.estado()
                                )
                        )
                        .toList(),
                value.predios()
                        .stream()
                        .map(item ->
                                new ProducerResponses.Property(
                                        item.predioId(),
                                        item.codigo(),
                                        item.nombre(),
                                        item.fechaRegistro(),
                                        item.estado(),
                                        item.tipoTitularidad(),
                                        item.porcentaje(),
                                        item.fechaDesde(),
                                        item.fechaHasta()
                                )
                        )
                        .toList(),
                value.campanias()
                        .stream()
                        .map(item ->
                                new ProducerResponses.Campaign(
                                        item.participacionCampaniaSocioId(),
                                        item.campaniaVentaId(),
                                        item.codigo(),
                                        item.nombre(),
                                        item.fechaInicio(),
                                        item.fechaFin(),
                                        item.estadoProceso(),
                                        item.estadoParticipacion(),
                                        item.fechaRegistro()
                                )
                        )
                        .toList()
        );
    }

    private ProducerCommands.LocationInput location(
            ProducerRequests.Location location
    ) {
        return new ProducerCommands.LocationInput(
                location.distritoCodigo(),
                location.centroPobladoId(),
                location.referencia()
        );
    }
}
