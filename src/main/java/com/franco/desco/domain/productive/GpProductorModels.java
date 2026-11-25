package com.franco.desco.domain.productive;

import java.math.BigDecimal;
import java.time.LocalDate;

public final class GpProductorModels {
    private GpProductorModels() {}

    public record Productor(Long personaId, String tipoDocumento, String numeroDocumento,
            String nombres, String apellidoPaterno, String apellidoMaterno, String nombreCompleto,
            String telefono, String correo, LocalDate fechaNacimiento,
            String distritoCodigo, Long centroPobladoId, String referencia) {}

    public record Parcela(Long parcelaId, Long predioId, String codigo, String nombre,
            BigDecimal areaHa, Boolean estado, String distritoCodigo, Long centroPobladoId,
            BigDecimal latitud, BigDecimal longitud, String referencia, String observacion) {}

    public record FichaPersona(String nombres, String apellidoPaterno, String apellidoMaterno,
            String telefono, String correo, String distritoCodigo,
            Long centroPobladoId, String referencia) {}

    public record FichaParcela(String nombre, BigDecimal areaHa, String distritoCodigo,
            Long centroPobladoId, BigDecimal latitud, BigDecimal longitud,
            String referencia, String observacion) {}
}
