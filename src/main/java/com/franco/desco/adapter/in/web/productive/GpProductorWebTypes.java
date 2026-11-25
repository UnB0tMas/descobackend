package com.franco.desco.adapter.in.web.productive;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;

public final class GpProductorWebTypes {
    private GpProductorWebTypes() {}

    @Schema(name = "GpProductorResponse")
    public record Productor(Long personaId, String tipoDocumento, String numeroDocumento,
            String nombres, String apellidoPaterno, String apellidoMaterno, String nombreCompleto,
            String telefono, String correo, LocalDate fechaNacimiento,
            String distritoCodigo, Long centroPobladoId, String referencia) {}

    @Schema(name = "GpProductorEditarRequest")
    public record Editar(@NotBlank @Size(max = 100) String nombres,
            @NotBlank @Size(max = 80) String apellidoPaterno, @Size(max = 80) String apellidoMaterno,
            @Size(max = 30) String telefono, @Email @Size(max = 180) String correo,
            @Pattern(regexp = "[0-9]{6}") String distritoCodigo,
            @Positive Long centroPobladoId, @Size(max = 300) String referencia) {}

    @Schema(name = "GpProductorParcelaAltaRequest")
    public record ParcelaAlta(@NotBlank @Size(max = 120) String nombre,
            @NotNull @DecimalMin("0.0001") @Digits(integer = 6, fraction = 4) BigDecimal areaHa,
            @NotBlank @Pattern(regexp = "[0-9]{6}") String distritoCodigo,
            @Positive Long centroPobladoId,
            @DecimalMin("-90.0") @DecimalMax("90.0") BigDecimal latitud,
            @DecimalMin("-180.0") @DecimalMax("180.0") BigDecimal longitud,
            @Size(max = 300) String referencia, @Size(max = 500) String observacion) {
        @AssertTrue(message = "Ingrese ambas coordenadas o ninguna") @Schema(hidden = true)
        public boolean isGpsValido() { return (latitud == null) == (longitud == null); }
    }

    @Schema(name = "GpProductorRetirarRequest")
    public record Retirar(@NotBlank @Size(min = 3, max = 500) String motivo) {}
}
