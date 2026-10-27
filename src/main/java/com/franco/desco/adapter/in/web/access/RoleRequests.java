package com.franco.desco.adapter.in.web.access;
import io.swagger.v3.oas.annotations.media.Schema; import jakarta.validation.constraints.*; import java.util.List;
public final class RoleRequests{private RoleRequests(){}
 @Schema(name="RoleCreateRequest") public record Create(@NotBlank @Size(max=40) String codigo,@NotBlank @Size(max=100) String nombre,@Size(max=200) String descripcion,boolean requiereSegundoFactor){}
 @Schema(name="RoleUpdateRequest") public record Update(@NotBlank @Size(max=100) String nombre,@Size(max=200) String descripcion,boolean requiereSegundoFactor){}
 @Schema(name="RoleDisableRequest") public record Disable(@NotBlank @Size(max=300) String motivo){}
 @Schema(name="RolePermissionsUpdateRequest") public record Permissions(@NotNull List<@NotNull Long> permisoIds,@Size(max=300) String motivo){}
}
