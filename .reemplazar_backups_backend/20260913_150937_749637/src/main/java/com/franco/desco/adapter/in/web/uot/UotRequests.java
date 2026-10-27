package com.franco.desco.adapter.in.web.uot;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

public final class UotRequests {
    private UotRequests() {}

    @Schema(name = "UotSelectContextRequest", description = "Selección del contexto UOT efectivo de la sesión autenticada.")
    public record SelectContext(
            @Schema(description = "Modo de trabajo.", allowableValues = {"ESPECIFICA", "GENERAL"}, example = "ESPECIFICA")
            @NotBlank @Pattern(regexp = "ESPECIFICA|GENERAL") String modo,
            @Schema(description = "UOT seleccionada. Debe enviarse en modo ESPECIFICA y omitirse en modo GENERAL.", example = "4", nullable = true)
            @Positive Long uotId
    ) {
        @AssertTrue(message = "Seleccione una UOT para el modo específico y no envíe UOT para el modo general.")
        public boolean contextoValido() {
            if (modo == null) return true;
            return "GENERAL".equalsIgnoreCase(modo) ? uotId == null : uotId != null;
        }
    }

    @Schema(name = "UotCreateRequest", description = "Registro de una nueva UOT dentro de la jerarquía DESCO.")
    public record Create(
            @Schema(description = "UOT padre.", example = "1")
            @NotNull @Positive Long uotPadreId,
            @Schema(description = "Ubicación registrada asociada a la UOT.", example = "12", nullable = true)
            @Positive Long ubicacionId,
            @Schema(description = "Código funcional único de la UOT.", example = "UOT-SARA-SARA")
            @NotBlank @Size(max = 40) String codigo,
            @Schema(description = "Nombre visible de la UOT.", example = "UOT Sara Sara")
            @NotBlank @Size(max = 160) String nombre,
            @Schema(description = "Descripción opcional.", nullable = true)
            @Size(max = 400) String descripcion
    ) {}

    @Schema(name = "UotUpdateRequest", description = "Actualización de una UOT existente.")
    public record Update(
            @Schema(description = "Nueva UOT padre.", nullable = true)
            @Positive Long uotPadreId,
            @Schema(description = "Ubicación asociada.", nullable = true)
            @Positive Long ubicacionId,
            @NotBlank @Size(max = 160) String nombre,
            @Size(max = 400) String descripcion,
            @Schema(description = "Estado lógico de la UOT.", example = "true")
            boolean estado
    ) {}

    @Schema(name = "UotAssignUserRequest", description = "Asignación de un usuario a una UOT.")
    public record AssignUser(
            @NotNull @Positive Long usuarioId,
            @Schema(description = "Marca esta UOT como predeterminada para el usuario.")
            boolean predeterminada
    ) {}

    @Schema(name = "UotAssignRoleRequest", description = "Asignación de un rol efectivo de usuario dentro de una UOT.")
    public record AssignRole(
            @NotNull @Positive Long usuarioId,
            @NotNull @Positive Long rolId
    ) {}
}
