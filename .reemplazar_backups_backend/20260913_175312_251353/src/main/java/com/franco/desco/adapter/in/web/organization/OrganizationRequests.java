package com.franco.desco.adapter.in.web.organization;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public final class OrganizationRequests {

    private OrganizationRequests() {
    }

    @Schema(name = "OrganizationLocationRequest")
    public record Location(
            @NotBlank @Pattern(regexp = "\\d{6}", message = "Seleccione un distrito válido.") String distritoCodigo,
            @Positive(message = "El centro poblado seleccionado no es válido.") Long centroPobladoId,
            @Size(max = 300, message = "La referencia no puede superar los 300 caracteres.") String referencia
    ) {
    }

    @Schema(name = "CompanyCreateRequest")
    public record CreateCompany(
            @NotBlank @Pattern(regexp = "\\d{11}") String ruc,
            @NotBlank @Size(max = 200) String razonSocial,
            @Size(max = 160) String nombreComercial,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            @NotNull @Valid Location ubicacion
    ) {
    }

    @Schema(name = "CompanyUpdateRequest")
    public record UpdateCompany(
            @NotBlank @Size(max = 200) String razonSocial,
            @Size(max = 160) String nombreComercial,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            @NotNull @Valid Location ubicacion
    ) {
    }

    @Schema(name = "AssociationCreateRequest")
    public record CreateAssociation(
            @NotBlank @Pattern(regexp = "\\d{11}") String ruc,
            @NotBlank @Size(max = 200) String razonSocial,
            @Size(max = 160) String nombreComercial,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            LocalDate fechaConstitucion,
            @Size(max = 50) String numeroPartida,
            @NotNull @Valid Location ubicacion
    ) {
    }

    @Schema(name = "AssociationUpdateRequest")
    public record UpdateAssociation(
            @NotBlank @Size(max = 200) String razonSocial,
            @Size(max = 160) String nombreComercial,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            LocalDate fechaConstitucion,
            @Size(max = 50) String numeroPartida,
            @NotNull @Valid Location ubicacion
    ) {
    }

    @Schema(name = "OrganizationDisableRequest")
    public record Disable(
            @NotBlank @Size(max = 300) String motivo
    ) {
    }

    @Schema(name = "AreaCreateRequest")
    public record CreateArea(
            @NotNull @Positive Long empresaId,
            @Positive Long areaPadreId,
            @NotBlank @Size(max = 30) String codigo,
            @NotBlank @Size(max = 120) String nombre
    ) {
    }

    @Schema(name = "AreaUpdateRequest")
    public record UpdateArea(
            @Positive Long areaPadreId,
            @NotBlank @Size(max = 120) String nombre
    ) {
    }
}
