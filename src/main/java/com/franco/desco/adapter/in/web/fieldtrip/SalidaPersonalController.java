package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.fieldtrip.personal.SalidaPersonalQuery;
import com.franco.desco.application.fieldtrip.personal.port.in.SalidaPersonalUseCase;
import com.franco.desco.domain.fieldtrip.SalidaPersonalModels;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/salidas-tecnicas/mis-salidas")
@Tag(name="Mis salidas técnicas",description="Consulta personal auditada de salidas E2 y actividad verificable")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class SalidaPersonalController {
    private final SalidaPersonalUseCase service;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    private final ApiResponseFactory responses;

    public SalidaPersonalController(SalidaPersonalUseCase service,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata,
            ApiResponseFactory responses) {
        this.service=service;
        this.identities=identities;
        this.metadata=metadata;
        this.responses=responses;
    }

    @GetMapping
    @Operation(operationId="salidasTecnicasMisSalidas",summary="Listar mis solicitudes y salidas con filtros SQL")
    @PreAuthorize("@permissionGuard.has(authentication,'VISITAS_LISTAR') and @permissionGuard.has(authentication,'SALIDAS_LISTAR')")
    public ResponseEntity<ApiResponse<SalidaPersonalModels.Lista>> listar(
            @RequestParam @Positive Long uotId,
            @RequestParam(required=false) @Size(max=120) String buscar,
            @RequestParam(required=false) String estado,
            @RequestParam(defaultValue="1") @Min(1) Integer pagina,
            @RequestParam(defaultValue="20") @Min(1) @Max(100) Integer tamano,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.listar(new SalidaPersonalQuery("LISTAR",uotId,null,
                buscar,estado,pagina,tamano),identities.resolve(auth),metadata.resolve(request)),request);
    }

    @GetMapping("/{salidaId}/actividad")
    @Operation(operationId="salidasTecnicasMiActividad",summary="Consultar solo mis actuaciones verificables en una salida")
    @PreAuthorize("@permissionGuard.has(authentication,'VISITAS_VER') and @permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<SalidaPersonalModels.Detalle>> actividad(
            @PathVariable @Positive Long salidaId,@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.detalle(new SalidaPersonalQuery("DETALLE",uotId,salidaId,
                null,null,null,null),identities.resolve(auth),metadata.resolve(request)),request);
    }
}
