package com.franco.desco.adapter.in.web.e4;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

public final class E4WebTypes {
    private E4WebTypes() {}
    @Schema(name="E4StockRequest")
    public record Stock(@NotNull @Min(0) Integer existenciaCertificada,
                        @NotBlank @Size(max=400) String motivo) {}
    @Schema(name="E4StockResponse")
    public record StockResultado(Long uotId,Integer existenciaCertificada,Long retenidas) {}
    @Schema(name="E4PesajePreliminarRequest")
    public record PesajePreliminar(@NotNull @Digits(integer=11,fraction=3) @DecimalMin("0.001") BigDecimal pesoBrutoKg) {}
    @Schema(name="E4PesajeAnulacionRequest")
    public record PesajeAnulacion(@NotNull @Positive Long version,@NotBlank @Size(max=400) String motivo) {}
    @Schema(name="E4PesajeCorreccionRequest")
    public record PesajeCorreccion(@NotNull @Digits(integer=11,fraction=3) @DecimalMin("0.001") BigDecimal pesoBrutoKg,
               @NotNull @Positive Long variedadId,@NotNull @Positive Long condicionId,
               @NotNull @Positive Long version,@NotBlank @Size(max=400) String motivo,
               @Digits(integer=7,fraction=3) @DecimalMin("0.000") BigDecimal taraExcepcionalKg) {}
    @Schema(name="E4PesajeGestionResponse")
    public record PesajeGestion(Long unidadId,String estado,BigDecimal pesoBrutoKg,
                                BigDecimal taraKg,BigDecimal pesoNetoKg) {}
    @Schema(name="E4RetornoValidarRequest")
    public record RetornoValidar(@Size(max=400) String motivo) {}
    @Schema(name="E4RetornoValidacionResponse")
    public record RetornoValidacion(Long asignacionId,Integer validadas) {}
    @Schema(name="E4PesajeEventoResponse")
    public record PesajeEvento(Long historialId,Long versionAnterior,Long versionNueva,
           String estadoAnterior,String estadoNuevo,BigDecimal pesoAnterior,BigDecimal pesoNuevo,
           BigDecimal taraAnterior,BigDecimal taraNueva,BigDecimal precioAnterior,BigDecimal precioNuevo,
           String motivo,Long usuarioId,String fechaHora) {}
    @Schema(name="E4HistorialResponse")
    public record Historial(Long unidadId,List<PesajeEvento> eventos) {}
    @Schema(name="E4ConfiguracionRequest")
    public record Configuracion(@NotNull @Min(1) @Max(100000) Integer cupoJabas,
                                @NotNull @DecimalMin("0") @DecimalMax("9.999") BigDecimal taraKg) {}
    @Schema(name="E4IncorporarSociosRequest")
    public record Incorporacion(@NotEmpty @Size(max=100) List<@NotNull @Positive Long> sociosIds) {}
    @Schema(name="E4SocioElegibleResponse")
    public record SocioElegible(Long socioAsociacionId, String nombre, String numeroDocumento) {}
    @Schema(name="E4SociosElegiblesResponse")
    public record SociosElegibles(Long campaniaId, List<SocioElegible> socios) {}
    @Schema(name="E4IncorporacionResultadoResponse")
    public record IncorporacionResultado(Long campaniaId, Integer incorporados) {}
    @Schema(name="E4AsignacionRequest")
    public record Asignacion(@NotNull @Min(1) @Max(3000) Integer cantidad) {}
    @Schema(name="E4PesajeRequest")
    public record Pesaje(@NotNull @Digits(integer=11,fraction=3) @DecimalMin("0.001") BigDecimal pesoBrutoKg,
                         @NotNull @Positive Long variedadId, @NotNull @Positive Long condicionId) {}
    @Schema(name="E4ClasificacionLineaRequest")
    public record ClasificacionLinea(@NotNull @DecimalMin("0.001") BigDecimal pesoKg,
                                     @NotNull Boolean rechazada,
                                     @Positive Long variedadId,@Positive Long condicionId) {}
    @Schema(name="E4ClasificacionRequest")
    public record Clasificacion(@NotEmpty @Size(max=10)
                                List<@Valid ClasificacionLinea> lineas,
                                @NotBlank @Size(max=400) String motivo) {}
    @Schema(name="E4ClasificacionResultadoResponse")
    public record ClasificacionResultado(Long unidadId,Integer lineas,BigDecimal kilosAceptados,
                                        BigDecimal kilosRechazados) {}
    @Schema(name="E4ClasificacionDetalleResponse")
    public record ClasificacionDetalle(Integer numero,BigDecimal pesoKg,Boolean rechazada,
                                      Long variedadId,Long condicionId,BigDecimal precioBase) {}
    @Schema(name="E4DevolucionRequest")
    public record Devolucion(@NotNull @Min(0) Integer llenas,@NotNull @Min(0) Integer vacias) {}
    @Schema(name="E4SancionRequest")
    public record Sancion(@NotNull @DecimalMin("0") BigDecimal precioNuevo,
                          @Positive Long condicionId,@Positive Long variedadId,
                          @NotBlank @Size(max=400) String motivo) {}
    @Schema(name="E4TarifaRequest")
    public record Tarifa(@NotNull @DecimalMin("0") BigDecimal precioUnitario) {}
    @Schema(name="E4CargoRequest")
    public record Cargo(@NotBlank @Size(max=400) String motivo) {}
    @Schema(name="E4PrecioResponse")
    public record Precio(Long variedadId,Long condicionId,BigDecimal precio,Integer version) {}
    @Schema(name="E4ResumenResponse")
    public record Resumen(Long campaniaId,String nombre,String estado,Integer cupoJabas,BigDecimal taraKg,
                          Integer stockFisico,Long stockRetenido,Long jabasPendientes,Long unidades,List<Precio> precios) {}
    @Schema(name="E4UnidadResponse")
    public record Unidad(Long unidadId,Integer numero,BigDecimal pesoBrutoKg,BigDecimal taraKg,
                         BigDecimal pesoNetoKg,Long variedadId,Long condicionId,BigDecimal precioBase,
                         String pesaje,String retorno,Long entregaId,Long version,
                         List<ClasificacionDetalle> clasificaciones) {}
    @Schema(name="E4UnidadesResponse")
    public record Unidades(Long asignacionId,Integer asignadas,Boolean retornoValidado,
                           Long pesadas,Long devueltas,Long faltantes,List<Unidad> unidades) {}
    @Schema(name="E4ConfiguracionResponse")
    public record ConfiguracionResultado(Long campaniaId,Integer cupoJabas,BigDecimal taraKg) {}
    @Schema(name="E4AsignacionResponse")
    public record AsignacionResultado(Long asignacionId,Integer unidades) {}
    @Schema(name="E4PesajeResponse")
    public record PesajeResultado(Long unidadId,BigDecimal pesoBrutoKg,BigDecimal taraKg,
                                  BigDecimal pesoNetoKg,BigDecimal precioBase) {}
    @Schema(name="E4DevolucionResponse")
    public record DevolucionResultado(Long asignacionId,Integer llenas,Integer vacias,Integer faltantes) {}
    @Schema(name="E4EntregaResponse")
    public record EntregaResultado(Long entregaId,BigDecimal kilosAceptados,Integer llenas) {}
    @Schema(name="E4SancionResponse")
    public record SancionResultado(Long sancionId,BigDecimal kilosAfectados,
                                   BigDecimal precioOriginal,BigDecimal precioNuevo,BigDecimal descuento) {}
    @Schema(name="E4TarifaResponse")
    public record TarifaResultado(Long tarifaId,BigDecimal precioUnitario) {}
    @Schema(name="E4ValidacionFaltanteResponse")
    public record ValidacionFaltante(Long asignacionId,String estado) {}
    @Schema(name="E4CargoResponse")
    public record CargoResultado(Long cargoId,Integer cantidad,BigDecimal precioUnitario,BigDecimal importe) {}
    @Schema(name="E4PrebalanceResponse")
    public record Prebalance(Long campaniaId,BigDecimal brutoConfirmado,
                             BigDecimal descuentosPrecio,BigDecimal cargosIndividuales) {}
}
