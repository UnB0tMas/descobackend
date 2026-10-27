package com.franco.desco.adapter.in.web.buyercollection;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.buyercollection.port.in.BuyerCollectionUseCase;
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
@RequestMapping("/api/v1/cobros")
@Tag(name="Cobros de compradores",description="Registro, confirmación, anulación y saldo de cobros de campañas y operativos.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class BuyerCollectionController {
    private final BuyerCollectionUseCase useCase;private final BuyerCollectionWebMapper mapper;private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;private final JwtSessionIdentityResolver identities;
    public BuyerCollectionController(BuyerCollectionUseCase u,BuyerCollectionWebMapper m,ApiResponseFactory r,ClientRequestContextResolver x,JwtSessionIdentityResolver i){useCase=u;mapper=m;responses=r;metadata=x;identities=i;}

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'COBROS_LISTAR')")
    @Operation(operationId="cobrosListar",summary="Listar cobros de compradores")
    public ResponseEntity<ApiResponse<PageResponse<BuyerCollectionResponses.Summary>>>list(@RequestParam(required=false)Long campaniaVentaId,@RequestParam(required=false)Long operativoVentaId,@RequestParam(required=false)String estadoProceso,@RequestParam(defaultValue="1")@Min(1)int pagina,@RequestParam(defaultValue="20")@Min(1)@Max(100)int tamano,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.list(mapper.list(pagina,tamano,campaniaVentaId,operativoVentaId,estadoProceso),identities.resolve(a),metadata.resolve(r)),r,p->new PageResponse<>(p.items().stream().map(mapper::response).toList(),p.pagina(),p.tamanio(),p.totalRegistros(),p.totalPaginas()));
    }

    @GetMapping("/saldo")
    @PreAuthorize("@permissionGuard.has(authentication,'COBROS_VER')")
    @Operation(operationId="cobrosVerSaldoCampania",summary="Consultar saldo pendiente del comprador")
    public ResponseEntity<ApiResponse<BuyerCollectionResponses.Balance>>balance(@RequestParam @NotNull Long campaniaVentaId,@RequestParam(required=false)Long operativoVentaId,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.balance(mapper.balance(campaniaVentaId,operativoVentaId),identities.resolve(a),metadata.resolve(r)),r,mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'COBROS_CREAR')")
    @Operation(operationId="cobrosRegistrar",summary="Registrar cobro")
    public ResponseEntity<ApiResponse<BuyerCollectionResponses.Created>>create(@Valid@RequestBody BuyerCollectionRequests.Create b,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.create(mapper.command(b),identities.resolve(a),metadata.resolve(r)),r,mapper::created);
    }

    @PostMapping("/{id}/confirmar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'COBROS_CONFIRMAR')")
    @Operation(operationId="cobrosConfirmar",summary="Confirmar cobro")
    public ResponseEntity<ApiResponse<Void>>confirm(@PathVariable Long id,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.confirm(mapper.confirm(id),identities.resolve(a),metadata.resolve(r)),r);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'COBROS_RETIRAR')")
    @Operation(operationId="cobrosAnular",summary="Anular cobro")
    public ResponseEntity<ApiResponse<Void>>cancel(@PathVariable Long id,@Valid@RequestBody BuyerCollectionRequests.Cancel b,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.cancel(mapper.cancel(id,b),identities.resolve(a),metadata.resolve(r)),r);
    }
}
