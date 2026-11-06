package com.franco.desco.adapter.in.web.expediente;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import jakarta.validation.Valid;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class E1WebTypes {
    private E1WebTypes() {}
    @Schema(name="E1PersonaRequest")
    public record PersonaRequest(@NotBlank String tipoDocumento, @NotBlank String numeroDocumento,
       String nombres,String apellidoPaterno,String apellidoMaterno,
       LocalDate fechaNacimiento,@Size(max=30) String telefono,@Email @Size(max=180) String correo,
       @Pattern(regexp="(?:\\d{6})?") String distritoCodigo,
       @Positive Long centroPobladoId,@Size(max=300) String referencia) {}
    @Schema(name="E1PredioAltaRequest")
    public record PredioRequest(@NotNull @Positive Long personaId,@NotBlank String nombre,
        @NotBlank @Pattern(regexp="\\d{6}") String distritoCodigo,String referencia,
        @DecimalMin("-90") @DecimalMax("90") BigDecimal latitud,
        @DecimalMin("-180") @DecimalMax("180") BigDecimal longitud,
        @Positive Long centroPobladoId,
        @DecimalMin("0.0001") @Digits(integer=6,fraction=4) BigDecimal areaTotalHa,
        @DecimalMin("0.0") @Digits(integer=6,fraction=4) BigDecimal areaCultivableHa,
        @Size(max=30) String tipoRiego,
        @DecimalMin("-500") @DecimalMax("7000") BigDecimal altitudM,
        @Size(max=150) String fuenteAgua, @Size(max=300) String infraestructura,
        @Size(max=500) String observacion, @PastOrPresent LocalDate fechaRegistro,
        @PastOrPresent LocalDate fechaDesde,
        @Size(max=20) String tipoTitularidadPrincipal,
        List<@Valid TitularAdicionalRequest> titularesAdicionales) {
        @AssertTrue @Schema(hidden=true) public boolean isCoordenadasValidas(){return (latitud==null)==(longitud==null);}
        @AssertTrue @Schema(hidden=true) public boolean isAreasCoherentes(){
            return areaTotalHa==null||areaCultivableHa==null||areaCultivableHa.compareTo(areaTotalHa)<=0;
        }
    }
    @Schema(name="E1TitularAdicionalRequest")
    public record TitularAdicionalRequest(@NotNull @Positive Long personaId,
        @NotBlank @Size(max=20) String tipoTitularidad,
        @NotNull @DecimalMin("0.01") @DecimalMax("99.99") @Digits(integer=2,fraction=2) BigDecimal porcentaje) {}
    @Schema(name="E1CultivoRequest")
    public record CultivoRequest(@NotNull @Positive Integer cultivoId,@Positive Long variedadId,
       @Positive Long parcelaId,String parcelaNombre,LocalDate fecha) {}
    @Schema(name="E1CrianzaRequest")
    public record CrianzaRequest(@NotNull @Positive Integer especieId,String nombre,@PositiveOrZero Integer cantidad,
       LocalDate fecha,String observacion) {}
    @Schema(name="E1ConteoRequest")
    public record ConteoRequest(@NotNull @Positive Long loteId,@PositiveOrZero Integer cantidad,LocalDate fecha,String observacion) {}
    @Schema(name="E1ActuacionRequest")
    public record ActuacionRequest(@NotBlank String tipo,@NotBlank @Size(min=3,max=2000) String observacion,
       LocalDateTime fechaHecho,@Positive Long crianzaId,@Positive Long cultivoId) {}
    @Schema(name="E1FichaRequest")
    public record FichaRequest(@DecimalMin("0.0001") BigDecimal areaTotalHa,
       @DecimalMin("0.0") BigDecimal areaCultivableHa,String tipoRiego) {}
    @Schema(name="E1VinculoRequest")
    public record VinculoRequest(@NotNull @Positive Long personaId) {}
    @Schema(name="E1IdentificadorResponse") public record Id(Long id) {}
    @Schema(name="E1ConvenioResponse") public record Convenio(Long id,String nombre) {}
    @Schema(name="E1ConveniosResponse") public record Convenios(List<Convenio> items) {}
    @Schema(name="E1PersonaResponse") public record Persona(Long personaId,String tipoDocumento,String numeroDocumento,String nombreCompleto) {}
    @Schema(name="E1PersonasResponse") public record Personas(List<Persona> items) {}
    @Schema(name="E1PredioResumenResponse") public record PredioResumen(Long predioId,String codigo,String nombre,
        String distritoCodigo,String referencia,BigDecimal latitud,BigDecimal longitud,String titular) {}
    @Schema(name="E1PrediosResponse") public record Predios(List<PredioResumen> items) {}
    @Schema(name="E1CatalogoResponse") public record Catalogo(Integer id,String nombre) {}
    @Schema(name="E1VariedadResponse") public record Variedad(Long id,Integer padreId,String nombre) {}
    @Schema(name="E1CatalogosResponse") public record Catalogos(List<Catalogo> cultivos,List<Variedad> variedades,List<Catalogo> especies) {}
    @Schema(name="E1TitularResponse") public record Titular(Long personaId,Long socioId,String numeroDocumento,String nombreCompleto,
        String tipoTitularidad,BigDecimal porcentaje,String rolTitularidad) {}
    @Schema(name="E1CultivoResponse") public record Cultivo(Long id,String cultivo,String variedad,String parcela,LocalDate fechaInicio,LocalDate fechaFin) {}
    @Schema(name="E1CrianzaResponse") public record Crianza(Long id,String especie,String lote,LocalDate fechaInicio,Integer cantidadActual) {}
    @Schema(name="E1ActuacionResponse") public record Actuacion(Long id,String tipo,String observacion,LocalDateTime fechaHecho,
        LocalDateTime fechaRegistro,String autor,Long cultivoId,Long crianzaId,Long salidaId,Long visitaId) {}
    @Schema(name="E1CensoResponse") public record Censo(Long id,String cultivo,LocalDate fecha,Integer total,Integer productivas,String observacion) {}
    @Schema(name="E1ConteoResponse") public record Conteo(Long id,Long crianzaId,Integer cantidad,LocalDate fechaHecho,String observacion) {}
    @Schema(name="E1ExpedienteResponse")
    public record Expediente(Long predioId,String codigo,String nombre,String distritoCodigo,String referencia,
        BigDecimal latitud,BigDecimal longitud,BigDecimal areaTotalHa,BigDecimal areaCultivableHa,String tipoRiego,
        boolean fichaCompleta,List<Titular> titulares,List<Cultivo> cultivos,List<Crianza> crianzas,
        List<Actuacion> historial,List<Censo> censos,List<Conteo> conteos) {}
}
