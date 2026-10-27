package com.franco.desco.adapter.in.web.useradmin;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.util.List;

public final class UserAdminRequests {
    private UserAdminRequests() {}

    @Schema(name="UserCreateRequest")
    public record Create(
            @NotNull Long empleadoId,
            @NotBlank @Size(max=80) String nombreUsuario,
            @NotBlank @Size(min=12,max=128) @Schema(format="password",accessMode=Schema.AccessMode.WRITE_ONLY) String passwordInicial,
            @NotBlank @Email @Size(max=200) String correoSeguridad,
            boolean requiereCambioPassword,
            @NotEmpty List<@NotNull Long> rolIds
    ) {}

    @Schema(name="UserUpdateRequest")
    public record Update(
            @NotBlank @Size(max=80) String nombreUsuario,
            Boolean requiereCambioPassword,
            Boolean segundoFactorHabilitado
    ) {}

    @Schema(name="UserDisableRequest")
    public record Disable(@NotBlank @Size(max=500) String motivo) {}

    @Schema(name="UserReactivateRequest")
    public record Reactivate(@Size(max=500) String motivo) {}

    @Schema(name="UserAssignRoleRequest")
    public record AssignRole(@NotNull Long rolId) {}

    @Schema(name="UserRemoveRoleRequest")
    public record RemoveRole(@NotNull Long rolId, @NotBlank @Size(max=500) String motivo) {}
}
