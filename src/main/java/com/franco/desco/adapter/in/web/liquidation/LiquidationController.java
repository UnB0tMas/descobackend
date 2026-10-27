package com.franco.desco.adapter.in.web.liquidation;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.liquidation.LiquidationCommands;
import com.franco.desco.application.liquidation.port.in.LiquidationUseCase;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/liquidaciones")
@Tag(name="Liquidaciones",description="Cálculo, versiones, aprobación y consulta de liquidaciones por socio.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class LiquidationController {
    private final LiquidationUseCase useCase;private final LiquidationWebMapper mapper;private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;private final JwtSessionIdentityResolver identities;
    public LiquidationController(LiquidationUseCase u,LiquidationWebMapper m,ApiResponseFactory r,ClientRequestContextResolver x,JwtSessionIdentityResolver i){
        useCase=u;mapper=m;responses=r;metadata=x;identities=i;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_LISTAR')")
    @Operation(operationId="liquidacionesListar",summary="Listar liquidaciones")
    public ResponseEntity<ApiResponse<PageResponse<LiquidationResponses.Summary>>>list(
            @RequestParam(required=false)Long campaniaVentaId,@RequestParam(required=false)Long participacionId,@RequestParam(required=false)String estadoProceso,
            @RequestParam(defaultValue="1")@Min(1)int pagina,@RequestParam(defaultValue="20")@Min(1)@Max(100)int tamano,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.list(mapper.list(pagina,tamano,campaniaVentaId,participacionId,estadoProceso),identities.resolve(a),metadata.resolve(r)),
                r,p->PageResponse.from(p,mapper::response));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_VER')")
    @Operation(operationId="liquidacionesVer",summary="Ver liquidación, detalle, saldo y pagos")
    public ResponseEntity<ApiResponse<LiquidationResponses.Detail>>get(@PathVariable Long id,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.get(new LiquidationCommands.GetLiquidation(id),identities.resolve(a),metadata.resolve(r)),r,mapper::response);
    }

    @PostMapping("/calcular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_CREAR')")
    @Operation(operationId="liquidacionesCalcular",summary="Calcular liquidación")
    public ResponseEntity<ApiResponse<LiquidationResponses.Created>>calculate(@Valid@RequestBody LiquidationRequests.Calculate q,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.calculate(new LiquidationCommands.Calculate(q.participacionId()),identities.resolve(a),metadata.resolve(r)),r,LiquidationResponses.Created::new);
    }

    @PostMapping("/{id}/recalcular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_EDITAR')")
    @Operation(operationId="liquidacionesRecalcular",summary="Crear nueva versión de liquidación")
    public ResponseEntity<ApiResponse<LiquidationResponses.Created>>recalculate(@PathVariable Long id,@Valid@RequestBody LiquidationRequests.Recalculate q,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.recalculate(new LiquidationCommands.Recalculate(id,q.motivo()),identities.resolve(a),metadata.resolve(r)),r,LiquidationResponses.Created::new);
    }

    @PostMapping("/{id}/aprobar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_APROBAR')")
    @Operation(operationId="liquidacionesAprobar",summary="Aprobar liquidación")
    public ResponseEntity<ApiResponse<Void>>approve(@PathVariable Long id,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.approve(new LiquidationCommands.Approve(id),identities.resolve(a),metadata.resolve(r)),r);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_RETIRAR')")
    @Operation(operationId="liquidacionesAnular",summary="Anular liquidación")
    public ResponseEntity<ApiResponse<Void>>cancel(@PathVariable Long id,@Valid@RequestBody LiquidationRequests.Cancel q,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.cancel(new LiquidationCommands.Cancel(id,q.motivo()),identities.resolve(a),metadata.resolve(r)),r);
    }
}
