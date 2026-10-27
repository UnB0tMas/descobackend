package com.franco.desco.adapter.in.web.resourceprogram;

import com.franco.desco.application.resourceprogram.ResourceProgramCommands;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.resourceprogram.ResourceProgramModels;
import org.springframework.stereotype.Component;

@Component
public class ResourceProgramWebMapper {

    public ResourceProgramCommands.ListResources list(
            int page,
            int size,
            String state,
            Long campaignId,
            Long operationId,
            Long fieldTripId
    ) {
        return new ResourceProgramCommands.ListResources(
                new PageRequest<>(
                        page,
                        size,
                        new ResourceProgramCommands.Filter(
                                state,
                                campaignId,
                                operationId,
                                fieldTripId
                        ),
                        null,
                        null
                )
        );
    }

    public ResourceProgramResponses.Summary response(
            ResourceProgramModels.Summary value
    ) {
        return new ResourceProgramResponses.Summary(
                value.recursoProgramadoId(),
                value.campaniaVentaId(),
                value.operativoVentaId(),
                value.salidaCampoId(),
                value.bienInventarioId(),
                value.bien(),
                value.suministroId(),
                value.suministro(),
                value.cantidadProgramada(),
                value.estadoProceso(),
                value.fechaProgramacion(),
                value.observacion(),
                value.cantidadEjecutada(),
                value.cantidadDevuelta()
        );
    }

    public ResourceProgramResponses.Detail response(
            ResourceProgramModels.Detail value
    ) {
        return new ResourceProgramResponses.Detail(
                value.recursoProgramadoId(),
                value.campaniaVentaId(),
                value.operativoVentaId(),
                value.salidaCampoId(),
                value.bienInventarioId(),
                value.bien(),
                value.estadoBien(),
                value.suministroId(),
                value.suministro(),
                value.unidadMedida(),
                value.cantidadProgramada(),
                value.observacion(),
                value.estado(),
                value.estadoProceso(),
                value.usuarioProgramacionId(),
                value.fechaProgramacion(),
                value.usuarioCancelacionId(),
                value.fechaCancelacion(),
                value.motivoCancelacion(),
                value.movimientos().stream()
                        .map(movement -> new ResourceProgramResponses.Movement(
                                movement.recursoMovimientoId(),
                                movement.tipoMovimiento(),
                                movement.cantidad(),
                                movement.fechaHora(),
                                movement.observacion(),
                                movement.usuario()
                        ))
                        .toList()
        );
    }

    public ResourceProgramResponses.Destination response(
            ResourceProgramModels.Destination value
    ) {
        return new ResourceProgramResponses.Destination(
                value.type(),
                value.destinationId(),
                value.uotId(),
                value.uotCode(),
                value.uotName(),
                value.code(),
                value.name(),
                value.processState(),
                value.referenceDate(),
                value.description()
        );
    }

    public ResourceProgramResponses.Availability response(
            ResourceProgramModels.Availability value
    ) {
        return new ResourceProgramResponses.Availability(
                value.bienes().stream()
                        .map(asset -> new ResourceProgramResponses.AvailableAsset(
                                asset.bienInventarioId(),
                                asset.uotId(),
                                asset.uotCodigo(),
                                asset.uotNombre(),
                                asset.codigoPatrimonial(),
                                asset.nombre(),
                                asset.estadoBien(),
                                asset.disponible()
                        ))
                        .toList(),
                value.suministros().stream()
                        .map(supply -> new ResourceProgramResponses.AvailableSupply(
                                supply.suministroId(),
                                supply.uotId(),
                                supply.uotCodigo(),
                                supply.uotNombre(),
                                supply.codigo(),
                                supply.nombre(),
                                supply.unidadMedida(),
                                supply.stockActual(),
                                supply.stockReservado(),
                                supply.stockDisponible(),
                                supply.stockMinimo(),
                                supply.requiereReposicion()
                        ))
                        .toList()
        );
    }
}
