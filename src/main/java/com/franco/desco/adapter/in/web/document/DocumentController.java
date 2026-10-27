package com.franco.desco.adapter.in.web.document;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.document.DocumentCommands;
import com.franco.desco.application.document.port.in.DocumentUseCase;
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

import java.time.Instant;

@RestController
@RequestMapping("/api/v1/documentos")
@Tag(name = "Documentos y evidencias", description = "Metadatos y vinculos de documentos/evidencias almacenados externamente.")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class DocumentController {

    private final DocumentUseCase useCase;
    private final DocumentWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public DocumentController(DocumentUseCase useCase, DocumentWebMapper mapper, ApiResponseFactory responses,
                              ClientRequestContextResolver metadata, JwtSessionIdentityResolver identities) {
        this.useCase = useCase; this.mapper = mapper; this.responses = responses; this.metadata = metadata; this.identities = identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'ARCHIVOS_LISTAR')")
    @Operation(operationId = "documentosListar", summary = "Listar documentos y evidencias autorizados")
    public ResponseEntity<ApiResponse<PageResponse<DocumentResponses.Summary>>> list(
            @RequestParam(required = false) String tipoEvidencia,
            @RequestParam(required = false) String origenCaptura,
            @RequestParam(required = false) Long usuarioId,
            @RequestParam(required = false) String contextoTipo,
            @RequestParam(required = false) Long contextoId,
            @RequestParam(required = false) Instant fechaDesde,
            @RequestParam(required = false) Instant fechaHasta,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.list(mapper.list(pagina, tamano, tipoEvidencia, origenCaptura, usuarioId, contextoTipo, contextoId, fechaDesde, fechaHasta),
                        identities.resolve(authentication), metadata.resolve(request)),
                request,
                page -> PageResponse.from(page, mapper::response)
        );
    }

    @GetMapping("/{archivoId}")
    @PreAuthorize("@permissionGuard.has(authentication,'ARCHIVOS_VER')")
    @Operation(operationId = "documentosVer", summary = "Ver detalle de un documento")
    public ResponseEntity<ApiResponse<DocumentResponses.Detail>> get(
            @PathVariable Long archivoId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(useCase.get(new DocumentCommands.GetDocument(archivoId), identities.resolve(authentication), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ARCHIVOS_CREAR')")
    @Operation(operationId = "documentosRegistrar", summary = "Registrar metadatos y vinculo de un archivo ya almacenado externamente")
    public ResponseEntity<ApiResponse<DocumentResponses.Created>> register(
            @Valid @RequestBody DocumentRequests.Register body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(useCase.register(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)), request, DocumentResponses.Created::new);
    }

    @PostMapping("/{archivoId}/retirar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'ARCHIVOS_RETIRAR')")
    @Operation(operationId = "documentosRetirar", summary = "Retirar un documento")
    public ResponseEntity<ApiResponse<Void>> retire(
            @PathVariable Long archivoId,
            @Valid @RequestBody DocumentRequests.Retire body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(useCase.retire(new DocumentCommands.RetireDocument(archivoId, body.motivo()), identities.resolve(authentication), metadata.resolve(request)), request);
    }
}
