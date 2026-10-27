package com.franco.desco.adapter.in.web.priceadjustment;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands;
import com.franco.desco.application.priceadjustment.port.in.PriceAdjustmentUseCase;
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
@RequestMapping("/api/v1/ajustes-precio")
@Tag(name="Ajustes de precio",description="Ajustes comerciales por socio, consulta de impacto y anulación.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class PriceAdjustmentController {
    private final PriceAdjustmentUseCase useCase; private final PriceAdjustmentWebMapper mapper;
    private final ApiResponseFactory responses; private final ClientRequestContextResolver metadata; private final JwtSessionIdentityResolver identities;

    public PriceAdjustmentController(PriceAdjustmentUseCase useCase,PriceAdjustmentWebMapper mapper,ApiResponseFactory responses,
                                     ClientRequestContextResolver metadata,JwtSessionIdentityResolver identities){
        this.useCase=useCase;this.mapper=mapper;this.responses=responses;this.metadata=metadata;this.identities=identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'AJUSTES_LISTAR')")
    @Operation(operationId="ajustesListar",summary="Listar ajustes de precio")
    public ResponseEntity<ApiResponse<PageResponse<PriceAdjustmentResponses.Summary>>> list(
            @RequestParam(required=false)Long participacionId,@RequestParam(required=false)Long operativoVentaId,
            @RequestParam(defaultValue="1")@Min(1)int pagina,@RequestParam(defaultValue="20")@Min(1)@Max(100)int tamano,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.list(mapper.list(pagina,tamano,participacionId,operativoVentaId),identities.resolve(a),metadata.resolve(r)),
                r,p->PageResponse.from(p,mapper::response));
    }

    @GetMapping("/{id}/impacto")
    @PreAuthorize("@permissionGuard.has(authentication,'AJUSTES_VER')")
    @Operation(operationId="ajustesVerImpacto",summary="Ver impacto de un ajuste")
    public ResponseEntity<ApiResponse<PriceAdjustmentResponses.Impact>> impact(@PathVariable Long id,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.impact(new PriceAdjustmentCommands.GetImpact(id),identities.resolve(a),metadata.resolve(r)),r,mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'AJUSTES_CREAR')")
    @Operation(operationId="ajustesCrear",summary="Registrar ajuste de precio")
    public ResponseEntity<ApiResponse<PriceAdjustmentResponses.Created>> create(@Valid@RequestBody PriceAdjustmentRequests.Create q,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.create(mapper.command(q),identities.resolve(a),metadata.resolve(r)),r,PriceAdjustmentResponses.Created::new);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'AJUSTES_RETIRAR')")
    @Operation(operationId="ajustesAnular",summary="Anular ajuste de precio")
    public ResponseEntity<ApiResponse<Void>> cancel(@PathVariable Long id,@Valid@RequestBody PriceAdjustmentRequests.Cancel q,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.cancel(new PriceAdjustmentCommands.Cancel(id,q.motivo()),identities.resolve(a),metadata.resolve(r)),r);
    }
}
