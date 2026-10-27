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

    public enum Origin {
        LOCAL,
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
            String telefono,
            String correo,
            String razonSocial,
            LocalDate fechaNacimiento,
            String sexo,
            Long ubicacionId,
            String departamentoCodigo,
            String departamentoNombre,
            String provinciaCodigo,
            String provinciaNombre,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referenciaUbicacion,
            String ubigeoReniec,
            String ubigeoSunat,
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
    }

    public record ProviderResult(
            boolean exito,
            boolean encontrado,
            String codigoError,
            ProviderData datos
    ) {
        public static ProviderResult success(
                ProviderData data
        ) {
            return new ProviderResult(
                    true,
                    true,
                    null,
                    data
            );
        }

        public static ProviderResult notFound(
                String code
        ) {
            return new ProviderResult(
                    true,
                    false,
                    code,
                    null
            );
        }

        public static ProviderResult error(
                String code
        ) {
            return new ProviderResult(
                    false,
                    false,
                    code,
                    null
            );
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
            String telefono,
            String correo,
            String razonSocial,
            LocalDate fechaNacimiento,
            String sexo,
            Long ubicacionId,
            String departamentoCodigo,
            String departamentoNombre,
            String provinciaCodigo,
            String provinciaNombre,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referenciaUbicacion,
            String ubigeoReniec,
            String ubigeoSunat,
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
