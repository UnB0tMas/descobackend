package com.franco.desco.adapter.in.web.logistics;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class LogisticsRequests {
    private LogisticsRequests() {}

    public record Policy(
            @NotNull @Positive Long uotId,
            @NotNull @Positive Long productoId,
            @NotNull Boolean permiteVenta,
            @NotNull Boolean permiteUsoInterno
    ) {}

    public record TransferLine(@NotNull @Positive Long productoId,
                               @NotNull @DecimalMin("0.001") BigDecimal cantidad) {}

    public record Transfer(
            @NotNull @Positive Long almacenOrigenId,
            @NotNull @Positive Long almacenDestinoId,
            @NotEmpty List<@Valid TransferLine> detalle,
            @Size(max=300) String observacion
    ) {}

    public record RequestProduct(
            @NotNull @Positive Long uotId,
            @NotNull @Positive Long almacenId,
            @NotNull @Positive Long productoId,
            @NotNull @Positive Long empleadoId,
            @NotNull @DecimalMin("0.001") BigDecimal cantidad,
            @NotBlank @Size(max=250) String actividad,
            @NotBlank @Size(max=300) String lugar,
            @NotNull LocalDateTime fechaInicio,
            LocalDateTime fechaFin,
            @Positive Long archivoAutorizacionId,
            @Size(max=500) String observacion
    ) {
        @AssertTrue(message="La fecha de fin debe ser posterior al inicio.")
        public boolean validDates() {
            return fechaInicio == null || fechaFin == null || !fechaFin.isBefore(fechaInicio);
        }
    }

    public record ProductOperation(
            @NotBlank @Pattern(regexp="APROBAR|RECHAZAR|ENTREGAR|DEVOLVER|CONSUMIR|CERRAR|CANCELAR") String operacion,
            @DecimalMin("0.001") BigDecimal cantidad,
            @Size(max=300) String observacion
    ) {}

    public record AttachFile(@NotNull @Positive Long archivoId) {}
}
