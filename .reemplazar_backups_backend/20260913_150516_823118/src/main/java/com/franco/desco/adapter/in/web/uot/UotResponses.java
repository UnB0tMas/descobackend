package com.franco.desco.adapter.in.web.uot;

import java.time.LocalDate;
import java.util.List;

public final class UotResponses {
    private UotResponses() {}

    public record Unit(
            Long uotId, Long uotPadreId, Long ubicacionId, String codigo, String nombre,
            String descripcion, boolean esRaiz, LocalDate fechaInicio, LocalDate fechaFin,
            boolean estado, boolean asignada, boolean predeterminada
    ) {}

    public record Membership(
            Long usuarioUotId, Long uotId, String codigo, String nombre,
            boolean predeterminada, List<String> roles
    ) {}

    public record Context(
            String modo, Long uotSeleccionadaId, boolean requiereSeleccion,
            boolean permiteModoGeneral, List<Membership> uots
    ) {}

    public record Created(Long uotId) {}
}
