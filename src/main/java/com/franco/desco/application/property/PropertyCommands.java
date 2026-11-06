package com.franco.desco.application.property;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class PropertyCommands {
    private PropertyCommands() {}

    public record Filter(String buscar, Long socioId, String distritoCodigo, Boolean soloActivos) {}
    public record ListProperties(PageRequest<Filter> page) {}
    public record GetProperty(Long predioId) {}
    public record Location(String distritoCodigo, Long centroPobladoId, String referencia, BigDecimal latitud, BigDecimal longitud, BigDecimal altitudM) {}
    public record Characteristics(BigDecimal areaTotalHa, BigDecimal areaCultivableHa, String tipoRiego, String fuenteAgua, String infraestructura, String observacion, LocalDate fechaDesde) {}
    public record Owner(Long personaId, Long socioId, String tipoTitularidad, BigDecimal porcentaje) {}
    public record CreateProperty(String codigo, String nombre, LocalDate fechaRegistro, Location ubicacion, Characteristics caracteristicas, List<Owner> titulares) {}
    public record UpdateProperty(Long predioId, String codigo, String nombre, LocalDate fechaTitularidad, Location ubicacion, Characteristics caracteristicas, List<Owner> titulares) {}
    public record RetireProperty(Long predioId, LocalDate fechaRetiro, String motivo) {}
}
