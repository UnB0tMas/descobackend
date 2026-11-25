package com.franco.desco.application.dashboardbi;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboardbi.DashboardBiModels;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.Set;

@Service
public class DashboardBiService {
    private static final ZoneId ZONA = ZoneId.of("America/Lima");
    private static final Set<String> TABS = Set.of("POS", "TECNICA", "RECURSOS", "DOCUMENTOS");
    private final DashboardBiPort port;

    public DashboardBiService(DashboardBiPort port) {
        this.port = port;
    }

    public AppResult<DashboardBiModels.Segmenters> segmenters(
            SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(port.segmenters(identity, metadata),
                "BI_FILTROS", "BI_FILTROS_NO_DISPONIBLES", AppStatus.BAD_REQUEST);
    }

    public AppResult<DashboardBiModels.Snapshot> load(DashboardBiModels.Filter requested,
            SessionIdentity identity, RequestMetadata metadata) {
        if (requested == null || !TABS.contains(requested.tab())) {
            return AppResult.error(AppStatus.BAD_REQUEST, "BI_TAB_INVALIDO", "Seleccione una sección válida.");
        }
        LocalDate today = LocalDate.now(ZONA);
        LocalDate hasta = requested.hasta() == null ? today : requested.hasta();
        LocalDate desde = requested.desde() == null ? hasta : requested.desde();
        if (desde.isAfter(hasta) || hasta.isAfter(today) || ChronoUnit.DAYS.between(desde, hasta) > 365) {
            return AppResult.error(AppStatus.BAD_REQUEST, "BI_PERIODO_INVALIDO",
                    "Elija un periodo válido de hasta 366 días que no termine en el futuro.");
        }
        if ((requested.almacenId() != null && requested.almacenId() <= 0)
                || (requested.predioId() != null && requested.predioId() <= 0)) {
            return AppResult.error(AppStatus.BAD_REQUEST, "BI_FILTRO_INVALIDO", "El filtro seleccionado no es válido.");
        }
        return ApplicationResults.ok(port.load(new DashboardBiModels.Filter(
                        requested.tab(), desde, hasta, requested.almacenId(), requested.predioId()),
                identity, metadata), "BI_CARGADO", "BI_NO_DISPONIBLE", AppStatus.BAD_REQUEST);
    }
}
