package com.franco.desco.adapter.in.web.identity;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.time.LocalDate;

public final class IdentityResponses {

    private IdentityResponses() {
    }

    @Schema(name = "IdentityResolveResponse")
    public record Resolve(
            String origen,
            boolean encontrado,
            boolean insertadoAutomaticamente,
            boolean permiteCargaManual,
            String entidadObjetivo,
            Long entidadId,
            String tipoPersona,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            String razonSocial,
            LocalDate fechaNacimiento,
            String sexo,
            Long ubicacionId,
            String departamentoCodigo,
            String departamentoNombre,
            String provinciaCodigo,
            String provinciaNombre,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referenciaUbicacion,
            Boolean estadoEntidad,
            boolean esEmpleado,
            boolean esSocio,
            boolean esAsociacion,
            String estadoConsulta,
            String direccionFiscalSugerida,
            Instant reintentoDesdeUtc
    ) {
    }
}
