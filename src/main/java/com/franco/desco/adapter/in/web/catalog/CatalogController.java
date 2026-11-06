package com.franco.desco.adapter.in.web.catalog;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.catalog.port.in.CatalogUseCase;
import com.franco.desco.application.catalog.service.ResourceCatalogService;
import com.franco.desco.application.shared.SessionIdentity;
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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/catalogos")
@Tag(name = "Catálogos", description = "Catálogos maestros administrables.")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class CatalogController {

    private final CatalogUseCase useCase;
    private final ResourceCatalogService resourceCatalogs;
    private final CatalogWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public CatalogController(
            CatalogUseCase useCase,
            ResourceCatalogService resourceCatalogs,
            CatalogWebMapper mapper,
            ApiResponseFactory responses,
            ClientRequestContextResolver metadata,
            JwtSessionIdentityResolver identities
    ) {
        this.useCase = useCase;
        this.resourceCatalogs = resourceCatalogs;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'REFERENCIAS_LISTAR') or (#catalogo == 'TIPO_TITULARIDAD' and @permissionGuard.has(authentication,'PREDIOS_LISTAR'))")
    @Operation(operationId = "catalogosListar", summary = "Listar valores de catálogo")
    public ResponseEntity<ApiResponse<PageResponse<CatalogResponses.Item>>> list(
            @RequestParam String catalogo,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        var command = mapper.list(catalogo, pagina, tamano);
        SessionIdentity identity = identities.resolve(authentication);

        if (resourceCatalogs.supports(catalogo)) {
            return responses.from(
                    resourceCatalogs.list(command, identity),
                    request,
                    result -> PageResponse.from(result, mapper::response)
            );
        }

        return responses.from(
                useCase.list(command, identity, metadata.resolve(request)),
                request,
                result -> PageResponse.from(result, mapper::response)
        );
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
    @Operation(operationId = "catalogosCrear", summary = "Registrar valor")
    public ResponseEntity<ApiResponse<CatalogResponses.Created>> create(
            @Valid @RequestBody CatalogRequests.Create body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        var command = mapper.command(body);
        SessionIdentity identity = identities.resolve(authentication);

        if (resourceCatalogs.supports(body.catalogo())) {
            return responses.from(
                    resourceCatalogs.create(command, identity),
                    request,
                    CatalogResponses.Created::new
            );
        }

        return responses.from(
                useCase.create(command, identity, metadata.resolve(request)),
                request,
                CatalogResponses.Created::new
        );
    }

    @PutMapping("/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_EDITAR')")
    @Operation(operationId = "catalogosEditar", summary = "Editar valor")
    public ResponseEntity<ApiResponse<Void>> update(
            @PathVariable Long id,
            @Valid @RequestBody CatalogRequests.Update body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        var command = mapper.command(id, body);
        SessionIdentity identity = identities.resolve(authentication);

        if (resourceCatalogs.supports(body.catalogo())) {
            return responses.from(resourceCatalogs.update(command, identity), request);
        }

        return responses.from(
                useCase.update(command, identity, metadata.resolve(request)),
                request
        );
    }

    @PostMapping("/{id}/deshabilitar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_RETIRAR')")
    @Operation(operationId = "catalogosDeshabilitar", summary = "Deshabilitar valor")
    public ResponseEntity<ApiResponse<Void>> disable(
            @PathVariable Long id,
            @Valid @RequestBody CatalogRequests.Disable body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        var command = mapper.command(id, body);
        SessionIdentity identity = identities.resolve(authentication);

        if (resourceCatalogs.supports(body.catalogo())) {
            return responses.from(resourceCatalogs.disable(command, identity), request);
        }

        return responses.from(
                useCase.disable(command, identity, metadata.resolve(request)),
                request
        );
    }
}
