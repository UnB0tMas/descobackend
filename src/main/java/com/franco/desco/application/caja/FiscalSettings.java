package com.franco.desco.application.caja;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Configuración en servidor; las credenciales nunca forman parte del comprobante ni del API. */
@Component
public class FiscalSettings {
    private static final Logger log = LoggerFactory.getLogger(FiscalSettings.class);
    @Value("${desco.facturacion-electronica.enabled:false}") private boolean enabled;
    @Value("${desco.facturacion-electronica.proveedor:SUNAT}") private String provider;
    @Value("${desco.facturacion-electronica.ambiente:BETA}") private String environment;
    @Value("${desco.facturacion-electronica.endpoint:}") private String endpoint;
    @Value("${desco.facturacion-electronica.api-key:}") private String apiKey;
    @Value("${desco.facturacion-electronica.usuario-sol:}") private String solUser;
    @Value("${desco.facturacion-electronica.clave-sol:}") private String solPassword;
    @Value("${desco.facturacion-electronica.certificado-ruta:}") private String certificatePath;
    @Value("${desco.facturacion-electronica.certificado-clave:}") private String certificatePassword;
    @Value("${desco.facturacion-electronica.emisor-ruc:}") private String issuerRuc;
    @Value("${desco.facturacion-electronica.emisor-razon-social:}") private String issuerName;
    @Value("${desco.facturacion-electronica.emisor-direccion:}") private String issuerAddress;
    @Value("${desco.facturacion-electronica.serie-boleta:B001}") private String receiptSeries;
    @Value("${desco.facturacion-electronica.serie-factura:F001}") private String invoiceSeries;

    @PostConstruct
    public void validateConfiguration() {
        if (enabled) {
            log.warn("[FACTURACION] Integración activada. Se conservarán documentos pendientes; " +
                    "el transporte firmado y la validación CDR requieren el adaptador SUNAT/PSE.");
            if (!integrationConfigured()) {
                log.warn("[FACTURACION] Faltan parámetros de integración, no se intentará emitir.");
            }
        }
    }

    public boolean enabled() { return enabled; }
    public String issuerRuc() { return issuerRuc; }
    public String issuerName() { return issuerName; }
    public String issuerAddress() { return issuerAddress; }
    public String receiptSeries() { return receiptSeries; }
    public String invoiceSeries() { return invoiceSeries; }

    /** Habilitar el flag no equivale a emitir: faltan XML firmado, transporte y CDR. */
    public boolean integrationConfigured() {
        return enabled && issuerRuc.matches("\\d{11}") && !issuerName.isBlank()
                && !endpoint.isBlank() && (!apiKey.isBlank() || !solUser.isBlank())
                && !certificatePath.isBlank();
    }
}
