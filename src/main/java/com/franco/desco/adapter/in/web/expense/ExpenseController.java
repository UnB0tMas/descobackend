package com.franco.desco.adapter.in.web.expense;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.expense.ExpenseCommands;
import com.franco.desco.application.expense.port.in.ExpenseUseCase;
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
@RequestMapping("/api/v1/gastos")
@Tag(name="Gastos",description="Gastos de campaña, prorrateo, aprobación y anulación.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class ExpenseController {
    private final ExpenseUseCase useCase;private final ExpenseWebMapper mapper;private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;private final JwtSessionIdentityResolver identities;
    public ExpenseController(ExpenseUseCase u,ExpenseWebMapper m,ApiResponseFactory r,ClientRequestContextResolver x,JwtSessionIdentityResolver i){
        useCase=u;mapper=m;responses=r;metadata=x;identities=i;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_LISTAR')")
    @Operation(operationId="gastosListar",summary="Listar gastos")
    public ResponseEntity<ApiResponse<PageResponse<ExpenseResponses.Summary>>>list(
            @RequestParam(required=false)Long campaniaVentaId,@RequestParam(required=false)Long operativoVentaId,@RequestParam(required=false)String estadoProceso,
            @RequestParam(defaultValue="1")@Min(1)int pagina,@RequestParam(defaultValue="20")@Min(1)@Max(100)int tamano,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.list(mapper.list(pagina,tamano,campaniaVentaId,operativoVentaId,estadoProceso),identities.resolve(a),metadata.resolve(r)),
                r,p->PageResponse.from(p,mapper::response));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_VER')")
    @Operation(operationId="gastosVer",summary="Ver gasto y prorrateo")
    public ResponseEntity<ApiResponse<ExpenseResponses.Detail>>get(@PathVariable Long id,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.get(new ExpenseCommands.GetExpense(id),identities.resolve(a),metadata.resolve(r)),r,mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_CREAR')")
    @Operation(operationId="gastosCrear",summary="Registrar gasto")
    public ResponseEntity<ApiResponse<ExpenseResponses.Created>>create(@Valid@RequestBody ExpenseRequests.Create q,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.create(mapper.command(q),identities.resolve(a),metadata.resolve(r)),r,ExpenseResponses.Created::new);
    }

    @PutMapping("/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_EDITAR')")
    @Operation(operationId="gastosEditar",summary="Editar gasto registrado")
    public ResponseEntity<ApiResponse<Void>>update(@PathVariable Long id,@Valid@RequestBody ExpenseRequests.Update q,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.update(mapper.command(id,q),identities.resolve(a),metadata.resolve(r)),r);
    }

    @PostMapping("/{id}/prorratear")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_CREAR')")
    @Operation(operationId="gastosProrratear",summary="Calcular o registrar prorrateo del gasto")
    public ResponseEntity<ApiResponse<Void>>prorate(@PathVariable Long id,@Valid@RequestBody ExpenseRequests.Prorate q,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.prorate(mapper.command(id,q),identities.resolve(a),metadata.resolve(r)),r);
    }

    @PostMapping("/{id}/aprobar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_APROBAR')")
    @Operation(operationId="gastosAprobar",summary="Aprobar gasto")
    public ResponseEntity<ApiResponse<Void>>approve(@PathVariable Long id,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.approve(new ExpenseCommands.Approve(id),identities.resolve(a),metadata.resolve(r)),r);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_RETIRAR')")
    @Operation(operationId="gastosAnular",summary="Anular gasto")
    public ResponseEntity<ApiResponse<Void>>cancel(@PathVariable Long id,@Valid@RequestBody ExpenseRequests.Cancel q,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.cancel(new ExpenseCommands.Cancel(id,q.motivo()),identities.resolve(a),metadata.resolve(r)),r);
    }
}
