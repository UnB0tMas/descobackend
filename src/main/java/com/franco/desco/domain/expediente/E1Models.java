package com.franco.desco.domain.expediente;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class E1Models {
    private E1Models() {}
    public record Convenio(Long id, String nombre) {}
    public record Convenios(List<Convenio> items) {}
    public record Persona(Long personaId, String tipoDocumento, String numeroDocumento, String nombreCompleto) {}
    public record Personas(List<Persona> items) {}
    public record PredioResumen(Long predioId, String codigo, String nombre, String distritoCodigo, String referencia,
                                BigDecimal latitud, BigDecimal longitud, String titular) {}
    public record Predios(List<PredioResumen> items) {}
    public record Catalogo(Integer id, String nombre) {}
    public record Variedad(Long id, Integer padreId, String nombre) {}
    public record Catalogos(List<Catalogo> cultivos, List<Variedad> variedades, List<Catalogo> especies) { public Catalogos { cultivos=emptyIfNull(cultivos); variedades=emptyIfNull(variedades); especies=emptyIfNull(especies); } }
    public record Titular(Long personaId, Long socioId, String numeroDocumento, String nombreCompleto,
                          String tipoTitularidad, BigDecimal porcentaje, String rolTitularidad) {}
    public record Cultivo(Long id, String cultivo, String variedad, String parcela, LocalDate fechaInicio, LocalDate fechaFin) {}
    public record Crianza(Long id, String especie, String lote, LocalDate fechaInicio, Integer cantidadActual) {}
    public record Actuacion(Long id, String tipo, String observacion, LocalDateTime fechaHecho, LocalDateTime fechaRegistro,
                            String autor, Long cultivoId, Long crianzaId, Long salidaId, Long visitaId) {}
    public record Censo(Long id,String cultivo,LocalDate fecha,Integer total,Integer productivas,String observacion) {}
    public record Conteo(Long id, Long crianzaId, Integer cantidad, LocalDate fechaHecho, String observacion) {}
    public record Expediente(Long predioId, String codigo, String nombre, String distritoCodigo, String referencia,
                             BigDecimal latitud, BigDecimal longitud, BigDecimal areaTotalHa, BigDecimal areaCultivableHa,
                             String tipoRiego, boolean fichaCompleta, List<Titular> titulares, List<Cultivo> cultivos,
                             List<Crianza> crianzas, List<Actuacion> historial, List<Censo> censos, List<Conteo> conteos) { public Expediente { titulares=emptyIfNull(titulares); cultivos=emptyIfNull(cultivos); crianzas=emptyIfNull(crianzas); historial=emptyIfNull(historial); censos=emptyIfNull(censos); conteos=emptyIfNull(conteos); } }
    private static <T> List<T> emptyIfNull(List<T> values) { return values == null ? List.of() : List.copyOf(values); }
    public record Identificador(Long id) {}
}
