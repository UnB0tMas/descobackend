package com.franco.desco.adapter.in.web.supplier;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.supplier.port.in.SupplierUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
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
@RequestMapping("/api/v1/proveedores")
@Tag(name = "Proveedores", description = "Personas y empresas proveedoras por UOT")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class SupplierController {
    private final SupplierUseCase service;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    public SupplierController(SupplierUseCase service, ApiResponseFactory responses,
                              JwtSessionIdentityResolver identities) {
        this.service = service; this.responses = responses; this.identities = identities;
    }

    @GetMapping(path = {"", "/"})
    @Operation(operationId = "proveedoresListar", summary = "Listar proveedores por UOT")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'ORGANIZACIONES_LISTAR')")
    public ResponseEntity<ApiResponse<SupplierWebTypes.Page>> list(
        @RequestParam @Positive Long uotId,
        @RequestParam(required = false) String buscar,
        @RequestParam(required = false) @Pattern(regexp = "PERSONA|EMPRESA") String tipo,
        @RequestParam(defaultValue = "false") boolean soloActivos,
        @RequestParam(defaultValue = "1") @Min(1) int pagina,
        @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
        @Parameter(hidden = true) JwtAuthenticationToken authentication,
        @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.list(uotId, buscar, tipo, soloActivos, pagina, tamano,
            identities.resolve(authentication)), request);
    }

    @PostMapping
    @IdempotentOperation
    @Operation(operationId = "proveedoresRegistrar", summary = "Registrar o vincular proveedor")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#data.uotId,'ORGANIZACIONES_CREAR')")
    public ResponseEntity<ApiResponse<SupplierWebTypes.Registered>> register(
        @Valid @RequestBody SupplierWebTypes.Save data,
        @Parameter(hidden = true) JwtAuthenticationToken authentication,
        @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.register(data, identities.resolve(authentication)), request);
    }

    @PutMapping("/{id}")
    @IdempotentOperation
    @Operation(operationId = "proveedoresActualizar", summary = "Actualizar datos de proveedor")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#data.uotId,'ORGANIZACIONES_EDITAR')")
    public ResponseEntity<ApiResponse<SupplierWebTypes.Registered>> update(
        @PathVariable @Positive Long id, @Valid @RequestBody SupplierWebTypes.Save data,
        @Parameter(hidden = true) JwtAuthenticationToken authentication,
        @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.update(id, data, identities.resolve(authentication)), request);
    }

    @PutMapping("/{id}/estado")
    @IdempotentOperation
    @Operation(operationId = "proveedoresEstado", summary = "Habilitar o deshabilitar proveedor")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'ORGANIZACIONES_EDITAR')")
    public ResponseEntity<ApiResponse<SupplierWebTypes.Registered>> state(
        @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
        @RequestParam boolean estado,
        @Parameter(hidden = true) JwtAuthenticationToken authentication,
        @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.setState(uotId, id, estado, identities.resolve(authentication)), request);
    }
}
