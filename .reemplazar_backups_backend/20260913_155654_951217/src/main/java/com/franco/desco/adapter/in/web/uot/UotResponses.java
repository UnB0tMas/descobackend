package com.franco.desco.adapter.in.web.uot;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDate;
import java.util.List;

public final class UotResponses {
    private UotResponses() {}

    @Schema(name = "UotUnitResponse", description = "Unidad operativa territorial disponible para consulta o administración.")
    public record Unit(
            Long uotId,
            Long uotPadreId,
            Long ubicacionId,
            String codigo,
            String nombre,
            String descripcion,
            boolean esRaiz,
            LocalDate fechaInicio,
            LocalDate fechaFin,
            boolean estado,
            @Schema(description = "Indica si la UOT está asignada al usuario consultante.") boolean asignada,
            @Schema(description = "Indica si es la UOT predeterminada del usuario.") boolean predeterminada
    ) {}

    @Schema(name = "UotMembershipResponse", description = "Asignación efectiva del usuario a una UOT con sus roles locales.")
    public record Membership(
            Long usuarioUotId,
            Long uotId,
            String codigo,
            String nombre,
            boolean predeterminada,
            List<String> roles
    ) {}

    @Schema(name = "UotContextResponse", description = "Contexto UOT efectivo de la sesión autenticada.")
    public record Context(
            @Schema(allowableValues = {"ESPECIFICA", "GENERAL"}, example = "ESPECIFICA") String modo,
            Long uotSeleccionadaId,
            boolean requiereSeleccion,
            boolean permiteModoGeneral,
            List<Membership> uots
    ) {}

    @Schema(name = "UotCreatedResponse")
    public record Created(Long uotId) {}
}
