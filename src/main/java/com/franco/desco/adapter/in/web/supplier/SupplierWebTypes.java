package com.franco.desco.adapter.in.web.supplier;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.util.List;
import java.time.LocalDate;

public final class SupplierWebTypes {
    private SupplierWebTypes() {}

    @Schema(name = "SupplierItemResponse")
    public record Item(Long id, String tipo, Long entidadId, String nombre, String tipoDocumento,
                       String documento, String telefono, String correo, Boolean estado,
                       String nombres, String apellidoPaterno, String apellidoMaterno,
                       String razonSocial, String nombreComercial, LocalDate fechaNacimiento, String sexo) {}
    @Schema(name = "SupplierPageResponse")
    public record Page(Long total, List<Item> items) {}
    @Schema(name = "SupplierRegisteredResponse")
    public record Registered(Long id) {}

    @Schema(name = "SupplierSaveRequest")
    public record Save(
        @NotNull @Positive Long uotId,
        @NotBlank @Pattern(regexp = "PERSONA|EMPRESA") String tipo,
        @NotBlank @Size(max = 15) String tipoDocumento,
        @NotBlank @Size(max = 30) String numeroDocumento,
        @Size(max = 100) String nombres,
        @Size(max = 80) String apellidoPaterno,
        @Size(max = 80) String apellidoMaterno,
        @Size(max = 200) String razonSocial,
        @Size(max = 160) String nombreComercial,
        @PastOrPresent LocalDate fechaNacimiento,
        @Size(max = 20) String sexo,
        @Size(max = 30) String telefono,
        @Email @Size(max = 180) String correo
    ) {
        @AssertTrue(message = "Complete la identidad del proveedor.")
        @Schema(hidden = true)
        public boolean isIdentityValid() {
            if ("PERSONA".equals(tipo))
                return nombres != null && !nombres.isBlank() && apellidoPaterno != null && !apellidoPaterno.isBlank()
                    && java.util.Set.of("DNI", "CE", "PASAPORTE").contains(tipoDocumento);
            return "EMPRESA".equals(tipo) && "RUC".equals(tipoDocumento)
                    && razonSocial != null && !razonSocial.isBlank();
        }
    }
}
