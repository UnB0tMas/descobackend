package com.franco.desco.adapter.in.web.resource;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.resource.ResourceCommands;
import com.franco.desco.application.resource.port.in.ResourceUseCase;
import com.franco.desco.application.resource.service.ProductPriceHistoryService;
import com.franco.desco.application.resource.service.ResourceExperienceService;
import com.franco.desco.application.resource.service.ResourceReadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
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
@RequestMapping("/api/v1/recursos")
@Tag(
        name = OpenApiConstants.TAG_RESOURCES,
        description = OpenApiConstants.TAG_RESOURCES_DESCRIPTION
)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class ResourceController {

    private final ResourceUseCase useCase;
    private final ResourceExperienceService experience;
    private final ResourceReadService reads;
    private final ResourceWebMapper mapper;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;
    private final ProductPriceHistoryService priceHistory;

    public ResourceController(
            ResourceUseCase useCase,
            ResourceExperienceService experience,
            ResourceReadService reads,
            ResourceWebMapper mapper,
            ApiResponseFactory responses,
            JwtSessionIdentityResolver identities,
            IdempotencyKeyResolver idempotency,
            ProductPriceHistoryService priceHistory
    ) {
        this.useCase = useCase;
        this.experience = experience;
        this.reads = reads;
        this.mapper = mapper;
        this.responses = responses;
        this.identities = identities;
        this.idempotency = idempotency;
        this.priceHistory = priceHistory;
    }

    @GetMapping("/codigos/sugerido")
    @PreAuthorize("isAuthenticated()")
    @Operation(
            operationId = "recursosCodigoSugerido",
            summary = "Generar un código sugerido editable para un recurso",
            description = "Genera un valor inicial único por UOT. El usuario puede modificarlo antes de guardar."
    )
    public ResponseEntity<ApiResponse<ResourceResponses.CodeSuggestion>> suggestedCode(
            @RequestParam @Positive Long uotId,
            @Parameter(
                    description = "Tipo de recurso para el que se solicita el código.",
                    schema = @Schema(
                            allowableValues = {"BIEN", "PRODUCTO", "ALMACEN", "SUMINISTRO"}
                    )
            )
            @RequestParam
            @Pattern(regexp = "BIEN|PRODUCTO|ALMACEN|SUMINISTRO")
            String tipo,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                experience.suggestedCode(
                        identities.resolve(authentication),
                        uotId,
                        tipo
                ),
                request,
                mapper::response
        );
    }

    @GetMapping("/bienes")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_LISTAR')")
    @Operation(
            operationId = "recursosBienesListar",
            summary = "Listar bienes patrimoniales paginados por contexto UOT"
    )
    public ResponseEntity<ApiResponse<PageResponse<ResourceResponses.AssetListItem>>> assets(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(required = false) String buscar,
            @RequestParam(required = false) @Positive Integer tipoBienId,
            @RequestParam(required = false) String estado,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                reads.assets(
                        identities.resolve(authentication),
                        uotId,
                        buscar,
                        tipoBienId,
                        estado,
                        pagina,
                        tamano
                ),
                request,
                result -> PageResponse.from(result, mapper::response)
        );
    }

    @GetMapping("/bienes/{id}")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_VER')")
    @Operation(
            operationId = "recursosBienesVer",
            summary = "Ver detalle, historial e incidentes de un bien"
    )
    public ResponseEntity<ApiResponse<ResourceResponses.AssetDetail>> asset(
            @PathVariable @Positive Long id,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.asset(identities.resolve(authentication), id),
                request,
                mapper::response
        );
    }

    @PostMapping("/bienes")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'INVENTARIO_CREAR')")
    @Operation(
            operationId = "recursosBienesCrear",
            summary = "Registrar un bien patrimonial",
            description = "Si no se envía código patrimonial, DESCO genera uno para la UOT."
    )
    public ResponseEntity<ApiResponse<ResourceResponses.AssetCreated>> createAsset(
            @Valid @RequestBody ResourceRequests.CreateAsset body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        ResourceCommands.CreateAsset command = new ResourceCommands.CreateAsset(
                body.uotId(),
                body.tipoBienId(),
                body.codigoPatrimonial(),
                body.nombre(),
                body.marca(),
                body.modelo(),
                body.serie(),
                body.fechaAdquisicion(),
                body.montoAdquisicion(),
                body.moneda(),
                body.proveedorPersonaId(),
                body.proveedorEmpresaId(),
                body.observacion(),
                idempotency.required(request)
        );

        return responses.from(
                experience.createAsset(
                        identities.resolve(authentication),
                        command
                ),
                request,
                ResourceResponses.AssetCreated::new
        );
    }

    @PutMapping("/bienes/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_EDITAR')")
    @Operation(
            operationId = "recursosBienesEditar",
            summary = "Editar datos patrimoniales de un bien"
    )
    public ResponseEntity<ApiResponse<Void>> updateAsset(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceRequests.UpdateAsset body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        ResourceCommands.UpdateAsset command = new ResourceCommands.UpdateAsset(
                id,
                body.tipoBienId(),
                body.nombre(),
                body.marca(),
                body.modelo(),
                body.serie(),
                body.fechaAdquisicion(),
                body.montoAdquisicion(),
                body.moneda(),
                body.proveedorPersonaId(),
                body.proveedorEmpresaId(),
                body.observacion()
        );

        return responses.from(
                useCase.updateAsset(
                        identities.resolve(authentication),
                        command
                ),
                request
        );
    }

    @PostMapping("/bienes/{id}/estado")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_EDITAR')")
    @Operation(
            operationId = "recursosBienesCambiarEstado",
            summary = "Cambiar el estado operativo de un bien"
    )
    public ResponseEntity<ApiResponse<Void>> changeState(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceRequests.ChangeAssetState body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.changeAssetState(
                        identities.resolve(authentication),
                        new ResourceCommands.ChangeAssetState(
                                id,
                                body.estado(),
                                body.motivo()
                        )
                ),
                request
        );
    }

    @PostMapping("/bienes/{id}/incidentes")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_EDITAR')")
    @Operation(
            operationId = "recursosBienesRegistrarIncidente",
            summary = "Registrar un incidente de un bien"
    )
    public ResponseEntity<ApiResponse<ResourceResponses.IncidentCreated>> incident(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceRequests.Incident body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.reportIncident(
                        identities.resolve(authentication),
                        new ResourceCommands.ReportIncident(
                                id,
                                body.tipo(),
                                body.fechaHora(),
                                body.descripcion(),
                                body.costoEstimado(),
                                idempotency.required(request)
                        )
                ),
                request,
                ResourceResponses.IncidentCreated::new
        );
    }

    @GetMapping("/productos")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'PRODUCTOS_LISTAR')")
    @Operation(
            operationId = "recursosProductosListar",
            summary = "Listar productos paginados con su precio vigente por UOT",
            description = "El listado nunca expone el historial de precios; únicamente el precio vigente efectivo para la UOT."
    )
    public ResponseEntity<ApiResponse<PageResponse<ResourceResponses.ProductListItem>>> products(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(required = false) String buscar,
            @RequestParam(required = false) String categoria,
            @RequestParam(required = false) Boolean estado,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                reads.products(
                        identities.resolve(authentication),
                        uotId,
                        buscar,
                        categoria,
                        estado,
                        pagina,
                        tamano
                ),
                request,
                result -> PageResponse.from(result, mapper::response)
        );
    }

    @GetMapping("/productos/{id}")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'PRODUCTOS_VER')")
    @Operation(
            operationId = "recursosProductosVer",
            summary = "Ver detalle de producto y precio vigente",
            description = "Devuelve el precio vigente de la UOT sin exponer versiones históricas."
    )
    public ResponseEntity<ApiResponse<ResourceResponses.ProductDetail>> product(
            @PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                reads.product(identities.resolve(authentication), uotId, id),
                request,
                mapper::response
        );
    }

    @PostMapping("/productos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotContextoId,'PRODUCTOS_CREAR')")
    @Operation(
            operationId = "recursosProductosCrear",
            summary = "Registrar un producto reutilizable",
            description = "Si no se envía código, DESCO genera uno para la UOT."
    )
    public ResponseEntity<ApiResponse<ResourceResponses.ProductCreated>> createProduct(
            @Valid @RequestBody ResourceRequests.CreateProduct body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                experience.createProduct(
                        identities.resolve(authentication),
                        new ResourceCommands.CreateProduct(
                                body.uotContextoId(),
                                body.codigo(),
                                body.nombre(),
                                body.descripcion(),
                                body.unidadMedida(),
                                body.categoria(),
                                idempotency.required(request)
                        )
                ),
                request,
                ResourceResponses.ProductCreated::new
        );
    }

    @GetMapping("/productos/{id}/precios/historial")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'PRODUCTOS_PRECIO_HISTORIAL')")
    @Operation(
            operationId = "recursosProductosHistorialPrecios",
            summary = "Listar historial de precios del producto por UOT"
    )
    public ResponseEntity<ApiResponse<List<ResourceResponses.PriceHistory>>> priceHistory(
            @PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                priceHistory.list(
                        identities.resolve(authentication),
                        uotId,
                        id
                ),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @PostMapping("/productos/{id}/precios/{precioId}/reactivar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'PRODUCTOS_PRECIO') and @permissionGuard.hasUot(authentication,#body.uotId,'PRODUCTOS_PRECIO_HISTORIAL')")
    @Operation(
            operationId = "recursosProductosReactivarPrecio",
            summary = "Reactivar una versión histórica como nueva versión vigente",
            description = "No modifica la fila histórica. Cierra el precio vigente y crea una nueva versión copiando el importe y la moneda de la versión seleccionada."
    )
    public ResponseEntity<ApiResponse<ResourceResponses.PriceReactivated>> reactivatePrice(
            @PathVariable @Positive Long id,
            @PathVariable @Positive Long precioId,
            @Valid @RequestBody ResourceRequests.ReactivatePrice body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                priceHistory.reactivate(
                        identities.resolve(authentication),
                        body.uotId(),
                        id,
                        precioId,
                        idempotency.required(request)
                ),
                request,
                mapper::response
        );
    }

    @PostMapping("/productos/{id}/precios")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotContextoId,'PRODUCTOS_PRECIO')")
    @Operation(
            operationId = "recursosProductosVersionarPrecio",
            summary = "Crear una nueva versión de precio de venta"
    )
    public ResponseEntity<ApiResponse<ResourceResponses.PriceCreated>> price(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceRequests.VersionPrice body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.versionPrice(
                        identities.resolve(authentication),
                        new ResourceCommands.VersionPrice(
                                body.uotContextoId(),
                                id,
                                body.uotPrecioId(),
                                body.precio(),
                                body.moneda(),
                                idempotency.required(request)
                        )
                ),
                request,
                ResourceResponses.PriceCreated::new
        );
    }

    @GetMapping("/almacenes")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_LISTAR')")
    @Operation(
            operationId = "recursosAlmacenesListar",
            summary = "Listar almacenes propios y compartidos"
    )
    public ResponseEntity<ApiResponse<List<ResourceResponses.Warehouse>>> warehouses(
            @RequestParam(required = false) @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.warehouses(
                        identities.resolve(authentication),
                        uotId
                ),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @PostMapping("/almacenes")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'ALMACENES_CREAR')")
    @Operation(
            operationId = "recursosAlmacenesCrear",
            summary = "Registrar un almacén",
            description = "La ubicación se informa mediante distrito, centro poblado y referencia; el usuario no ingresa el FK de ubicación."
    )
    public ResponseEntity<ApiResponse<ResourceResponses.WarehouseCreated>> createWarehouse(
            @Valid @RequestBody ResourceRequests.CreateWarehouse body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        ResourceRequests.WarehouseLocation location = body.ubicacion();

        return responses.from(
                experience.createWarehouse(
                        identities.resolve(authentication),
                        body.uotId(),
                        location.distritoCodigo(),
                        location.centroPobladoId(),
                        location.referencia(),
                        body.codigo(),
                        body.nombre(),
                        body.descripcion(),
                        idempotency.required(request)
                ),
                request,
                ResourceResponses.WarehouseCreated::new
        );
    }

    @PostMapping("/almacenes/{id}/compartir")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_CREAR')")
    @Operation(
            operationId = "recursosAlmacenesCompartir",
            summary = "Compartir un almacén con otra UOT"
    )
    public ResponseEntity<ApiResponse<Void>> share(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceRequests.ShareWarehouse body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.shareWarehouse(
                        identities.resolve(authentication),
                        new ResourceCommands.ShareWarehouse(
                                id,
                                body.uotId(),
                                body.permiteEntrada(),
                                body.permiteSalida()
                        )
                ),
                request
        );
    }

    @PostMapping("/almacenes/{id}/productos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'ALMACENES_MOVIMIENTO')")
    @Operation(
            operationId = "recursosAlmacenesConfigurarProducto",
            summary = "Agregar un producto al almacén y definir su stock inicial",
            description = "Si el stock inicial es mayor que cero, DESCO registra una entrada en Kardex en lugar de modificar el saldo directamente."
    )
    public ResponseEntity<ApiResponse<ResourceResponses.WarehouseProductConfigured>> configureWarehouseProduct(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceRequests.ConfigureWarehouseProduct body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                experience.configureWarehouseProduct(
                        identities.resolve(authentication),
                        body.uotId(),
                        id,
                        body.productoId(),
                        body.stockInicial(),
                        body.stockMinimo(),
                        body.costoUnitario(),
                        body.moneda(),
                        body.lote(),
                        body.fechaVencimiento(),
                        idempotency.required(request),
                        body.documentoReferencia(),
                        body.observacion()
                ),
                request,
                mapper::response
        );
    }

    @GetMapping("/stock")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_LISTAR')")
    @Operation(
            operationId = "recursosStockListar",
            summary = "Consultar stock actual, reservado y disponible"
    )
    public ResponseEntity<ApiResponse<List<ResourceResponses.Stock>>> stock(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(required = false) @Positive Long almacenId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.stock(
                        identities.resolve(authentication),
                        uotId,
                        almacenId
                ),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @GetMapping("/kardex")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_KARDEX')")
    @Operation(
            operationId = "recursosKardexListar",
            summary = "Consultar Kardex de productos"
    )
    public ResponseEntity<ApiResponse<List<ResourceResponses.Kardex>>> kardex(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(required = false) @Positive Long almacenId,
            @RequestParam(required = false) @Positive Long productoId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.kardex(
                        identities.resolve(authentication),
                        uotId,
                        almacenId,
                        productoId
                ),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @PostMapping("/movimientos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'ALMACENES_MOVIMIENTO')")
    @Operation(
            operationId = "recursosMovimientosRegistrar",
            summary = "Registrar un movimiento de inventario"
    )
    public ResponseEntity<ApiResponse<ResourceResponses.MovementCreated>> movement(
            @Valid @RequestBody ResourceRequests.RegisterMovement body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        List<ResourceCommands.MovementLine> lines = body.detalle().stream()
                .map(value -> new ResourceCommands.MovementLine(
                        value.productoId(),
                        value.cantidad(),
                        value.costoUnitario(),
                        value.moneda(),
                        value.lote(),
                        value.fechaVencimiento()
                ))
                .toList();

        ResourceCommands.RegisterMovement command =
                new ResourceCommands.RegisterMovement(
                        body.uotId(),
                        body.almacenId(),
                        body.tipo(),
                        body.naturaleza(),
                        idempotency.required(request),
                        lines,
                        body.proveedorPersonaId(),
                        body.proveedorEmpresaId(),
                        body.documentoReferencia(),
                        body.observacion()
                );

        return responses.from(
                useCase.registerMovement(
                        identities.resolve(authentication),
                        command
                ),
                request,
                ResourceResponses.MovementCreated::new
        );
    }
}
