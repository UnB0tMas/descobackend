package com.franco.desco.adapter.in.web.supply;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.supply.SupplyUotService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/suministros")
@Tag(
        name = "Suministros",
        description = "Inventario y Kardex de suministros aislados por UOT."
)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class SupplyController {

    private final com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver idempotency;
    private final SupplyUotService service;
    private final SupplyWebMapper mapper;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;

    public SupplyController(
            SupplyUotService service,
            SupplyWebMapper mapper,
            ApiResponseFactory responses,
            JwtSessionIdentityResolver identities,
            com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver idempotency
    ) {
        this.idempotency = idempotency;
        this.service = service;
        this.mapper = mapper;
        this.responses = responses;
        this.identities = identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_LISTAR')")
    @Operation(
            operationId = "suministrosUotListar",
            summary = "Listar suministros por UOT",
            description = "En modo ESPECIFICA usa la UOT de la sesión. En GENERAL uotId es un filtro opcional y cada fila conserva su UOT."
    )
    public ResponseEntity<ApiResponse<PageResponse<SupplyResponses.Summary>>> list(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(500) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.list(
                        identities.resolve(authentication),
                        uotId,
                        pagina,
                        tamano
                ),
                request,
                page -> PageResponse.from(page, mapper::response)
        );
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'INVENTARIO_CREAR')")
    @Operation(
            operationId = "suministrosUotCrear",
            summary = "Registrar suministro en una UOT",
            description = "Si no se envía código, DESCO genera uno para la UOT."
    )
    public ResponseEntity<ApiResponse<SupplyResponses.Created>> create(
            @Valid @RequestBody SupplyRequests.Create body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.create(
                        identities.resolve(authentication),
                        body.uotId(),
                        body.codigo(),
                        body.nombre(),
                        body.unidadMedida(),
                        body.stockInicial(),
                        body.stockMinimo(),
                        idempotency.required(request)
                ),
                request,
                SupplyResponses.Created::new
        );
    }

    @PutMapping("/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'INVENTARIO_EDITAR')")
    @Operation(
            operationId = "suministrosUotEditar",
            summary = "Editar suministro de una UOT"
    )
    public ResponseEntity<ApiResponse<Void>> update(
            @PathVariable @Positive Long id,
            @Valid @RequestBody SupplyRequests.Update body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.update(
                        identities.resolve(authentication),
                        body.uotId(),
                        id,
                        body.nombre(),
                        body.unidadMedida(),
                        body.stockMinimo(),
                        idempotency.required(request)
                ),
                request
        );
    }

    @GetMapping("/{id}/kardex")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_VER')")
    @Operation(
            operationId = "suministrosUotKardex",
            summary = "Consultar Kardex histórico de un suministro"
    )
    public ResponseEntity<ApiResponse<List<SupplyResponses.Movement>>> kardex(
            @PathVariable @Positive Long id,
            @RequestParam(required = false) @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.kardex(
                        identities.resolve(authentication),
                        uotId,
                        id
                ),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @PostMapping("/{id}/movimientos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'INVENTARIO_EDITAR')")
    @Operation(
            operationId = "suministrosUotMovimientoCrear",
            summary = "Registrar entrada o ajuste de suministro"
    )
    public ResponseEntity<ApiResponse<SupplyResponses.MovementCreated>> movement(
            @PathVariable @Positive Long id,
            @Valid @RequestBody SupplyRequests.Movement body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.movement(
                        identities.resolve(authentication),
                        body.uotId(),
                        id,
                        body.tipoMovimiento(),
                        body.cantidad(),
                        body.documentoReferencia(),
                        body.observacion(),
                        idempotency.required(request)
                ),
                request,
                SupplyResponses.MovementCreated::new
        );
    }

    @PostMapping("/movimientos/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'INVENTARIO_EDITAR')")
    @Operation(
            operationId = "suministrosUotMovimientoAnular",
            summary = "Anular un movimiento manual de suministro"
    )
    public ResponseEntity<ApiResponse<Void>> cancel(
            @PathVariable @Positive Long id,
            @Valid @RequestBody SupplyRequests.CancelMovement body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.cancel(
                        identities.resolve(authentication),
                        body.uotId(),
                        id,
                        body.motivo(),
                        idempotency.required(request)
                ),
                request
        );
    }
}
