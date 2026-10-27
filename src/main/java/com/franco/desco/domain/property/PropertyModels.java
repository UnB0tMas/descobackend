package com.franco.desco.domain.property;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class PropertyModels {
    private PropertyModels() {}

    public record Summary(
            Long predioId, String codigo, String nombre, LocalDate fechaRegistro, boolean estado,
            String distritoCodigo, Long centroPobladoId, String referencia, BigDecimal areaTotalHa,
            BigDecimal areaCultivableHa, String tipoRiego, String titulares
    ) {}

    public record Owner(
            Long predioTitularidadId, Long socioId, String tipoDocumento, String numeroDocumento,
            String nombres, String apellidoPaterno, String apellidoMaterno, String tipoTitularidad,
            BigDecimal porcentaje, LocalDate fechaDesde, LocalDate fechaHasta, boolean estado
    ) {}

    public record Version(
            Long predioVersionId, BigDecimal areaTotalHa, BigDecimal areaCultivableHa, String tipoRiego,
            String fuenteAgua, String infraestructura, String observacion, LocalDate fechaDesde,
            LocalDate fechaHasta, boolean estado
    ) {}

    public record Plot(
            Long parcelaId, String parcelaCodigo, String parcelaNombre, BigDecimal areaHa, boolean parcelaEstado,
            Long ubicacionId, Long parcelaCultivoId, Long variedadPaltaId, String variedad,
            LocalDate fechaInicio, LocalDate fechaFin, String situacionCultivo, boolean cultivoEstado
    ) {}

    public record FileRef(Long archivoId, String nombreOriginal, String mimeType, String secureUrl, Instant fechaCarga, String categoria, String origenCaptura) {}

    public record Detail(
            Long predioId, String codigo, String nombre, LocalDate fechaRegistro, boolean estado,
            Long ubicacionId, String distritoCodigo, Long centroPobladoId, String referencia,
            BigDecimal latitud, BigDecimal longitud, BigDecimal altitudM, Long predioVersionId,
            BigDecimal areaTotalHa, BigDecimal areaCultivableHa, String tipoRiego, String fuenteAgua,
            String infraestructura, String observacion, LocalDate fechaDesde,
            List<Owner> titulares, List<Version> versiones, List<Plot> parcelas, List<FileRef> archivos
    ) {
        public Detail {
            titulares = titulares == null ? List.of() : List.copyOf(titulares);
            versiones = versiones == null ? List.of() : List.copyOf(versiones);
            parcelas = parcelas == null ? List.of() : List.copyOf(parcelas);
            archivos = archivos == null ? List.of() : List.copyOf(archivos);
        }
    }
}
