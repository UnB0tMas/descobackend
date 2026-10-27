package com.franco.desco.domain.document;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class DocumentModels {
    private DocumentModels() {}

    public record Summary(
            Long archivoId,
            String nombreOriginal,
            String mimeType,
            String secureUrl,
            Long tamanoBytes,
            String categoria,
            String tipoEvidencia,
            String origenCaptura,
            String descripcion,
            Instant fechaCaptura,
            BigDecimal latitudCaptura,
            BigDecimal longitudCaptura,
            Instant fechaCarga,
            Long usuarioId,
            String nombreUsuario,
            String tipoContexto,
            Long contextoId
    ) {}

    public record Link(
            Long archivoVinculoId,
            String tipoContexto,
            Long contextoId
    ) {}

    public record Detail(
            Long archivoId,
            String nombreOriginal,
            String mimeType,
            String cloudinaryPublicId,
            String secureUrl,
            Long tamanoBytes,
            String categoria,
            String tipoEvidencia,
            String origenCaptura,
            String descripcion,
            Instant fechaCaptura,
            BigDecimal latitudCaptura,
            BigDecimal longitudCaptura,
            Instant fechaCarga,
            Long usuarioId,
            String nombreUsuario,
            List<Link> vinculos
    ) {
        public Detail {
            vinculos = vinculos == null ? List.of() : List.copyOf(vinculos);
        }
    }
}
