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
import com.franco.desco.domain.identity.IdentityModels.LocalResolution;
import com.franco.desco.domain.identity.IdentityModels.Origin;
import com.franco.desco.domain.identity.IdentityModels.PersistOutcome;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import com.franco.desco.domain.identity.IdentityModels.Reservation;
import com.franco.desco.domain.identity.IdentityModels.ResolutionResult;
import com.franco.desco.domain.identity.PeruvianDocumentRules;

public final class IdentityApplicationService
        implements IdentityUseCase {

    private static final String MANUAL_MESSAGE =
            "No fue posible completar todos los datos automáticamente. "
                    + "Puede continuar y completar la información manualmente.";

    private static final String TEMPORARY_MESSAGE =
            "No fue posible completar la validación en este momento. "
                    + "Intente nuevamente o continúe con el registro manual.";

    private final IdentityPersistencePort persistence;
    private final IdentityProviderPort provider;

    public IdentityApplicationService(
            IdentityPersistencePort persistence,
            IdentityProviderPort provider
    ) {
        this.persistence = persistence;
        this.provider = provider;
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

        if (!PeruvianDocumentRules.validFor(
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

        /*
         * Regla principal:
         * si ya existe en DESCO, jamás consumir la API.
         * Los datos faltantes se completan posteriormente mediante los
         * formularios normales de la entidad.
         */
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

        /*
         * El resultado externo siempre pasa por SQL Server.
         * La BD decide si:
         * - inserta Persona/Empresa;
         * - crea catálogo geográfico faltante;
         * - crea Ubicacion;
         * - habilita carga manual;
         * - reutiliza una entidad que otra solicitud insertó en paralelo.
         */
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
                    new ResolutionResult(
                            Origin.MANUAL,
                            false,
                            false,
                            outcome.permiteCargaManual(),
                            normalized.entidadObjetivo(),
                            null,
                            local.tipoPersona(),
                            normalized.tipoDocumento(),
                            normalized.numeroDocumento(),
                            null,
                            null,
                            null,
                            null,
                            null,
                            false,
                            false,
                            false,
                            outcome.estadoConsulta(),
                            suggestedAddress,
                            reservation.reintentoDesdeUtc()
                    )
            );
        }

        /*
         * Después de persistir la respuesta de Factiliza, se vuelve a leer
         * desde DESCO. Así el HTTP response se construye siempre desde la
         * fuente local y el proveedor queda encapsulado.
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

    /*
     * Se responde como LOCAL incluso después de una importación.
     *
     * Esto es intencional:
     * - la respuesta se arma después de persistir;
     * - evita filtrar el nombre del proveedor al frontend;
     * - mantiene compatible el Angular actual;
     * - insertadoAutomaticamente permite saber si el registro se creó
     *   durante esta resolución.
     */
    private ResolutionResult fromLocal(
            LocalResolution value,
            boolean inserted,
            String suggestedAddress
    ) {
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
                value.razonSocial(),
                value.estadoEntidad(),
                value.esEmpleado(),
                value.esSocio(),
                value.esAsociacion(),
                value.estadoConsultaPrevia(),
                suggestedAddress,
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
                local.reintentoDesdeUtc()
        );
    }

    private ResolutionResult manual(
            LocalResolution local,
            String status,
            java.time.Instant retryFrom
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
                false,
                false,
                false,
                status,
                null,
                retryFrom
        );
    }
}
