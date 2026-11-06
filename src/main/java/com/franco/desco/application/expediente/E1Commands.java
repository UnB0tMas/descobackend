package com.franco.desco.application.expediente;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public final class E1Commands {
    private E1Commands() {
    }

    public record ListConvenios(Long uotId) {}
    public record SearchPersonas(Long uotId, String buscar) {}
    public record CreatePersona(Long uotId, Persona persona) {}
    public record ListPredios(Long uotId, Long convenioId, String buscar) {}
    public record CreatePredio(Long uotId, Long convenioId, Predio predio) {}
    public record GetExpediente(Long uotId, Long convenioId, Long predioId) {}
    public record GetCatalogos(Long uotId) {}
    public record AddCultivo(Long uotId, Long convenioId, Long predioId, Cultivo cultivo) {}
    public record AddCrianza(Long uotId, Long convenioId, Long predioId, Crianza crianza) {}
    public record AddConteo(Long uotId, Long convenioId, Long predioId, Conteo conteo) {}
    public record AddActuacion(Long uotId, Long convenioId, Long predioId, Actuacion actuacion) {}
    public record CompleteFicha(Long uotId, Long convenioId, Long predioId, Ficha ficha) {}
    public record LinkConvenio(Long uotId, Long convenioId, Long predioId, Vinculo vinculo) {}

    public record Persona(
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            LocalDate fechaNacimiento,
            String telefono,
            String correo,
            String distritoCodigo,
            Long centroPobladoId,
            String referencia
    ) {}

    public record Predio(
            Long personaId,
            String nombre,
            String distritoCodigo,
            String referencia,
            BigDecimal latitud,
            BigDecimal longitud,
            Long centroPobladoId,
            BigDecimal areaTotalHa,
            BigDecimal areaCultivableHa,
            String tipoRiego, BigDecimal altitudM, String fuenteAgua,
            String infraestructura, String observacion, LocalDate fechaRegistro,
            LocalDate fechaDesde, String tipoTitularidadPrincipal,
            java.util.List<TitularAdicional> titularesAdicionales
    ) {}

    public record TitularAdicional(Long personaId, String tipoTitularidad, BigDecimal porcentaje) {}

    public record Cultivo(
            Integer cultivoId,
            Long variedadId,
            Long parcelaId,
            String parcelaNombre,
            LocalDate fecha
    ) {}

    public record Crianza(
            Integer especieId,
            String nombre,
            Integer cantidad,
            LocalDate fecha,
            String observacion
    ) {}

    public record Conteo(Long loteId, Integer cantidad, LocalDate fecha, String observacion) {}
    public record Actuacion(String tipo, String observacion, LocalDateTime fechaHecho, Long crianzaId, Long cultivoId) {}
    public record Ficha(BigDecimal areaTotalHa, BigDecimal areaCultivableHa, String tipoRiego) {}
    public record Vinculo(Long personaId) {}
}
