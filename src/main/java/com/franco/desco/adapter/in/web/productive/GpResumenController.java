package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.productive.summary.GpResumenDto;
import com.franco.desco.application.productive.summary.GpResumenService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;

@RestController
@RequestMapping("/api/v1/gestion-productiva-general")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class GpResumenController {
    private final GpResumenService servicio;
    private final JwtSessionIdentityResolver identities;

    public GpResumenController(GpResumenService servicio, JwtSessionIdentityResolver identities) {
        this.servicio = servicio;
        this.identities = identities;
    }

    @GetMapping("/actividades/{id}/resumen")
    @Operation(operationId = "gpResumenObtener", summary = "Resumen productivo filtrado")
    @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_VER') && "
            + "@permissionGuard.has(authentication,'CENSOS_LISTAR') && "
            + "@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<GpResumenDto>> obtener(
            @RequestParam @Positive long uotId,
            @PathVariable @Positive long id,
            @RequestParam(defaultValue = "12M")
            @Pattern(regexp = "90D|12M|TODO") String periodo,
            @RequestParam(defaultValue = "TODOS")
            @Pattern(regexp = "TODOS|OBSERVACION|EVALUACION|INCIDENCIA|TRATAMIENTO|RESPUESTA") String tipoEvento,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        GpResumenDto datos = servicio.consultar(identities.resolve(authentication), uotId, id,
                periodo, tipoEvento);
        return ResponseEntity.ok(new ApiResponse<>(true, "GP_RESUMEN_OBTENIDO",
                "Información actualizada.", datos,
                CorrelationIdFilter.correlationId(request), Instant.now()));
    }
}
