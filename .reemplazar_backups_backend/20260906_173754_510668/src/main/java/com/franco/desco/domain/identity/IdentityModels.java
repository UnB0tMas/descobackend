package com.franco.desco.domain.identity;

import java.time.Instant;
import java.time.LocalDate;

public final class IdentityModels {

    private IdentityModels() {
    }

    public enum Target {
        PERSONA,
        EMPRESA
    }

    public enum DocumentType {
        DNI,
        RUC
    }

    /*
     * VERIFICAPE se conserva temporalmente por compatibilidad binaria con
     * componentes antiguos. El flujo nuevo persiste primero y responde como
     * LOCAL para mantener el contrato actual del frontend sin exponer el
     * proveedor externo al usuario.
     */
    public enum Origin {
        LOCAL,
        VERIFICAPE,
        MANUAL
    }

    public record LocalResolution(
            boolean encontradoLocal,
            Target entidadObjetivo,
            Long entidadId,
            String tipoPersona,
            DocumentType tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String razonSocial,
            Boolean estadoEntidad,
            boolean esEmpleado,
            boolean esSocio,
            boolean esAsociacion,
            boolean requiereConsultaExterna,
            DocumentType tipoDocumentoConsultaExterna,
            String numeroDocumentoConsultaExterna,
            String claveConsulta,
            String estadoConsultaPrevia,
            Instant reintentoDesdeUtc,
            Instant bloqueoHastaUtc
    ) {
    }

    public record Reservation(
            boolean puedeConsultar,
            DocumentType tipoDocumentoConsultaExterna,
            String numeroDocumentoConsultaExterna,
            String claveConsulta,
            Instant reintentoDesdeUtc
    ) {
    }

    /*
     * Contrato interno proveedor -> persistencia.
     *
     * Los primeros seis campos se mantienen en el mismo orden que el modelo
     * anterior. El constructor de seis parámetros conserva compatibilidad con
     * adapters legacy que todavía compilen contra ProviderData.
     *
     * Los campos geográficos adicionales se serializan como parte de "datos"
     * y son consumidos por PA_Identidad_Upd_ResultadoConsultaExterna.
     */
    public record ProviderData(
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            LocalDate fechaNacimiento,
            String razonSocial,
            String direccionFiscal,
            String direccionCompleta,
            String sexo,
            String departamento,
            String provincia,
            String distrito,
            String departamentoCodigo,
            String provinciaCodigo,
            String distritoCodigo,
            String centroPoblado,
            String centroPobladoCodigo,
            String ubigeoReniec,
            String ubigeoSunat,
            String tipoContribuyente,
            String estadoContribuyente,
            String condicionContribuyente
    ) {
        public ProviderData(
                String nombres,
                String apellidoPaterno,
                String apellidoMaterno,
                LocalDate fechaNacimiento,
                String razonSocial,
                String direccionFiscal
        ) {
            this(
                    nombres,
                    apellidoPaterno,
                    apellidoMaterno,
                    fechaNacimiento,
                    razonSocial,
                    direccionFiscal,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null
            );
        }
    }

    public record ProviderResult(
            boolean exito,
            boolean encontrado,
            String codigoError,
            ProviderData datos
    ) {
        public static ProviderResult success(ProviderData data) {
            return new ProviderResult(true, true, null, data);
        }

        public static ProviderResult notFound(String code) {
            return new ProviderResult(true, false, code, null);
        }

        public static ProviderResult error(String code) {
            return new ProviderResult(false, false, code, null);
        }
    }

    public record PersistOutcome(
            boolean insertado,
            boolean permiteCargaManual,
            Long entidadId,
            String estadoConsulta
    ) {
    }

    public record ResolutionResult(
            Origin origen,
            boolean encontrado,
            boolean insertadoAutomaticamente,
            boolean permiteCargaManual,
            Target entidadObjetivo,
            Long entidadId,
            String tipoPersona,
            DocumentType tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String razonSocial,
            Boolean estadoEntidad,
            boolean esEmpleado,
            boolean esSocio,
            boolean esAsociacion,
            String estadoConsulta,
            String direccionFiscalSugerida,
            Instant reintentoDesdeUtc
    ) {
    }
}
