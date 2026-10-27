package com.franco.desco.adapter.in.web.organization;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class OrganizationResponses {

    private OrganizationResponses() {
    }

    @Schema(name = "OrganizationSummaryResponse")
    public record Summary(
            Long empresaId,
            String ruc,
            String razonSocial,
            String nombreComercial,
            String telefono,
            String correo,
            Instant fechaCreacion,
            boolean estado,
            boolean esAsociacion,
            LocalDate fechaConstitucion,
            String numeroPartida
    ) {
    }

    @Schema(name = "AreaResponse")
    public record Area(
            Long areaId,
            Long empresaId,
            String empresa,
            Long areaPadreId,
            String areaPadre,
            String codigo,
            String nombre,
            boolean estado
    ) {
    }

    @Schema(name = "OrganizationEmployeeResponse")
    public record Employee(
            Long empleadoId,
            String codigoEmpleado,
            String numeroDocumento,
            String empleado
    ) {
    }

    @Schema(name = "OrganizationDetailResponse")
    public record Detail(
            Summary organizacion,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referencia,
            BigDecimal altitudM,
            String posicionWkt,
            Integer posicionSrid,
            List<Area> areas,
            List<Employee> empleados
    ) {
    }

    @Schema(name = "CreatedIdResponse")
    public record CreatedId(Long id) {
    }
}
