package com.franco.desco.adapter.in.web.localdocument;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.*;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.localdocument.LocalDocumentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.*;
import org.springframework.http.*;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/api/v1/documentos/local")
@Tag(name = OpenApiConstants.TAG_LOCAL_DOCUMENTS, description = OpenApiConstants.TAG_LOCAL_DOCUMENTS_DESCRIPTION)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class LocalDocumentController {
    private final LocalDocumentService service;
    private final LocalDocumentWebMapper mapper;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public LocalDocumentController(
            LocalDocumentService service,
            LocalDocumentWebMapper mapper,
            ApiResponseFactory responses,
            JwtSessionIdentityResolver identities,
            IdempotencyKeyResolver idempotency
    ) {
        this.service = service;
        this.mapper = mapper;
        this.responses = responses;
        this.identities = identities;
        this.idempotency = idempotency;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @IdempotentOperation
    @Operation(operationId = "documentosLocalesSubir", summary = "Subir un documento o imagen al almacenamiento local")
    public ResponseEntity<ApiResponse<LocalDocumentResponses.FileInfo>> upload(
            @Parameter(description = "UOT propietaria del archivo.", required = true)
            @RequestParam @Positive Long uotId,
            @Parameter(description = "Archivo binario que se almacenará en el servidor.", required = true)
            @RequestParam(name = "archivo") MultipartFile archivo,
            @Parameter(description = "Categoría lógica del archivo.")
            @RequestParam(defaultValue = "DOCUMENTO") String categoria,
            @RequestParam(required = false) @Size(max = 400) String descripcion,
            @Parameter(description = "Tipo de vínculo opcional, por ejemplo BIEN o PRODUCTO.")
            @RequestParam(defaultValue = "NINGUNO") String vinculoTipo,
            @RequestParam(required = false) @Positive Long vinculoId,
            @RequestParam(defaultValue = "false") boolean principal,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.upload(
                        identities.resolve(authentication), uotId, archivo, categoria, descripcion,
                        vinculoTipo, vinculoId, principal, idempotency.required(request)
                ),
                request,
                mapper::response
        );
    }

    @GetMapping
    @Operation(operationId = "documentosLocalesListar", summary = "Listar archivos locales autorizados")
    public ResponseEntity<ApiResponse<List<LocalDocumentResponses.FileInfo>>> list(
            @RequestParam(required = false) @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.list(identities.resolve(authentication), uotId),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @GetMapping(value = "/{archivoId}/contenido")
    @Operation(operationId = "documentosLocalesContenido", summary = "Descargar o visualizar el contenido autenticado de un archivo")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "200",
            description = "Contenido binario del archivo. El Content-Type real corresponde al MIME almacenado.",
            content = @Content(
                    mediaType = MediaType.APPLICATION_OCTET_STREAM_VALUE,
                    schema = @Schema(type = "string", format = "binary")
            )
    )
    public ResponseEntity<?> content(
            @PathVariable @Positive Long archivoId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        var result = service.content(identities.resolve(authentication), archivoId);
        if (!result.exitoso() || result.datos() == null) {
            return responses.from(result, request);
        }

        var content = result.datos();
        ContentDisposition disposition = ContentDisposition.inline()
                .filename(content.info().originalName(), StandardCharsets.UTF_8)
                .build();

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.info().contentType()))
                .contentLength(content.info().size())
                .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                .header("X-Content-Type-Options", "nosniff")
                .body(content.resource());
    }

    @PostMapping("/{archivoId}/retirar")
    @IdempotentOperation
    @Operation(operationId = "documentosLocalesRetirar", summary = "Retirar lógicamente un archivo y encolar su eliminación física")
    public ResponseEntity<ApiResponse<Void>> retire(
            @PathVariable @Positive Long archivoId,
            @RequestParam @NotBlank @Size(max = 300) String motivo,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                service.retire(
                        identities.resolve(authentication), archivoId, motivo, idempotency.required(request)
                ),
                request
        );
    }
}
