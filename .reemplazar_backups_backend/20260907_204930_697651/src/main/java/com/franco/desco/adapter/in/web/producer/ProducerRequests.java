package com.franco.desco.adapter.in.web.producer;

import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.Target;
import com.franco.desco.domain.identity.PeruvianDocumentRules;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public final class ProducerRequests {

    private static final String PERSON_NAME_PATTERN =
            "^[\\p{L}\\p{M}]+(?:[ '\\-][\\p{L}\\p{M}]+)*$";

    private ProducerRequests() {
    }

    @Schema(name = "ProducerLocationRequest")
    public record Location(
            @NotBlank
            @Pattern(regexp = "\\d{6}", message = "Seleccione un distrito válido.")
            String distritoCodigo,
            @Positive(message = "El centro poblado seleccionado no es válido.")
            Long centroPobladoId,
            @Size(max = 300)
            String referencia
    ) {
    }

    @Schema(name = "ProducerCreateRequest")
    public record Create(
            @NotBlank
            @Pattern(regexp = "DNI|RUC|CE|PASAPORTE|OTRO")
            String tipoDocumento,
            @NotBlank @Size(max = 30) String numeroDocumento,
            @NotBlank @Size(max = 100)
            @Pattern(regexp = PERSON_NAME_PATTERN)
            String nombres,
            @NotBlank @Size(max = 80)
            @Pattern(regexp = PERSON_NAME_PATTERN)
            String apellidoPaterno,
            @Size(max = 80)
            @Pattern(regexp = PERSON_NAME_PATTERN)
            String apellidoMaterno,
            @Size(max = 30)
            @Pattern(regexp = "^\\+?\\d{7,15}$")
            String telefono,
            @Email @Size(max = 180) String correo,
            LocalDate fechaNacimiento,
            @NotNull @PastOrPresent LocalDate fechaAlta,
            @NotNull @Positive Long asociacionId,
            @NotBlank @Size(max = 30) String codigoSocio,
            @NotNull @PastOrPresent LocalDate fechaDesde,
            @NotBlank
            @Pattern(regexp = "ACTIVO|SUSPENDIDO")
            String situacionMembresia,
            @NotNull @Valid Location ubicacion
    ) {
        @AssertTrue(message = "La fecha de nacimiento debe corresponder a una persona mayor de edad.")
        public boolean edadValida() {
            return validAdult(fechaNacimiento);
        }

        @AssertTrue(message = "La fecha de afiliación no puede ser anterior al alta.")
        public boolean fechasValidas() {
            return fechaAlta == null
                    || fechaDesde == null
                    || !fechaDesde.isBefore(fechaAlta);
        }

        @AssertTrue(message = "El DNI o RUC no es válido para una persona natural.")
        public boolean documentoValido() {
            return validPersonDocument(tipoDocumento, numeroDocumento);
        }
    }

    @Schema(name = "ProducerUpdateRequest")
    public record Update(
            @NotBlank
            @Pattern(regexp = "DNI|RUC|CE|PASAPORTE|OTRO")
            String tipoDocumento,
            @NotBlank @Size(max = 30) String numeroDocumento,
            @NotBlank @Size(max = 100)
            @Pattern(regexp = PERSON_NAME_PATTERN)
            String nombres,
            @NotBlank @Size(max = 80)
            @Pattern(regexp = PERSON_NAME_PATTERN)
            String apellidoPaterno,
            @Size(max = 80)
            @Pattern(regexp = PERSON_NAME_PATTERN)
            String apellidoMaterno,
            @Size(max = 30)
            @Pattern(regexp = "^\\+?\\d{7,15}$")
            String telefono,
            @Email @Size(max = 180) String correo,
            LocalDate fechaNacimiento,
            @NotNull @Positive Long asociacionId,
            @NotBlank @Size(max = 30) String codigoSocio,
            @NotNull @PastOrPresent LocalDate fechaDesde,
            @NotBlank
            @Pattern(regexp = "ACTIVO|SUSPENDIDO")
            String situacionMembresia,
            @NotNull @Valid Location ubicacion
    ) {
        @AssertTrue(message = "La fecha de nacimiento debe corresponder a una persona mayor de edad.")
        public boolean edadValida() {
            return validAdult(fechaNacimiento);
        }

        @AssertTrue(message = "El DNI o RUC no es válido para una persona natural.")
        public boolean documentoValido() {
            return validPersonDocument(tipoDocumento, numeroDocumento);
        }
    }

    @Schema(name = "ProducerRetireRequest")
    public record Retire(
            @NotNull @PastOrPresent LocalDate fechaRetiro,
            @NotBlank @Size(max = 500) String motivo
    ) {
    }

    private static boolean validAdult(LocalDate birthDate) {
        if (birthDate == null) {
            return true;
        }

        LocalDate today = LocalDate.now();
        return !birthDate.isAfter(today.minusYears(18))
                && !birthDate.isBefore(today.minusYears(120));
    }

    private static boolean validPersonDocument(
            String documentType,
            String documentNumber
    ) {
        if (documentType == null || documentNumber == null) {
            return true;
        }

        String type = documentType.trim().toUpperCase();

        if (!"DNI".equals(type) && !"RUC".equals(type)) {
            return true;
        }

        return PeruvianDocumentRules.validFor(
                Target.PERSONA,
                DocumentType.valueOf(type),
                PeruvianDocumentRules.normalize(documentNumber)
        );
    }
}
