package com.franco.desco.domain.organization;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class OrganizationModels {

    private OrganizationModels() {
    }

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

    public record EmployeeLite(
            Long empleadoId,
            String codigoEmpleado,
            String numeroDocumento,
            String empleado
    ) {
    }

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
            List<EmployeeLite> empleados
    ) {
        public Detail {
            areas = areas == null ? List.of() : List.copyOf(areas);
            empleados = empleados == null ? List.of() : List.copyOf(empleados);
        }
    }
}
