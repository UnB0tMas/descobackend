package com.franco.desco.adapter.in.web.identity;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;

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
            String razonSocial,
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
