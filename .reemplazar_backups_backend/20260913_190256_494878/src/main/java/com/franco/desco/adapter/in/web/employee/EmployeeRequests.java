package com.franco.desco.adapter.in.web.employee;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public final class EmployeeRequests {

    private EmployeeRequests() {
    }

    @Schema(name = "EmployeeLocationRequest")
    public record Location(
            @NotBlank @Pattern(regexp = "\\d{6}", message = "Seleccione un distrito válido.") String distritoCodigo,
            @Positive(message = "El centro poblado seleccionado no es válido.") Long centroPobladoId,
            @Size(max = 300, message = "La referencia no puede superar los 300 caracteres.") String referencia
    ) {
    }

    @Schema(name = "EmployeeCreateRequest")
    public record Create(
            @NotBlank @Pattern(regexp = "DNI|RUC|CE|PASAPORTE|OTRO", message = "El tipo de documento no es válido.") String tipoDocumento,
            @NotBlank @Size(max = 30) String numeroDocumento,
            @NotBlank @Size(max = 100) String nombres,
            @NotBlank @Size(max = 80) String apellidoPaterno,
            @Size(max = 80) String apellidoMaterno,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            @PastOrPresent(message = "La fecha de nacimiento no puede ser futura.") LocalDate fechaNacimiento,
            @NotNull @Positive(message = "Seleccione una UOT válida.") Long uotId,
            @Positive(message = "La empresa seleccionada no es válida.") Long empresaId,
            @NotBlank @Size(max = 30) String codigoEmpleado,
            @NotNull LocalDate fechaIngreso,
            @Positive(message = "El área seleccionada no es válida.") Long areaId,
            @Size(max = 120) String cargo,
            @NotNull @Valid Location ubicacion
    ) {
    }

    @Schema(name = "EmployeeUpdateRequest")
    public record Update(
            @Size(max = 15) @Pattern(regexp = "DNI|RUC|CE|PASAPORTE|OTRO", message = "El tipo de documento no es válido.") String tipoDocumento,
            @Size(max = 30) String numeroDocumento,
            @Size(max = 100) String nombres,
            @Size(max = 80) String apellidoPaterno,
            @Size(max = 80) String apellidoMaterno,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            @PastOrPresent(message = "La fecha de nacimiento no puede ser futura.") LocalDate fechaNacimiento,
            @NotNull @Positive(message = "Seleccione una UOT válida.") Long uotId,
            @Positive(message = "La empresa seleccionada no es válida.") Long empresaId,
            @Size(max = 30) String codigoEmpleado,
            LocalDate fechaIngreso,
            @Positive(message = "El área seleccionada no es válida.") Long areaId,
            @Size(max = 120) String cargo,
            LocalDate fechaAsignacionArea,
            @NotNull @Valid Location ubicacion
    ) {
    }

    @Schema(name = "EmployeeRetireRequest")
    public record Retire(
            @NotNull @Positive(message = "Seleccione una UOT válida.") Long uotId,
            @NotBlank @Size(max = 500) String motivo,
            LocalDate fechaCese
    ) {
    }
}
