package com.franco.desco.adapter.in.web.producer;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.producer.ProducerCommands;
import com.franco.desco.application.producer.port.in.ProducerUseCase;
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

@RestController @RequestMapping("/api/v1/productores") @Tag(name="Productores",description="Gestión de productores y socios.") @SecurityRequirement(name=OpenApiConstants.BEARER_AUTH) @Validated
public class ProducerController {
    private final ProducerUseCase useCase; private final ProducerWebMapper mapper; private final ApiResponseFactory responses; private final ClientRequestContextResolver metadata; private final JwtSessionIdentityResolver identities;
    public ProducerController(ProducerUseCase u,ProducerWebMapper m,ApiResponseFactory r,ClientRequestContextResolver x,JwtSessionIdentityResolver i){useCase=u;mapper=m;responses=r;metadata=x;identities=i;}
    @GetMapping @PreAuthorize("@permissionGuard.has(authentication,'PRODUCTORES_LISTAR')") @Operation(operationId="productoresListar",summary="Listar productores")
    public ResponseEntity<ApiResponse<PageResponse<ProducerResponses.Summary>>> list(@RequestParam(required=false) String buscar,@RequestParam(required=false) Long asociacionId,@RequestParam(required=false) String situacion,@RequestParam(defaultValue="1") @Min(1) int pagina,@RequestParam(defaultValue="20") @Min(1) @Max(200) int tamano,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return responses.from(useCase.list(mapper.list(pagina,tamano,buscar,asociacionId,situacion),identities.resolve(a),metadata.resolve(r)),r,p->PageResponse.from(p,mapper::response));}
    @GetMapping("/{id}") @PreAuthorize("@permissionGuard.has(authentication,'PRODUCTORES_VER')") @Operation(operationId="productoresVer",summary="Ver detalle del productor")
    public ResponseEntity<ApiResponse<ProducerResponses.Detail>> get(@PathVariable Long id,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return responses.from(useCase.get(new ProducerCommands.GetProducer(id),identities.resolve(a),metadata.resolve(r)),r,mapper::response);}
    @PostMapping @IdempotentOperation @PreAuthorize("@permissionGuard.has(authentication,'PRODUCTORES_CREAR')") @Operation(operationId="productoresCrear",summary="Registrar productor")
    public ResponseEntity<ApiResponse<ProducerResponses.Created>> create(@Valid @RequestBody ProducerRequests.Create q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return responses.from(useCase.create(mapper.command(q),identities.resolve(a),metadata.resolve(r)),r,ProducerResponses.Created::new);}
    @PutMapping("/{id}") @IdempotentOperation @PreAuthorize("@permissionGuard.has(authentication,'PRODUCTORES_EDITAR')") @Operation(operationId="productoresEditar",summary="Editar productor")
    public ResponseEntity<ApiResponse<Void>> update(@PathVariable Long id,@Valid @RequestBody ProducerRequests.Update q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return responses.from(useCase.update(mapper.command(id,q),identities.resolve(a),metadata.resolve(r)),r);}
    @PostMapping("/{id}/retirar") @IdempotentOperation @PreAuthorize("@permissionGuard.has(authentication,'PRODUCTORES_RETIRAR')") @Operation(operationId="productoresRetirar",summary="Retirar productor")
    public ResponseEntity<ApiResponse<Void>> retire(@PathVariable Long id,@Valid @RequestBody ProducerRequests.Retire q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return responses.from(useCase.retire(new ProducerCommands.RetireProducer(id,q.fechaRetiro(),q.motivo()),identities.resolve(a),metadata.resolve(r)),r);}
}
