package com.franco.desco.application.producer;

import com.franco.desco.application.shared.pagination.PageRequest;

import java.time.LocalDate;

public final class ProducerCommands {

    private ProducerCommands() {
    }

    public record Filter(
            String buscar,
            Long asociacionId,
            String situacion
    ) {
    }

    public record ListProducers(
            PageRequest<Filter> page
    ) {
    }

    public record GetProducer(
            Long socioId
    ) {
    }

    public record LocationInput(
            String distritoCodigo,
            Long centroPobladoId,
            String referencia
    ) {
    }

    public record CreateProducer(
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            LocalDate fechaAlta,
            Long asociacionId,
            String codigoSocio,
            LocalDate fechaDesde,
            String situacionMembresia,
            LocationInput ubicacion
    ) {
    }

    public record UpdateProducer(
            Long socioId,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            Long asociacionId,
            String codigoSocio,
            LocalDate fechaDesde,
            String situacionMembresia,
            LocationInput ubicacion
    ) {
    }

    public record RetireProducer(
            Long socioId,
            LocalDate fechaRetiro,
            String motivo
    ) {
    }
}
