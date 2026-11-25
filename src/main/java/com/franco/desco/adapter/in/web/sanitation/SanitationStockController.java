package com.franco.desco.adapter.in.web.sanitation;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import com.franco.desco.application.sanitation.service.SanitationStockService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/v1/sanidad/recursos-entregados")
public class SanitationStockController {
    private final SanitationStockService service;
    private final JwtSessionIdentityResolver identities;
    public SanitationStockController(SanitationStockService service,JwtSessionIdentityResolver identities){
        this.service=service;this.identities=identities;
    }
    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_CREAR')")
    public ApiResponse<List<?>> listar(@RequestParam(required=false) Long responsableEmpleadoId,
            @RequestParam(required=false) Long salidaCampoId,
            @RequestParam(required=false) Long visitaTecnicaId,
            @RequestParam(required=false) Long predioId,
            JwtAuthenticationToken authentication,HttpServletRequest request){
        List<?> items=service.listar(identities.resolve(authentication),responsableEmpleadoId,
                salidaCampoId,visitaTecnicaId,predioId);
        return new ApiResponse<>(true,"RECURSOS_ENTREGADOS","Productos entregados consultados.",items,
                CorrelationIdFilter.correlationId(request),Instant.now());
    }
}
