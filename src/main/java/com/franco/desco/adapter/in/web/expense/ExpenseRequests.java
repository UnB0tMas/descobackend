package com.franco.desco.adapter.in.web.expense;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ExpenseRequests {
    private ExpenseRequests() {}

    @Schema(name="ExpenseCreateRequest")
    public record Create(
            @NotNull Long campaniaVentaId,
            Long operativoVentaId,
            @NotNull Short tipoGastoId,
            @NotNull Short reglaProrrateoId,
            @NotNull LocalDate fecha,
            @NotBlank @Size(max=250) String concepto,
            @NotNull @DecimalMin("0.0001") BigDecimal importe,
            @NotBlank @Pattern(regexp="[A-Za-z]{3}") String moneda
    ) {}

    @Schema(name="ExpenseUpdateRequest")
    public record Update(
            @NotNull Short tipoGastoId,
            @NotNull Short reglaProrrateoId,
            @NotNull LocalDate fecha,
            @NotBlank @Size(max=250) String concepto,
            @NotNull @DecimalMin("0.0001") BigDecimal importe,
            @NotBlank @Pattern(regexp="[A-Za-z]{3}") String moneda
    ) {}

    @Schema(name="ExpenseProrationItemRequest")
    public record ProrationItem(@NotNull Long participacionId,@NotNull @PositiveOrZero BigDecimal importeAsignado){}

    @Schema(name="ExpenseProrateRequest")
    public record Prorate(List<@Valid ProrationItem> prorrateo){}

    @Schema(name="ExpenseCancelRequest")
    public record Cancel(@NotBlank @Size(max=500) String motivo){}
}
