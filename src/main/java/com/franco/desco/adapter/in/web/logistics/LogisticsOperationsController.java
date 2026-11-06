package com.franco.desco.adapter.in.web.logistics;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.logistics.LogisticsOperationsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/recursos-operativos")
@Tag(name="Logística operativa por UOT",description="Catálogo de UOT, transferencias y uso técnico de productos.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class LogisticsOperationsController {
    private final LogisticsOperationsService service;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public LogisticsOperationsController(LogisticsOperationsService service,ApiResponseFactory responses,
                                         JwtSessionIdentityResolver identities,IdempotencyKeyResolver idempotency) {
        this.service=service;this.responses=responses;this.identities=identities;this.idempotency=idempotency;
    }

    @GetMapping("/productos-uot")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'ALMACENES_LISTAR') or @permissionGuard.hasUot(authentication,#uotId,'POS_OPERAR')")
    @Operation(operationId="productosUotListar",summary="Catálogo y stock de una UOT")
    public ResponseEntity<ApiResponse<List<Map<String,Object>>>> products(
            @RequestParam @Positive Long uotId,@Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.policies(identities.resolve(authentication),uotId),request);
    }

    @PutMapping("/productos-uot/politica")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'ALMACENES_MOVIMIENTO')")
    @Operation(operationId="productosUotConfigurar",summary="Habilitar venta y uso interno")
    public ResponseEntity<ApiResponse<Void>> policy(@Valid @RequestBody LogisticsRequests.Policy body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.policy(identities.resolve(authentication),
                new LogisticsOperationsService.Policy(body.uotId(),body.productoId(),body.permiteVenta(),body.permiteUsoInterno())),request);
    }

    @GetMapping("/transferencias/productos")
    @PreAuthorize("@permissionGuard.has(authentication,'ALMACENES_LISTAR')")
    @Operation(operationId="almacenesProductosTransferibles",summary="Productos de origen y motivos que impiden transferirlos")
    public ResponseEntity<ApiResponse<List<Map<String,Object>>>> transferProducts(
            @RequestParam @Positive Long almacenOrigenId,@RequestParam @Positive Long almacenDestinoId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.transferProducts(identities.resolve(authentication),almacenOrigenId,almacenDestinoId),request);
    }

    @PostMapping("/transferencias")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ALMACENES_MOVIMIENTO')")
    @Operation(operationId="almacenesTransferirStock",summary="Transferir cantidades entre dos almacenes autorizados")
    public ResponseEntity<ApiResponse<Long>> transfer(@Valid @RequestBody LogisticsRequests.Transfer body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.transfer(identities.resolve(authentication),
                new LogisticsOperationsService.Transfer(body.almacenOrigenId(),body.almacenDestinoId(),
                    body.detalle().stream().map(d->new LogisticsOperationsService.TransferLine(d.productoId(),d.cantidad())).toList(),body.observacion()),
                idempotency.required(request)),request);
    }

    @GetMapping("/programaciones")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'RECURSOS_LISTAR')")
    @Operation(operationId="programacionProductosListar",summary="Listar solicitudes técnicas de productos")
    public ResponseEntity<ApiResponse<List<Map<String,Object>>>> programs(@RequestParam @Positive Long uotId,
            @RequestParam(required=false) String estado,@Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.programs(identities.resolve(authentication),uotId,estado),request);
    }

    @GetMapping("/programaciones/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_VER')")
    @Operation(operationId="programacionProductosDetalle",summary="Ver solicitud y movimientos")
    public ResponseEntity<ApiResponse<List<Map<String,Object>>>> detail(@PathVariable @Positive Long id,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.detail(identities.resolve(authentication),id),request);
    }

    @PostMapping("/programaciones")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'RECURSOS_CREAR')")
    @Operation(operationId="programacionProductosSolicitar",summary="Solicitar un producto para uso técnico")
    public ResponseEntity<ApiResponse<Long>> requestProduct(@Valid @RequestBody LogisticsRequests.RequestProduct body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.request(identities.resolve(authentication),
                new LogisticsOperationsService.RequestProduct(body.uotId(),body.almacenId(),body.productoId(),body.empleadoId(),
                    body.cantidad(),body.actividad(),body.lugar(),body.fechaInicio(),body.fechaFin(),body.archivoAutorizacionId(),body.observacion()),
                idempotency.required(request)),request);
    }

    @PostMapping("/programaciones/{id}/operaciones")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR') or @permissionGuard.has(authentication,'RECURSOS_EDITAR') or @permissionGuard.has(authentication,'ALMACENES_MOVIMIENTO')")
    @Operation(operationId="programacionProductosOperacion",summary="Aprobar, entregar, devolver, consumir o cerrar")
    public ResponseEntity<ApiResponse<Long>> operation(@PathVariable @Positive Long id,
            @Valid @RequestBody LogisticsRequests.ProductOperation body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.operation(identities.resolve(authentication),id,
                new LogisticsOperationsService.ProductOperation(body.operacion(),body.cantidad(),body.observacion()),
                idempotency.required(request)),request);
    }

    @PostMapping("/programados/{id}/adjuntos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_EDITAR')")
    @Operation(operationId="recursosProgramadosAdjuntarDocumento",summary="Vincular un archivo local de autorización")
    public ResponseEntity<ApiResponse<Void>> attach(@PathVariable @Positive Long id,
            @Valid @RequestBody LogisticsRequests.AttachFile body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.attach(identities.resolve(authentication),id,body.archivoId()),request);
    }
}
