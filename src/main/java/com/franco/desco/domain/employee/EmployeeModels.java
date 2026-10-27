package com.franco.desco.domain.employee;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class EmployeeModels {

    private EmployeeModels() {
    }

    public record Summary(
            Long empleadoId,
            Long uotId,
            String uotCodigo,
            String uotNombre,
            Long empresaId,
            String empresa,
            String codigoEmpleado,
            LocalDate fechaIngreso,
            LocalDate fechaCese,
            boolean estado,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            Long areaId,
            String area,
            String cargo,
            Long usuarioId,
            String nombreUsuario,
            String estadoCuenta
    ) {
        public Summary(Long empleadoId, Long empresaId, String empresa, String codigoEmpleado, LocalDate fechaIngreso,
                       LocalDate fechaCese, boolean estado, String tipoDocumento, String numeroDocumento, String nombres,
                       String apellidoPaterno, String apellidoMaterno, String telefono, String correo, Long areaId, String area,
                       String cargo, Long usuarioId, String nombreUsuario, String estadoCuenta) {
            this(empleadoId, null, null, null, empresaId, empresa, codigoEmpleado, fechaIngreso, fechaCese, estado,
                    tipoDocumento, numeroDocumento, nombres, apellidoPaterno, apellidoMaterno, telefono, correo, areaId, area,
                    cargo, usuarioId, nombreUsuario, estadoCuenta);
        }
    }

    public record AreaHistory(
            Long empleadoAreaId,
            Long areaId,
            String area,
            String cargo,
            LocalDate fechaDesde,
            LocalDate fechaHasta,
            boolean estado
    ) {
    }

    public record UserBrief(
            Long usuarioId,
            String nombreUsuario,
            String estadoCuenta,
            Instant ultimoAccesoCorrecto,
            boolean segundoFactorHabilitado
    ) {
    }

    public record RoleBrief(
            Long rolId,
            String codigo,
            String nombre,
            Instant fechaDesde,
            Instant fechaHasta,
            boolean estado
    ) {
    }

    public record Detail(
            Long empleadoId,
            Long uotId,
            String uotCodigo,
            String uotNombre,
            Long empresaId,
            String empresa,
            String codigoEmpleado,
            LocalDate fechaIngreso,
            LocalDate fechaCese,
            boolean estado,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referencia,
            List<AreaHistory> areas,
            UserBrief usuario,
            List<RoleBrief> roles
    ) {
        public Detail(Long empleadoId, Long empresaId, String empresa, String codigoEmpleado, LocalDate fechaIngreso, LocalDate fechaCese,
                      boolean estado, String tipoDocumento, String numeroDocumento, String nombres, String apellidoPaterno,
                      String apellidoMaterno, String telefono, String correo, LocalDate fechaNacimiento, String distritoCodigo,
                      String distritoNombre, Long centroPobladoId, String centroPobladoNombre, String referencia,
                      List<AreaHistory> areas, UserBrief usuario, List<RoleBrief> roles) {
            this(empleadoId, null, null, null, empresaId, empresa, codigoEmpleado, fechaIngreso, fechaCese, estado, tipoDocumento,
                    numeroDocumento, nombres, apellidoPaterno, apellidoMaterno, telefono, correo, fechaNacimiento, distritoCodigo,
                    distritoNombre, centroPobladoId, centroPobladoNombre, referencia, areas, usuario, roles);
        }

        public Detail {
            areas = areas == null
                    ? List.of()
                    : List.copyOf(areas);

            roles = roles == null
                    ? List.of()
                    : List.copyOf(roles);
        }
    }
}
