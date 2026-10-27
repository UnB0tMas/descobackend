package com.franco.desco.adapter.in.web.incident;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.incident.IncidentCommands;
import com.franco.desco.application.incident.port.in.IncidentUseCase;
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
@RequestMapping("/api/v1/incidencias")
@Tag(name="Incidencias operativas", description="Registro, revisión, resolución y anulación de incidencias operativas.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class IncidentController {
    private final IncidentUseCase useCase;
    private final IncidentWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public IncidentController(IncidentUseCase useCase, IncidentWebMapper mapper, ApiResponseFactory responses,
                              ClientRequestContextResolver metadata, JwtSessionIdentityResolver identities) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'INCIDENCIAS_LISTAR')")
    @Operation(operationId="incidenciasListar", summary="Listar incidencias operativas")
    public ResponseEntity<ApiResponse<PageResponse<IncidentResponses.Summary>>> list(
            @RequestParam(required=false) Long operativoVentaId,
            @RequestParam(required=false) Long entregaSocioId,
            @RequestParam(required=false) String estadoIncidencia,
            @RequestParam(required=false) String tipoIncidencia,
            @RequestParam(required=false) String severidad,
            @RequestParam(defaultValue="1") @Min(1) int pagina,
            @RequestParam(defaultValue="20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(
                useCase.list(mapper.list(pagina, tamano, operativoVentaId, entregaSocioId, estadoIncidencia, tipoIncidencia, severidad),
                        identities.resolve(authentication), metadata.resolve(request)),
                request,
                p -> PageResponse.from(p, mapper::response)
        );
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'INCIDENCIAS_VER')")
    @Operation(operationId="incidenciasVer", summary="Ver detalle de incidencia")
    public ResponseEntity<ApiResponse<IncidentResponses.Detail>> get(
            @PathVariable Long id,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.get(new IncidentCommands.GetIncident(id), identities.resolve(authentication), metadata.resolve(request)),
                request, mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INCIDENCIAS_CREAR')")
    @Operation(operationId="incidenciasCrear", summary="Registrar incidencia")
    public ResponseEntity<ApiResponse<IncidentResponses.Created>> create(
            @Valid @RequestBody IncidentRequests.Create body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.create(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)),
                request, IncidentResponses.Created::new);
    }

    @PutMapping("/{id}/revision")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INCIDENCIAS_EDITAR')")
    @Operation(operationId="incidenciasRevisar", summary="Actualizar incidencia y colocarla en revisión")
    public ResponseEntity<ApiResponse<Void>> review(
            @PathVariable Long id,
            @Valid @RequestBody IncidentRequests.Review body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.review(mapper.command(id, body), identities.resolve(authentication), metadata.resolve(request)), request);
    }

    @PostMapping("/{id}/resolver")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INCIDENCIAS_EDITAR') or @permissionGuard.has(authentication,'INCIDENCIAS_CONFIRMAR') or @permissionGuard.has(authentication,'INCIDENCIAS_APROBAR')")
    @Operation(operationId="incidenciasResolver", summary="Resolver incidencia")
    public ResponseEntity<ApiResponse<Void>> resolve(
            @PathVariable Long id,
            @Valid @RequestBody IncidentRequests.Resolve body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.resolve(new IncidentCommands.Resolve(id, body.motivo()),
                identities.resolve(authentication), metadata.resolve(request)), request);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'INCIDENCIAS_RETIRAR')")
    @Operation(operationId="incidenciasAnular", summary="Anular incidencia")
    public ResponseEntity<ApiResponse<Void>> cancel(
            @PathVariable Long id,
            @Valid @RequestBody IncidentRequests.Cancel body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.cancel(new IncidentCommands.Cancel(id, body.motivo()),
                identities.resolve(authentication), metadata.resolve(request)), request);
    }
}
