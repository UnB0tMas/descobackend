package com.franco.desco.adapter.in.web.dashboard;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.dashboard.port.in.DashboardUseCase;
import com.franco.desco.domain.dashboard.DashboardModels;
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
@RequestMapping("/api/v1/dashboard")
@Tag(
        name = "Dashboard",
        description = "Indicadores, gráficos, alertas y accesos rápidos autorizados para la sesión."
)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
public class DashboardController {

    private final DashboardUseCase useCase;
    private final DashboardWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public DashboardController(
            DashboardUseCase useCase,
            DashboardWebMapper mapper,
            ApiResponseFactory responses,
            ClientRequestContextResolver metadata,
            JwtSessionIdentityResolver identities
    ) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'INICIO_LISTAR')")
    @Operation(
            operationId = "dashboardResumen",
            summary = "Obtener resumen personalizado del dashboard",
            description = "Devuelve únicamente los KPI y gráficos configurados para los roles o el usuario y que además estén respaldados por permisos vigentes."
    )
    public ResponseEntity<ApiResponse<DashboardResponses.Summary>> summary(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            @Parameter(description = "Fecha inicial del periodo en formato ISO yyyy-MM-dd.")
            LocalDate desde,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            @Parameter(description = "Fecha final del periodo en formato ISO yyyy-MM-dd.")
            LocalDate hasta,
            @Parameter(hidden = true)
            JwtAuthenticationToken authentication,
            @Parameter(hidden = true)
            HttpServletRequest request
    ) {
        DashboardModels.Filter filter = new DashboardModels.Filter(
                desde,
                hasta
        );

        return responses.from(
                useCase.summary(
                        identities.resolve(authentication),
                        metadata.resolve(request),
                        filter
                ),
                request,
                mapper::response
        );
    }
}
