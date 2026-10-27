package com.franco.desco.adapter.in.web.localdocument;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.*;
import com.franco.desco.application.localdocument.LocalDocumentService;
import com.franco.desco.domain.localdocument.LocalDocumentModels;
import io.swagger.v3.oas.annotations.Parameter;
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
@Tag(name = "Documentos locales", description = "Carga y lectura autenticada de archivos almacenados en el servidor DESCO.")
@SecurityRequirement(name = "bearerAuth")
@Validated
public class LocalDocumentController {
    private final LocalDocumentService service;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public LocalDocumentController(LocalDocumentService service, ApiResponseFactory responses,
                                   JwtSessionIdentityResolver identities, IdempotencyKeyResolver idempotency) {
        this.service = service;
        this.responses = responses;
        this.identities = identities;
        this.idempotency = idempotency;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @IdempotentOperation
    public ResponseEntity<ApiResponse<LocalDocumentModels.FileInfo>> upload(
            @RequestParam @Positive Long uotId,
            @RequestPart("archivo") MultipartFile archivo,
            @RequestParam(defaultValue = "DOCUMENTO") String categoria,
            @RequestParam(required = false) @Size(max = 400) String descripcion,
            @RequestParam(defaultValue = "NINGUNO") String vinculoTipo,
            @RequestParam(required = false) @Positive Long vinculoId,
            @RequestParam(defaultValue = "false") boolean principal,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.upload(identities.resolve(authentication), uotId, archivo, categoria, descripcion,
                vinculoTipo, vinculoId, principal, idempotency.required(request)), request);
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<LocalDocumentModels.FileInfo>>> list(
            @RequestParam(required = false) @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.list(identities.resolve(authentication), uotId), request);
    }

    @GetMapping("/{archivoId}/contenido")
    public ResponseEntity<?> content(
            @PathVariable @Positive Long archivoId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        var result = service.content(identities.resolve(authentication), archivoId);
        if (!result.exitoso() || result.datos() == null) return responses.from(result, request);
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
    public ResponseEntity<ApiResponse<Void>> retire(
            @PathVariable @Positive Long archivoId,
            @RequestParam @NotBlank @Size(max = 300) String motivo,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.retire(identities.resolve(authentication), archivoId, motivo, idempotency.required(request)), request);
    }
}
