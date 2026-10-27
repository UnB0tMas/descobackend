package com.franco.desco.adapter.in.web.resource;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.*;
import com.franco.desco.application.resource.ResourceCommands;
import com.franco.desco.application.resource.port.in.ResourceUseCase;
import com.franco.desco.domain.resource.ResourceModels;
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

@RestController
@RequestMapping("/api/v1/recursos")
@Tag(name="Recursos",description="Bienes patrimoniales, productos, almacenes, stock y Kardex multi-UOT.")
@SecurityRequirement(name="bearerAuth")
@Validated
public class ResourceController {
    private final ResourceUseCase useCase;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public ResourceController(ResourceUseCase useCase, ApiResponseFactory responses, JwtSessionIdentityResolver identities, IdempotencyKeyResolver idempotency){
        this.useCase=useCase;this.responses=responses;this.identities=identities;this.idempotency=idempotency;
    }

    @GetMapping("/bienes")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_LISTAR')")
    public ResponseEntity<ApiResponse<List<ResourceModels.Asset>>> assets(@RequestParam(required=false) @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.assets(identities.resolve(authentication),uotId),request);
    }

    @GetMapping("/bienes/{id}")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_VER')")
    public ResponseEntity<ApiResponse<ResourceModels.AssetDetail>> asset(@PathVariable @Positive Long id,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.asset(identities.resolve(authentication),id),request);
    }

    @PostMapping("/bienes")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'INVENTARIO_CREAR')")
    public ResponseEntity<ApiResponse<Long>> createAsset(@Valid @RequestBody ResourceRequests.CreateAsset body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        var c=new ResourceCommands.CreateAsset(body.uotId(),body.tipoBienId(),body.codigoPatrimonial(),body.nombre(),body.marca(),body.modelo(),body.serie(),body.fechaAdquisicion(),body.montoAdquisicion(),body.moneda(),body.proveedorPersonaId(),body.proveedorEmpresaId(),body.observacion(),idempotency.required(request));
        return responses.from(useCase.createAsset(identities.resolve(authentication),c),request);
    }

    @PutMapping("/bienes/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_EDITAR')")
    public ResponseEntity<ApiResponse<Void>> updateAsset(@PathVariable @Positive Long id,@Valid @RequestBody ResourceRequests.UpdateAsset body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        var c=new ResourceCommands.UpdateAsset(id,body.tipoBienId(),body.nombre(),body.marca(),body.modelo(),body.serie(),body.fechaAdquisicion(),body.montoAdquisicion(),body.moneda(),body.proveedorPersonaId(),body.proveedorEmpresaId(),body.observacion());
        return responses.from(useCase.updateAsset(identities.resolve(authentication),c),request);
    }

    @PostMapping("/bienes/{id}/estado")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_EDITAR')")
    public ResponseEntity<ApiResponse<Void>> changeState(@PathVariable @Positive Long id,@Valid @RequestBody ResourceRequests.ChangeAssetState body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.changeAssetState(identities.resolve(authentication),new ResourceCommands.ChangeAssetState(id,body.estado(),body.motivo())),request);
    }

    @PostMapping("/bienes/{id}/incidentes")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'INVENTARIO_EDITAR')")
    public ResponseEntity<ApiResponse<Long>> incident(@PathVariable @Positive Long id,@Valid @RequestBody ResourceRequests.Incident body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.reportIncident(identities.resolve(authentication),new ResourceCommands.ReportIncident(id,body.tipo(),body.fechaHora(),body.descripcion(),body.costoEstimado(),idempotency.required(request))),request);
    }

    @GetMapping("/productos")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'PRODUCTOS_LISTAR')")
    public ResponseEntity<ApiResponse<List<ResourceModels.Product>>> products(@RequestParam(required=false) @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.products(identities.resolve(authentication),uotId),request);
    }

    @PostMapping("/productos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotContextoId,'PRODUCTOS_CREAR')")
    public ResponseEntity<ApiResponse<Long>> createProduct(@Valid @RequestBody ResourceRequests.CreateProduct body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.createProduct(identities.resolve(authentication),new ResourceCommands.CreateProduct(body.uotContextoId(),body.codigo(),body.nombre(),body.descripcion(),body.unidadMedida(),body.categoria(),idempotency.required(request))),request);
    }

    @PostMapping("/productos/{id}/precios")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotContextoId,'PRODUCTOS_PRECIO')")
    public ResponseEntity<ApiResponse<Long>> price(@PathVariable @Positive Long id,@Valid @RequestBody ResourceRequests.VersionPrice body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        return responses.from(useCase.versionPrice(identities.resolve(authentication),new ResourceCommands.VersionPrice(body.uotContextoId(),id,body.uotPrecioId(),body.precio(),body.moneda(),idempotency.required(request))),request);
    }

    @GetMapping("/almacenes")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_LISTAR')")
    public ResponseEntity<ApiResponse<List<ResourceModels.Warehouse>>> warehouses(@RequestParam(required=false) @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){return responses.from(useCase.warehouses(identities.resolve(authentication),uotId),request);}

    @PostMapping("/almacenes")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'ALMACENES_CREAR')")
    public ResponseEntity<ApiResponse<Long>> createWarehouse(@Valid @RequestBody ResourceRequests.CreateWarehouse body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){return responses.from(useCase.createWarehouse(identities.resolve(authentication),new ResourceCommands.CreateWarehouse(body.uotId(),body.ubicacionId(),body.codigo(),body.nombre(),body.descripcion(),idempotency.required(request))),request);}

    @PostMapping("/almacenes/{id}/compartir")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_CREAR')")
    public ResponseEntity<ApiResponse<Void>> share(@PathVariable @Positive Long id,@Valid @RequestBody ResourceRequests.ShareWarehouse body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){return responses.from(useCase.shareWarehouse(identities.resolve(authentication),new ResourceCommands.ShareWarehouse(id,body.uotId(),body.permiteEntrada(),body.permiteSalida())),request);}

    @GetMapping("/stock")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_LISTAR')")
    public ResponseEntity<ApiResponse<List<ResourceModels.Stock>>> stock(@RequestParam(required=false) @Positive Long uotId,@RequestParam(required=false) @Positive Long almacenId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){return responses.from(useCase.stock(identities.resolve(authentication),uotId,almacenId),request);}

    @GetMapping("/kardex")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'ALMACENES_KARDEX')")
    public ResponseEntity<ApiResponse<List<ResourceModels.Kardex>>> kardex(@RequestParam(required=false) @Positive Long uotId,@RequestParam(required=false) @Positive Long almacenId,@RequestParam(required=false) @Positive Long productoId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){return responses.from(useCase.kardex(identities.resolve(authentication),uotId,almacenId,productoId),request);}

    @PostMapping("/movimientos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'ALMACENES_MOVIMIENTO')")
    public ResponseEntity<ApiResponse<Long>> movement(@Valid @RequestBody ResourceRequests.RegisterMovement body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request){
        List<ResourceCommands.MovementLine> lines=body.detalle().stream().map(x->new ResourceCommands.MovementLine(x.productoId(),x.cantidad(),x.costoUnitario(),x.moneda(),x.lote(),x.fechaVencimiento())).toList();
        var c=new ResourceCommands.RegisterMovement(body.uotId(),body.almacenId(),body.tipo(),body.naturaleza(),idempotency.required(request),lines,body.proveedorPersonaId(),body.proveedorEmpresaId(),body.documentoReferencia(),body.observacion());
        return responses.from(useCase.registerMovement(identities.resolve(authentication),c),request);
    }
}
