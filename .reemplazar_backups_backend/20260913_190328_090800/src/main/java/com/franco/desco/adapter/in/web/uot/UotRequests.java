package com.franco.desco.adapter.in.web.uot;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.util.List;

public final class UotRequests {
    private UotRequests() {}

    @Schema(name="UotSelectContextRequest",description="Selecciona una UOT concreta o una vista general de todas las UOT asignadas.")
    public record SelectContext(
            @NotBlank @Pattern(regexp="ESPECIFICA|GENERAL") String modo,
            @Positive Long uotId
    ) {
        @AssertTrue(message="En modo ESPECIFICA debe seleccionar una UOT; en GENERAL no debe enviar uotId.")
        public boolean contextoValido(){return modo==null || ("GENERAL".equalsIgnoreCase(modo)?uotId==null:uotId!=null);}
    }

    @Schema(name="UotCreateRequest")
    public record Create(@NotNull @Positive Long uotPadreId,@Positive Long ubicacionId,@NotBlank @Size(max=40) String codigo,@NotBlank @Size(max=160) String nombre,@Size(max=400) String descripcion){}
    @Schema(name="UotUpdateRequest")
    public record Update(@Positive Long uotPadreId,@Positive Long ubicacionId,@NotBlank @Size(max=160) String nombre,@Size(max=400) String descripcion){}
    @Schema(name="UotAssignUserRequest")
    public record AssignUser(@NotNull @Positive Long usuarioId,boolean predeterminada){}
    @Schema(name="UotAssignRoleRequest",description="El rol se aplica únicamente dentro de la UOT indicada.")
    public record AssignRole(@NotNull @Positive Long usuarioId,@NotNull @Positive Long rolId){}
    @Schema(name="UotDeactivateRequest")
    public record Deactivate(@NotBlank @Size(max=500) String motivo){}

    @Schema(name="UotTransferResourcesRequest",description="Transfiere stock, bienes y/o suministros conservando el Kardex histórico de la UOT origen.")
    public record TransferResources(
            @NotNull @Positive Long uotDestinoId,
            @Positive Long almacenOrigenId,
            @Positive Long almacenDestinoId,
            boolean transferirStock,
            List<@Positive Long> bienIds,
            List<@Positive Long> suministroIds,
            @NotBlank @Size(max=500) String motivo
    ) {
        public TransferResources {
            bienIds = bienIds == null ? List.of() : List.copyOf(bienIds);
            suministroIds = suministroIds == null ? List.of() : List.copyOf(suministroIds);
        }
        @AssertTrue(message="Si transfiere stock debe indicar almacén de origen y destino.")
        public boolean almacenesValidos(){return !transferirStock || (almacenOrigenId!=null && almacenDestinoId!=null);}
        @AssertTrue(message="Seleccione stock, bienes o suministros para transferir.")
        public boolean recursosSeleccionados(){return transferirStock || !bienIds.isEmpty() || !suministroIds.isEmpty();}
    }
}
