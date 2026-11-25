package com.franco.desco.application.caja;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Un documento canónico por venta. Nunca registra una aceptación SUNAT sin su respuesta real. */
@Service
public class FiscalReceiptService {
    private final JdbcTemplate jdbc;
    private final JsonMapper json;
    private final FiscalSettings settings;

    public record Datos(String tipoDocumento, String serie, Long numero,
                        String emisorRuc, String emisorRazonSocial, String emisorDireccion,
                        String atendidoPor, String qrContenido, String estadoFiscal) {}

    public FiscalReceiptService(JdbcTemplate jdbc, JsonMapper json, FiscalSettings settings) {
        this.jdbc = jdbc;
        this.json = json;
        this.settings = settings;
    }

    @Transactional
    public Datos preparar(long ventaId, long uotId, String uotNombre, String fecha,
                          String cliente, String documento, String moneda,
                          BigDecimal subtotal, BigDecimal impuesto, BigDecimal total,
                          List<Map<String, Object>> lineas) {
        List<Map<String, Object>> almacenados = jdbc.queryForList("""
            SELECT tipo_documento, serie, numero, estado_fiscal, qr_contenido, datos_json
            FROM comercial.ComprobanteFiscalPendiente WITH (UPDLOCK, HOLDLOCK)
            WHERE venta_id = ?
            """, ventaId);
        if (!almacenados.isEmpty() && almacenados.getFirst().get("datos_json") != null) {
            String persisted = (String) almacenados.getFirst().get("datos_json");
            Datos snapshot = json.readValue(persisted, Datos.class);
            String qrSunat = (String) almacenados.getFirst().get("qr_contenido");
            String estado = (String) almacenados.getFirst().get("estado_fiscal");
            return new Datos(snapshot.tipoDocumento(), snapshot.serie(), snapshot.numero(),
                    snapshot.emisorRuc(), snapshot.emisorRazonSocial(), snapshot.emisorDireccion(),
                    snapshot.atendidoPor(), qrSunat == null ? snapshot.qrContenido() : qrSunat,
                    estado);
        }
        String tipo = documento != null && documento.matches("\\d{11}") ? "FACTURA" : "BOLETA";
        String serie = "FACTURA".equals(tipo) ? settings.invoiceSeries() : settings.receiptSeries();
        // Identificador estable, no numeración tributaria confirmada.
        long numero = ventaId;
        String qr = "DESCO|" + uotId + "|" + ventaId + "|" + fecha + "|" + total;
        List<String> operadores = jdbc.query("""
            SELECT COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(P.nombres,' ',P.apellido_paterno,' ',
                           COALESCE(P.apellido_materno,'')))),''),US.nombre_usuario)
            FROM comercial.Venta V
            JOIN seg.Usuario US ON US.usuario_id=V.vendedor_usuario_id
            LEFT JOIN org.Persona P ON P.persona_id=US.persona_id
            WHERE V.venta_id = ? AND V.uot_id = ?
            """, (rs, row) -> rs.getString(1), ventaId, uotId);
        Datos datos = new Datos(tipo, serie, numero, settings.issuerRuc(),
                settings.issuerName().isBlank() ? uotNombre : settings.issuerName(),
                settings.issuerAddress(), operadores.isEmpty() ? "" : operadores.getFirst(), qr,
                "PENDIENTE");
        Map<String, Object> documentoGuardado = new LinkedHashMap<>();
        documentoGuardado.put("datos", datos);
        documentoGuardado.put("ventaId", ventaId);
        documentoGuardado.put("uotId", uotId);
        documentoGuardado.put("fecha", fecha);
        documentoGuardado.put("cliente", cliente);
        documentoGuardado.put("documentoCliente", documento);
        documentoGuardado.put("moneda", moneda);
        documentoGuardado.put("subtotal", subtotal);
        documentoGuardado.put("impuesto", impuesto);
        documentoGuardado.put("total", total);
        documentoGuardado.put("lineas", lineas);
        String documentoJson = json.writeValueAsString(documentoGuardado);
        String datosJson = json.writeValueAsString(datos);
        jdbc.update("""
            IF NOT EXISTS (SELECT 1 FROM comercial.ComprobanteFiscalPendiente WITH (UPDLOCK, HOLDLOCK)
                           WHERE venta_id = ?)
            BEGIN
                INSERT comercial.ComprobanteFiscalPendiente
                    (venta_id, uot_id, tipo_documento, estado_fiscal)
                VALUES (?, ?, ?, 'PENDIENTE')
            END
            """, ventaId, ventaId, uotId, tipo);
        jdbc.update("""
            UPDATE comercial.ComprobanteFiscalPendiente
               SET tipo_documento = ?, serie = ?, numero = ?, datos_json = ?,
                   documento_json = ?, qr_contenido = ?, fecha_actualizacion = SYSUTCDATETIME()
             WHERE venta_id = ? AND datos_json IS NULL AND estado_fiscal = 'PENDIENTE'
            """, tipo, serie, numero, datosJson, documentoJson, qr, ventaId);
        return datos;
    }
}
