package com.franco.desco.adapter.in.web.organization;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.organization.OrganizationCommands.GetOrganization;
import com.franco.desco.application.organization.port.in.OrganizationUseCase;
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
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/organizaciones")
@Tag(name = "Organizaciones", description = "Empresas, asociaciones y áreas de DESCO.")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class OrganizationController {

    private final OrganizationUseCase useCase;
    private final OrganizationWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public OrganizationController(OrganizationUseCase useCase, OrganizationWebMapper mapper, ApiResponseFactory responses, ClientRequestContextResolver metadata, JwtSessionIdentityResolver identities) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    private SessionIdentity identity(JwtAuthenticationToken authentication) {
        return identities.resolve(authentication);
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_LISTAR')")
    @Operation(operationId = "organizacionesListar", summary = "Listar organizaciones")
    public ResponseEntity<ApiResponse<PageResponse<OrganizationResponses.Summary>>> list(@RequestParam(defaultValue = "1") @Min(1) int pagina, @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.list(mapper.list(pagina, tamano), identity(authentication), metadata.resolve(request)), request, page -> PageResponse.from(page, mapper::response));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_VER')")
    @Operation(operationId = "organizacionesVer", summary = "Ver organización")
    public ResponseEntity<ApiResponse<OrganizationResponses.Detail>> get(@PathVariable Long id, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.get(new GetOrganization(id), identity(authentication), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/empresas")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_CREAR')")
    @Operation(operationId = "organizacionesCrearEmpresa", summary = "Registrar empresa")
    public ResponseEntity<ApiResponse<OrganizationResponses.CreatedId>> createCompany(@Valid @RequestBody OrganizationRequests.CreateCompany body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.createCompany(mapper.command(body), identity(authentication), metadata.resolve(request)), request, OrganizationResponses.CreatedId::new);
    }

    @PutMapping("/empresas/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_EDITAR')")
    @Operation(operationId = "organizacionesEditarEmpresa", summary = "Editar empresa")
    public ResponseEntity<ApiResponse<Void>> updateCompany(@PathVariable Long id, @Valid @RequestBody OrganizationRequests.UpdateCompany body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.updateCompany(mapper.command(id, body), identity(authentication), metadata.resolve(request)), request);
    }

    @PostMapping("/asociaciones")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_CREAR')")
    @Operation(operationId = "organizacionesCrearAsociacion", summary = "Registrar asociación")
    public ResponseEntity<ApiResponse<OrganizationResponses.CreatedId>> createAssociation(@Valid @RequestBody OrganizationRequests.CreateAssociation body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.createAssociation(mapper.command(body), identity(authentication), metadata.resolve(request)), request, OrganizationResponses.CreatedId::new);
    }

    @PutMapping("/asociaciones/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_EDITAR')")
    @Operation(operationId = "organizacionesEditarAsociacion", summary = "Editar asociación")
    public ResponseEntity<ApiResponse<Void>> updateAssociation(@PathVariable Long id, @Valid @RequestBody OrganizationRequests.UpdateAssociation body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.updateAssociation(mapper.command(id, body), identity(authentication), metadata.resolve(request)), request);
    }

    @PostMapping("/{id}/deshabilitar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_RETIRAR')")
    @Operation(operationId = "organizacionesDeshabilitar", summary = "Deshabilitar organización")
    public ResponseEntity<ApiResponse<Void>> disableOrganization(@PathVariable Long id, @Valid @RequestBody OrganizationRequests.Disable body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.disableOrganization(mapper.disableOrganization(id, body), identity(authentication), metadata.resolve(request)), request);
    }

    @GetMapping("/areas")
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_LISTAR')")
    @Operation(operationId = "organizacionesListarAreas", summary = "Listar áreas")
    public ResponseEntity<ApiResponse<PageResponse<OrganizationResponses.Area>>> areas(@RequestParam(required = false) Long empresaId, @RequestParam(defaultValue = "1") @Min(1) int pagina, @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.listAreas(mapper.listAreas(pagina, tamano, empresaId), identity(authentication), metadata.resolve(request)), request, page -> PageResponse.from(page, mapper::response));
    }

    @PostMapping("/areas")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_CREAR')")
    @Operation(operationId = "organizacionesCrearArea", summary = "Registrar área")
    public ResponseEntity<ApiResponse<OrganizationResponses.CreatedId>> createArea(@Valid @RequestBody OrganizationRequests.CreateArea body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.createArea(mapper.command(body), identity(authentication), metadata.resolve(request)), request, OrganizationResponses.CreatedId::new);
    }

    @PutMapping("/areas/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_EDITAR')")
    @Operation(operationId = "organizacionesEditarArea", summary = "Editar área")
    public ResponseEntity<ApiResponse<Void>> updateArea(@PathVariable Long id, @Valid @RequestBody OrganizationRequests.UpdateArea body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.updateArea(mapper.command(id, body), identity(authentication), metadata.resolve(request)), request);
    }

    @PostMapping("/areas/{id}/deshabilitar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_RETIRAR')")
    @Operation(operationId = "organizacionesDeshabilitarArea", summary = "Deshabilitar área y subáreas")
    public ResponseEntity<ApiResponse<Void>> disableArea(@PathVariable Long id, @Valid @RequestBody OrganizationRequests.Disable body, @Parameter(hidden = true) JwtAuthenticationToken authentication, @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.disableArea(mapper.disableArea(id, body), identity(authentication), metadata.resolve(request)), request);
    }
}
