
package com.franco.desco.adapter.in.web.e5;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

public final class E5ExtrasWebTypes {
    private E5ExtrasWebTypes() {}

    @Schema(name="E5GraficoDiaResponse")
    public record Dia(String fecha,BigDecimal kilogramos,BigDecimal ventaEfectiva) {}
    @Schema(name="E5GraficoVariedadResponse")
    public record Variedad(Short variedadId,String variedad,BigDecimal kilogramos,BigDecimal ventaEfectiva) {}
    @Schema(name="E5GraficosResponse")
    public record Graficos(Long campaniaId,String fechaInicio,String fechaFin,Short variedadPaltaId,
        List<Dia> porDia,List<Variedad> porVariedad) {}
    @Schema(name="E5EntregaSocioDetalleResponse")
    public record Entrega(Long entregaId,String lote,String fecha,Integer jabas,BigDecimal pesoBruto,
        BigDecimal tara,BigDecimal rechazado,BigDecimal aceptado) {}
    @Schema(name="E5PartidaSocioResponse")
    public record Partida(Long detalleId,Long entregaId,String variedad,Long condicionId,String condicion,
        BigDecimal kilogramos,BigDecimal precioBase,BigDecimal precioEfectivo,BigDecimal importe) {}
    @Schema(name="E5JabaSocioResponse")
    public record Jaba(Long entregaId,Long unidadId,Integer numero,BigDecimal pesoBruto,BigDecimal tara,BigDecimal pesoNeto) {}
    @Schema(name="E5EntregasSocioResponse")
    public record EntregasSocio(Long participacionId,List<Entrega> entregas,List<Partida> partidas,List<Jaba> jabas) {}
    @Schema(name="E5CobroMovimientoResponse")
    public record CobroMovimiento(Long cobroId,String fecha,BigDecimal importe,String moneda,String estado,
        String medioPago,String numeroOperacion) {}
    @Schema(name="E5CobrosDetalleResponse")
    public record CobrosDetalle(Long campaniaId,List<CobroMovimiento> movimientos) {}
    @Schema(name="E5PagoBeneficiarioHistorialResponse")
    public record Historial(Long pagoId,Long beneficiarioPersonaId,String documento,String nombre,Long usuarioId,String fecha,String motivoEntrega,Long comprobanteArchivoId) {}
    @Schema(name="E5BeneficiarioResponse")
    public record Beneficiario(Long liquidacionId,Long beneficiarioPersonaId,String documento,String nombre,Long uotId,
        List<Historial> historial) {}
    @Schema(name="E5ReceptorRequest")
    public record Receptor(@NotBlank @Size(max=15) String tipoDocumento,
        @NotBlank @Size(max=30) String numeroDocumento,
        @Size(max=100) String nombres,@Size(max=80) String apellidoPaterno,
        @Size(max=80) String apellidoMaterno,@Size(max=30) String telefono,
        @Size(max=180) String correo,String fechaNacimiento,
        @Size(max=20) String sexo,Long identityId) {}
    @Schema(name="E5ReceptorRegistradoResponse")
    public record ReceptorRegistrado(Long personaId) {}
    @Schema(name="E5PagoBeneficiarioRequest")
    public record Pago(@NotNull @DecimalMin("0.01") @Digits(integer=17,fraction=2) BigDecimal importe,
        @NotBlank @Pattern(regexp="YAPE|PLIN|EFECTIVO|DEPOSITO") String medioPago,
        @Size(max=100) String referencia,@NotNull @Positive Long beneficiarioPersonaId,
        @Size(max=500) String motivoEntrega,@Positive Long comprobanteArchivoId) {}
}
