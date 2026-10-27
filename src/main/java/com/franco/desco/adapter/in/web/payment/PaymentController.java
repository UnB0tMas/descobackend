package com.franco.desco.adapter.in.web.payment;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.payment.port.in.PaymentUseCase;
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
@RequestMapping("/api/v1/pagos")
@Tag(name="Pagos a socios",description="Registro, confirmación, anulación y consulta de pagos asociados a liquidaciones.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class PaymentController {
    private final PaymentUseCase useCase;
    private final PaymentWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public PaymentController(PaymentUseCase useCase,PaymentWebMapper mapper,ApiResponseFactory responses,ClientRequestContextResolver metadata,JwtSessionIdentityResolver identities){
        this.useCase=useCase;this.mapper=mapper;this.responses=responses;this.metadata=metadata;this.identities=identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_LISTAR')")
    @Operation(operationId="pagosListar",summary="Listar pagos a socios")
    public ResponseEntity<ApiResponse<PageResponse<PaymentResponses.Summary>>> list(
            @RequestParam(required=false) Long liquidacionSocioId,
            @RequestParam(required=false) String estadoProceso,
            @RequestParam(defaultValue="1") @Min(1) int pagina,
            @RequestParam(defaultValue="20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.list(mapper.list(pagina,tamano,liquidacionSocioId,estadoProceso),identities.resolve(auth),metadata.resolve(request)),request,
                page -> new PageResponse<>(page.items().stream().map(mapper::response).toList(),page.pagina(),page.tamanio(),page.totalRegistros(),page.totalPaginas()));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_VER')")
    @Operation(operationId="pagosVer",summary="Ver detalle de pago")
    public ResponseEntity<ApiResponse<PaymentResponses.Detail>> get(@PathVariable Long id,@Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.get(mapper.get(id),identities.resolve(auth),metadata.resolve(request)),request,mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_CREAR')")
    @Operation(operationId="pagosRegistrar",summary="Registrar pago")
    public ResponseEntity<ApiResponse<PaymentResponses.Created>> create(@Valid @RequestBody PaymentRequests.Create body,@Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.create(mapper.command(body),identities.resolve(auth),metadata.resolve(request)),request,mapper::created);
    }

    @PostMapping("/{id}/confirmar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_CONFIRMAR')")
    @Operation(operationId="pagosConfirmar",summary="Confirmar pago")
    public ResponseEntity<ApiResponse<Void>> confirm(@PathVariable Long id,@Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.confirm(mapper.confirm(id),identities.resolve(auth),metadata.resolve(request)),request);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_RETIRAR')")
    @Operation(operationId="pagosAnular",summary="Anular pago")
    public ResponseEntity<ApiResponse<Void>> cancel(@PathVariable Long id,@Valid @RequestBody PaymentRequests.Cancel body,@Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.cancel(mapper.cancel(id,body),identities.resolve(auth),metadata.resolve(request)),request);
    }
}
