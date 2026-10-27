package com.franco.desco.application.dashboard.service;

import com.franco.desco.application.dashboard.port.in.DashboardUseCase;
import com.franco.desco.application.dashboard.port.out.DashboardPersistencePort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboard.DashboardModels;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;

public final class DashboardApplicationService implements DashboardUseCase {

    private static final long MAX_DAYS_BETWEEN = 365L;
    private static final long DEFAULT_DAYS_BETWEEN = 89L;

    private final DashboardPersistencePort persistence;

    public DashboardApplicationService(
            DashboardPersistencePort persistence
    ) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<DashboardModels.Summary> summary(
            SessionIdentity identity,
            RequestMetadata metadata,
            DashboardModels.Filter filter
    ) {
        DashboardModels.Filter normalized = normalize(filter);

        if (normalized.desde().isAfter(normalized.hasta())) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "DASHBOARD_PERIODO_INVALIDO",
                    "La fecha desde no puede ser posterior a la fecha hasta."
            );
        }

        if (ChronoUnit.DAYS.between(
                normalized.desde(),
                normalized.hasta()
        ) > MAX_DAYS_BETWEEN) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "DASHBOARD_PERIODO_EXCEDIDO",
                    "El dashboard admite como máximo 366 días por consulta."
            );
        }

        LocalDate today = LocalDate.now(ZoneOffset.UTC);

        if (normalized.hasta().isAfter(today)) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "DASHBOARD_FECHA_FUTURA",
                    "La fecha hasta no puede ser posterior a la fecha actual."
            );
        }

        return ApplicationResults.ok(
                persistence.summary(identity, metadata, normalized),
                "DASHBOARD_CARGADO",
                "DASHBOARD_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }

    private DashboardModels.Filter normalize(
            DashboardModels.Filter requested
    ) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        LocalDate requestedUntil = requested == null
                ? null
                : requested.hasta();
        LocalDate requestedFrom = requested == null
                ? null
                : requested.desde();

        LocalDate until = requestedUntil == null
                ? today
                : requestedUntil;
        LocalDate from = requestedFrom == null
                ? until.minusDays(DEFAULT_DAYS_BETWEEN)
                : requestedFrom;

        return new DashboardModels.Filter(from, until);
    }
}
