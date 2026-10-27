package com.franco.desco.application.identity.service;

import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.application.identity.port.in.IdentityUseCase;
import com.franco.desco.application.identity.port.out.IdentityPersistencePort;
import com.franco.desco.application.identity.port.out.IdentityProviderPort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.LocalResolution;
import com.franco.desco.domain.identity.IdentityModels.Origin;
import com.franco.desco.domain.identity.IdentityModels.PersistOutcome;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import com.franco.desco.domain.identity.IdentityModels.Reservation;
import com.franco.desco.domain.identity.IdentityModels.ResolutionResult;
import com.franco.desco.domain.identity.IdentityModels.Target;
import com.franco.desco.domain.identity.PeruvianDocumentRules;

import java.time.Instant;

public final class IdentityApplicationService
        implements IdentityUseCase {

    private static final String MANUAL_MESSAGE =
            "Complete los datos manualmente.";

    private static final String TEMPORARY_MESSAGE =
            "No se pudo validar el documento.";

    private static final String AUTOMATIC_LOOKUP_DISABLED_MESSAGE =
            "Complete los datos manualmente.";

    private final IdentityPersistencePort persistence;
    private final IdentityProviderPort provider;
    private final boolean externalProviderEnabled;

    public IdentityApplicationService(
            IdentityPersistencePort persistence,
            IdentityProviderPort provider,
            boolean externalProviderEnabled
    ) {
        this.persistence = persistence;
        this.provider = provider;
        this.externalProviderEnabled = externalProviderEnabled;
    }

    @Override
    public AppResult<ResolutionResult> resolve(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        String document = PeruvianDocumentRules.normalize(
                command.numeroDocumento()
        );

        ResolveDocument normalized = new ResolveDocument(
                command.entidadObjetivo(),
                command.tipoDocumento(),
                document
        );

        boolean manualCompanyRuc =
                !externalProviderEnabled
                        && normalized.entidadObjetivo() == Target.EMPRESA
                        && normalized.tipoDocumento() == DocumentType.RUC
                        && hasElevenDigits(
                                normalized.numeroDocumento()
                        );

        if (!manualCompanyRuc
                && !PeruvianDocumentRules.validFor(
                        normalized.entidadObjetivo(),
                        normalized.tipoDocumento(),
                        normalized.numeroDocumento()
                )) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "DOCUMENTO_INVALIDO",
                    "El documento ingresado no es válido."
            );
        }

        PersistenceResult<LocalResolution> localResult =
                persistence.resolveLocal(
                        normalized,
                        identity,
                        metadata
                );

        if (!localResult.exitoso()
                || localResult.datos() == null) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "IDENTIDAD_NO_DISPONIBLE",
                    TEMPORARY_MESSAGE
            );
        }

        LocalResolution local = localResult.datos();

        if (local.encontradoLocal()) {
            return AppResult.ok(
                    "IDENTIDAD_LOCAL",
                    "La información ya se encuentra registrada.",
                    fromLocal(
                            local,
                            false,
                            null
                    )
            );
        }

        if (!local.requiereConsultaExterna()) {
            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    manual(
                            local,
                            local.estadoConsultaPrevia()
                    )
            );
        }

        /*
         * Factiliza es opcional. La búsqueda local siempre ocurre primero.
         * Cuando el proveedor está deshabilitado se corta el flujo antes de
         * reservar una consulta externa y se habilita el registro manual.
         */
        if (!externalProviderEnabled) {
            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    AUTOMATIC_LOOKUP_DISABLED_MESSAGE,
                    manual(
                            local,
                            local.estadoConsultaPrevia()
                    )
            );
        }

        PersistenceResult<Reservation> reservationResult =
                persistence.reserveExternalQuery(
                        normalized,
                        identity,
                        metadata
                );

        if (!reservationResult.exitoso()
                || reservationResult.datos() == null) {
            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    manual(
                            local,
                            local.estadoConsultaPrevia()
                    )
            );
        }

        Reservation reservation =
                reservationResult.datos();

        if (!reservation.puedeConsultar()) {
            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    manual(
                            local,
                            local.estadoConsultaPrevia(),
                            reservation.reintentoDesdeUtc()
                    )
            );
        }

        ProviderResult providerResult =
                provider.query(
                        reservation.tipoDocumentoConsultaExterna(),
                        reservation.numeroDocumentoConsultaExterna()
                );

        PersistenceResult<PersistOutcome> persistenceResult =
                persistence.registerExternalResult(
                        normalized,
                        providerResult,
                        identity,
                        metadata
                );

        if (!persistenceResult.exitoso()
                || persistenceResult.datos() == null) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "VALIDACION_NO_COMPLETADA",
                    TEMPORARY_MESSAGE
            );
        }

        PersistOutcome outcome =
                persistenceResult.datos();

        if (outcome.entidadId() == null) {
            String suggestedAddress =
                    providerResult.datos() == null
                            ? null
                            : providerResult.datos().direccionFiscal();

            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    manual(
                            local,
                            outcome.estadoConsulta(),
                            reservation.reintentoDesdeUtc(),
                            suggestedAddress
                    )
            );
        }

        /*
         * La respuesta se relee desde DESCO_DB después de persistir.
         * De este modo fecha de nacimiento, ubicación y catálogos geográficos
         * enviados al frontend son exactamente los datos que quedaron guardados.
         */
        PersistenceResult<LocalResolution> refreshedResult =
                persistence.resolveLocal(
                        normalized,
                        identity,
                        metadata
                );

        if (!refreshedResult.exitoso()
                || refreshedResult.datos() == null
                || !refreshedResult.datos().encontradoLocal()) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "VALIDACION_NO_COMPLETADA",
                    TEMPORARY_MESSAGE
            );
        }

        String suggestedAddress =
                providerResult.datos() == null
                        ? null
                        : providerResult.datos().direccionFiscal();

        return AppResult.ok(
                outcome.insertado()
                        ? "IDENTIDAD_IMPORTADA"
                        : "IDENTIDAD_REUTILIZADA",
                outcome.insertado()
                        ? "Los datos disponibles fueron validados y guardados correctamente."
                        : "La información ya se encuentra registrada.",
                fromLocal(
                        refreshedResult.datos(),
                        outcome.insertado(),
                        suggestedAddress
                )
        );
    }

    private ResolutionResult fromLocal(
            LocalResolution value,
            boolean inserted,
            String suggestedAddress
    ) {
        String resolvedAddress =
                hasText(suggestedAddress)
                        ? suggestedAddress.trim()
                        : value.referenciaUbicacion();

        return new ResolutionResult(
                Origin.LOCAL,
                true,
                inserted,
                false,
                value.entidadObjetivo(),
                value.entidadId(),
                value.tipoPersona(),
                value.tipoDocumento(),
                value.numeroDocumento(),
                value.nombres(),
                value.apellidoPaterno(),
                value.apellidoMaterno(),
                value.telefono(),
                value.correo(),
                value.razonSocial(),
                value.fechaNacimiento(),
                value.sexo(),
                value.ubicacionId(),
                value.departamentoCodigo(),
                value.departamentoNombre(),
                value.provinciaCodigo(),
                value.provinciaNombre(),
                value.distritoCodigo(),
                value.distritoNombre(),
                value.centroPobladoId(),
                value.centroPobladoNombre(),
                value.referenciaUbicacion(),
                value.estadoEntidad(),
                value.esEmpleado(),
                value.esSocio(),
                value.esAsociacion(),
                value.estadoConsultaPrevia(),
                resolvedAddress,
                value.reintentoDesdeUtc()
        );
    }

    private ResolutionResult manual(
            LocalResolution local,
            String status
    ) {
        return manual(
                local,
                status,
                local.reintentoDesdeUtc(),
                null
        );
    }

    private ResolutionResult manual(
            LocalResolution local,
            String status,
            Instant retryFrom
    ) {
        return manual(
                local,
                status,
                retryFrom,
                null
        );
    }

    private ResolutionResult manual(
            LocalResolution local,
            String status,
            Instant retryFrom,
            String suggestedAddress
    ) {
        return new ResolutionResult(
                Origin.MANUAL,
                false,
                false,
                true,
                local.entidadObjetivo(),
                null,
                local.tipoPersona(),
                local.tipoDocumento(),
                local.numeroDocumento(),
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
                null,
                null,
                null,
                null,
                null,
                false,
                false,
                false,
                status,
                suggestedAddress,
                retryFrom
        );
    }

    private boolean hasElevenDigits(
            String value
    ) {
        return value != null
                && value.matches("\\d{11}");
    }

    private boolean hasText(
            String value
    ) {
        return value != null && !value.isBlank();
    }
}
