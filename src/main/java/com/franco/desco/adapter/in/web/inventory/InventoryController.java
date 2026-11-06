package com.franco.desco.adapter.in.web.inventory;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.inventory.InventoryCommands;
import com.franco.desco.application.inventory.port.in.InventoryUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/inventario")
@Tag(
        name = "Inventario y vehículos",
        description = "Bienes, vehículos, suministros y movimientos de inventario."
)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class InventoryController {

    private final InventoryUseCase useCase;
    private final InventoryWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public InventoryController(
            InventoryUseCase useCase,
            InventoryWebMapper mapper,
            ApiResponseFactory responses,
            ClientRequestContextResolver metadata,
            JwtSessionIdentityResolver identities
    ) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    @GetMapping("/bienes")
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_LISTAR')")
    @Operation(operationId = "inventarioBienesListar", summary = "Listar bienes")
    public ResponseEntity<ApiResponse<PageResponse<InventoryResponses.AssetSummary>>> assets(
            @RequestParam(required = false) Long empresaId,
            @RequestParam(required = false) Long tipoBienId,
            @RequestParam(required = false) String estadoBien,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.listAssets(
                        mapper.assets(pagina, tamano, empresaId, tipoBienId, estadoBien),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                page -> PageResponse.from(page, mapper::response)
        );
    }

    @GetMapping("/bienes/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_VER')")
    @Operation(operationId = "inventarioBienesVer", summary = "Ver bien")
    public ResponseEntity<ApiResponse<InventoryResponses.AssetDetail>> asset(
            @PathVariable Long id,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.getAsset(
                        new InventoryCommands.GetAsset(id),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                mapper::response
        );
    }

    @PostMapping("/bienes")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_CREAR')")
    @Operation(operationId = "inventarioBienesCrear", summary = "Registrar bien")
    public ResponseEntity<ApiResponse<InventoryResponses.Created>> createAsset(
            @Valid @RequestBody InventoryRequests.CreateAsset body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.createAsset(
                        new InventoryCommands.CreateAsset(
                                body.empresaId(),
                                body.tipoBienId(),
                                body.codigoPatrimonial(),
                                body.nombre(),
                                body.marca(),
                                body.modelo(),
                                body.serie()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                InventoryResponses.Created::new
        );
    }

    @PutMapping("/bienes/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_EDITAR')")
    @Operation(operationId = "inventarioBienesEditar", summary = "Editar bien")
    public ResponseEntity<ApiResponse<Void>> updateAsset(
            @PathVariable Long id,
            @Valid @RequestBody InventoryRequests.UpdateAsset body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.updateAsset(
                        new InventoryCommands.UpdateAsset(
                                id,
                                body.nombre(),
                                body.marca(),
                                body.modelo(),
                                body.serie(),
                                body.estadoBien()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @PostMapping("/bienes/{id}/baja")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_RETIRAR')")
    @Operation(operationId = "inventarioBienesBaja", summary = "Dar de baja un bien")
    public ResponseEntity<ApiResponse<Void>> retireAsset(
            @PathVariable Long id,
            @Valid @RequestBody InventoryRequests.RetireAsset body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.retireAsset(
                        new InventoryCommands.RetireAsset(id, body.motivo()),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @PostMapping("/bienes/{id}/vehiculo")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_CREAR')")
    @Operation(operationId = "inventarioVehiculosRegistrar", summary = "Registrar datos de vehículo para un bien")
    public ResponseEntity<ApiResponse<InventoryResponses.Created>> vehicle(
            @PathVariable Long id,
            @Valid @RequestBody InventoryRequests.RegisterVehicle body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.registerVehicle(
                        new InventoryCommands.RegisterVehicle(
                                id,
                                body.placa(),
                                body.tipoVehiculo(),
                                body.kilometrajeKm(), body.color()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                InventoryResponses.Created::new
        );
    }

    @PutMapping("/vehiculos/{id}/kilometraje")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_EDITAR')")
    @Operation(operationId = "inventarioVehiculosKilometraje", summary = "Actualizar kilometraje")
    public ResponseEntity<ApiResponse<Void>> mileage(
            @PathVariable Long id,
            @Valid @RequestBody InventoryRequests.UpdateMileage body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.updateMileage(
                        new InventoryCommands.UpdateMileage(id, body.kilometrajeKm()),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @GetMapping("/suministros")
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_LISTAR')")
    @Operation(operationId = "inventarioSuministrosListar", summary = "Listar suministros")
    public ResponseEntity<ApiResponse<PageResponse<InventoryResponses.Supply>>> supplies(
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.listSupplies(
                        mapper.supplies(pagina, tamano),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                page -> PageResponse.from(page, mapper::response)
        );
    }

    @PostMapping("/suministros")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_CREAR')")
    @Operation(operationId = "inventarioSuministrosCrear", summary = "Registrar suministro")
    public ResponseEntity<ApiResponse<InventoryResponses.Created>> createSupply(
            @Valid @RequestBody InventoryRequests.CreateSupply body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.createSupply(
                        new InventoryCommands.CreateSupply(
                                body.codigo(),
                                body.nombre(),
                                body.unidadMedida(),
                                body.stockInicial()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                InventoryResponses.Created::new
        );
    }

    @PutMapping("/suministros/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_EDITAR')")
    @Operation(operationId = "inventarioSuministrosEditar", summary = "Editar suministro")
    public ResponseEntity<ApiResponse<Void>> updateSupply(
            @PathVariable Long id,
            @Valid @RequestBody InventoryRequests.UpdateSupply body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.updateSupply(
                        new InventoryCommands.UpdateSupply(
                                id,
                                body.nombre(),
                                body.unidadMedida()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @GetMapping("/suministros/kardex")
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_VER')")
    @Operation(operationId = "inventarioSuministrosKardex", summary = "Consultar kardex de suministros")
    public ResponseEntity<ApiResponse<List<InventoryResponses.SupplyMovement>>> kardex(
            @RequestParam(required = false) Long suministroId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.supplyMovements(
                        new InventoryCommands.ListSupplyMovements(suministroId),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                list -> list.stream().map(mapper::response).toList()
        );
    }

    @PostMapping("/suministros/{id}/movimientos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_EDITAR')")
    @Operation(operationId = "inventarioSuministrosMovimientoRegistrar", summary = "Registrar movimiento de suministro")
    public ResponseEntity<ApiResponse<InventoryResponses.Created>> adjust(
            @PathVariable Long id,
            @Valid @RequestBody InventoryRequests.AdjustSupply body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.adjustSupply(
                        new InventoryCommands.AdjustSupply(
                                id,
                                body.tipoMovimiento(),
                                body.cantidad(),
                                body.documentoReferencia(),
                                body.observacion()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                InventoryResponses.Created::new
        );
    }

    @PostMapping("/suministros/movimientos/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INVENTARIO_EDITAR')")
    @Operation(operationId = "inventarioSuministrosMovimientoAnular", summary = "Anular un movimiento independiente de suministro")
    public ResponseEntity<ApiResponse<Void>> annulMovement(
            @PathVariable Long id,
            @Valid @RequestBody InventoryRequests.AnnulSupplyMovement body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.annulSupplyMovement(
                        new InventoryCommands.AnnulSupplyMovement(
                                id,
                                body.motivo()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }
}
