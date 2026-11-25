package com.franco.desco.adapter.in.web.dashboardbi;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.dashboardbi.DashboardBiService;
import com.franco.desco.domain.dashboardbi.DashboardBiModels;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/reportes/dashboard")
@Tag(name = "Dashboard BI", description = "Inteligencia de negocios de la UOT, sin módulo especial APAFSA/APAPPSS")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
public class DashboardBiController {
    private final DashboardBiService service;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;

    public DashboardBiController(DashboardBiService service, ApiResponseFactory responses,
                                 JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata) {
        this.service = service;
        this.responses = responses;
        this.identities = identities;
        this.metadata = metadata;
    }

    @GetMapping("/segmentadores")
    @PreAuthorize("@permissionGuard.has(authentication,'DASHBOARD_BI_VER') and @permissionGuard.has(authentication,'REPORTES_CONTROL_VER')")
    @Operation(operationId = "dashboardBiSegmentadores", summary = "Segmentadores autorizados de la UOT")
    public ResponseEntity<ApiResponse<DashboardBiModels.Segmenters>> segmenters(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.segmenters(identities.resolve(authentication),
                metadata.resolve(request)), request, value -> value);
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'DASHBOARD_BI_VER') and @permissionGuard.has(authentication,'REPORTES_CONTROL_VER')")
    @Operation(operationId = "dashboardBiResumen", summary = "Consultar 4 KPI y 4 gráficos por sección",
            description = "Solo devuelve información de la UOT autorizada; fechas interpretadas en America/Lima.")
    public ResponseEntity<ApiResponse<DashboardBiModels.Snapshot>> summary(
            @RequestParam String tab,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            @RequestParam(required = false) Long almacenId,
            @RequestParam(required = false) Long predioId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.load(new DashboardBiModels.Filter(tab, desde, hasta, almacenId, predioId),
                identities.resolve(authentication), metadata.resolve(request)), request, value -> value);
    }
}
