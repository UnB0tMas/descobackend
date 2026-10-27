package com.franco.desco.adapter.in.web.producer;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ProducerResponses {

    private ProducerResponses() {
    }

    @Schema(name = "ProducerSummaryResponse")
    public record Summary(
            Long socioId,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaAlta,
            boolean estado,
            Long socioAsociacionId,
            Long asociacionId,
            String codigoSocio,
            String situacionMembresia,
            String asociacionNombre
    ) {
    }

    public record Membership(
            Long socioAsociacionId,
            Long asociacionId,
            String asociacionNombre,
            String codigoSocio,
            LocalDate fechaDesde,
            LocalDate fechaHasta,
            String situacionMembresia,
            boolean estado
    ) {
    }

    public record Property(
            Long predioId,
            String codigo,
            String nombre,
            LocalDate fechaRegistro,
            boolean estado,
            String tipoTitularidad,
            BigDecimal porcentaje,
            LocalDate fechaDesde,
            LocalDate fechaHasta
    ) {
    }

    public record Campaign(
            Long participacionCampaniaSocioId,
            Long campaniaVentaId,
            String codigo,
            String nombre,
            LocalDate fechaInicio,
            LocalDate fechaFin,
            String estadoProceso,
            String estadoParticipacion,
            LocalDate fechaRegistro
    ) {
    }

    @Schema(name = "ProducerDetailResponse")
    public record Detail(
            Long socioId,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            LocalDate fechaAlta,
            boolean estado,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referencia,
            List<Membership> afiliaciones,
            List<Property> predios,
            List<Campaign> campanias
    ) {
    }

    public record Created(
            Long socioId
    ) {
    }
}
