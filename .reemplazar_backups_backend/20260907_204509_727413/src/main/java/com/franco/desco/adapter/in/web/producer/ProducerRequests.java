package com.franco.desco.adapter.in.web.producer;

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

public final class ProducerRequests {

    private ProducerRequests() {
    }

    @Schema(name = "ProducerLocationRequest")
    public record Location(
            @NotBlank
            @Pattern(
                    regexp = "\\d{6}",
                    message = "Seleccione un distrito válido."
            )
            String distritoCodigo,

            @Positive(
                    message = "El centro poblado seleccionado no es válido."
            )
            Long centroPobladoId,

            @Size(
                    max = 300,
                    message = "La referencia no puede superar los 300 caracteres."
            )
            String referencia
    ) {
    }

    @Schema(name = "ProducerCreateRequest")
    public record Create(
            @NotBlank
            @Size(max = 20)
            @Pattern(
                    regexp = "DNI|RUC|CE|PASAPORTE|OTRO",
                    message = "El tipo de documento no es válido."
            )
            String tipoDocumento,

            @NotBlank
            @Size(max = 30)
            String numeroDocumento,

            @NotBlank
            @Size(max = 100)
            String nombres,

            @NotBlank
            @Size(max = 80)
            String apellidoPaterno,

            @Size(max = 80)
            String apellidoMaterno,

            @Size(max = 30)
            String telefono,

            @Email
            @Size(max = 180)
            String correo,

            @PastOrPresent(message = "La fecha de nacimiento no puede ser futura.")
            LocalDate fechaNacimiento,

            @NotNull
            LocalDate fechaAlta,

            @NotNull
            @Positive(message = "La asociación seleccionada no es válida.")
            Long asociacionId,

            @NotBlank
            @Size(max = 30)
            String codigoSocio,

            @NotNull
            LocalDate fechaDesde,

            @NotBlank
            @Size(max = 20)
            @Pattern(
                    regexp = "ACTIVO|SUSPENDIDO",
                    message = "La situación de membresía no es válida."
            )
            String situacionMembresia,

            @NotNull
            @Valid
            Location ubicacion
    ) {
    }

    @Schema(name = "ProducerUpdateRequest")
    public record Update(
            @NotBlank
            @Size(max = 20)
            @Pattern(
                    regexp = "DNI|RUC|CE|PASAPORTE|OTRO",
                    message = "El tipo de documento no es válido."
            )
            String tipoDocumento,

            @NotBlank
            @Size(max = 30)
            String numeroDocumento,

            @NotBlank
            @Size(max = 100)
            String nombres,

            @NotBlank
            @Size(max = 80)
            String apellidoPaterno,

            @Size(max = 80)
            String apellidoMaterno,

            @Size(max = 30)
            String telefono,

            @Email
            @Size(max = 180)
            String correo,

            @PastOrPresent(message = "La fecha de nacimiento no puede ser futura.")
            LocalDate fechaNacimiento,

            @NotNull
            @Positive(message = "La asociación seleccionada no es válida.")
            Long asociacionId,

            @NotBlank
            @Size(max = 30)
            String codigoSocio,

            @NotNull
            LocalDate fechaDesde,

            @NotBlank
            @Size(max = 20)
            @Pattern(
                    regexp = "ACTIVO|SUSPENDIDO",
                    message = "La situación de membresía no es válida."
            )
            String situacionMembresia,

            @NotNull
            @Valid
            Location ubicacion
    ) {
    }

    @Schema(name = "ProducerRetireRequest")
    public record Retire(
            @NotNull
            LocalDate fechaRetiro,

            @NotBlank
            @Size(max = 500)
            String motivo
    ) {
    }
}
