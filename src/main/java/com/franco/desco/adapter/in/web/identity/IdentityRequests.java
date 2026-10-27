package com.franco.desco.adapter.in.web.identity;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public final class IdentityRequests {

    private IdentityRequests() {
    }

    public enum Target {
        PERSONA,
        EMPRESA
    }

    public enum DocumentType {
        DNI,
        RUC
    }

    @Schema(name = "IdentityResolveRequest")
    public record Resolve(
            @NotNull Target entidadObjetivo,
            @NotNull DocumentType tipoDocumento,
            @NotBlank
            @Pattern(
                    regexp = "\\d{8}|\\d{11}",
                    message = "El documento debe contener 8 dígitos para DNI o 11 dígitos para RUC."
            )
            String numeroDocumento
    ) {
        @AssertTrue(
                message = "La combinación de entidad y tipo de documento no es válida."
        )
        public boolean isCombinationValid() {
            if (entidadObjetivo == null || tipoDocumento == null) {
                return true;
            }

            if (entidadObjetivo == Target.EMPRESA) {
                return tipoDocumento == DocumentType.RUC;
            }

            return true;
        }
    }
}
