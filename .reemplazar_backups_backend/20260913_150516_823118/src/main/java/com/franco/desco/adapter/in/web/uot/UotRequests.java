package com.franco.desco.adapter.in.web.uot;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

public final class UotRequests {
    private UotRequests() {}

    @Schema(name = "UotSelectContextRequest")
    public record SelectContext(
            @NotBlank @Pattern(regexp = "ESPECIFICA|GENERAL") String modo,
            @Positive Long uotId
    ) {}

    @Schema(name = "UotCreateRequest")
    public record Create(
            @NotNull @Positive Long uotPadreId,
            @Positive Long ubicacionId,
            @NotBlank @Size(max = 40) String codigo,
            @NotBlank @Size(max = 160) String nombre,
            @Size(max = 400) String descripcion
    ) {}

    @Schema(name = "UotUpdateRequest")
    public record Update(
            @Positive Long uotPadreId,
            @Positive Long ubicacionId,
            @NotBlank @Size(max = 160) String nombre,
            @Size(max = 400) String descripcion,
            boolean estado
    ) {}

    @Schema(name = "UotAssignUserRequest")
    public record AssignUser(@NotNull @Positive Long usuarioId, boolean predeterminada) {}

    @Schema(name = "UotAssignRoleRequest")
    public record AssignRole(@NotNull @Positive Long usuarioId, @NotNull @Positive Long rolId) {}
}
