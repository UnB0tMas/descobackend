package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.*;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.fieldtrip.document.E2DocumentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.Positive;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;

@RestController
@RequestMapping("/api/v1/salidas-operativas")
@Validated
@Tag(name="Documentos de salida de campo",description="Word institucional, firma y evidencias locales")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
public class E2DocumentController {
    private final E2DocumentService documents;
    private final JwtSessionIdentityResolver identity;
    private final ApiResponseFactory responses;
    private final IdempotencyKeyResolver keys;
    public E2DocumentController(E2DocumentService documents,JwtSessionIdentityResolver identity,
            ApiResponseFactory responses,IdempotencyKeyResolver keys){
        this.documents=documents;this.identity=identity;this.responses=responses;this.keys=keys;
    }
    @GetMapping("/documentos/mios")
    @Operation(operationId="salidasDocumentosMios",summary="Mis documentos y evidencias de salidas")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<List<E2DocumentService.Documento>>> mios(
            @RequestParam(required=false) @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken a,
            @Parameter(hidden=true) HttpServletRequest r){
        return responses.from(documents.listar(uotId,null,identity.resolve(a),true),r);
    }
    @GetMapping("/{id}/documentos")
    @Operation(operationId="salidasDocumentosListar",summary="Documentos de una salida")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<List<E2DocumentService.Documento>>> listar(
            @PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken a,
            @Parameter(hidden=true) HttpServletRequest r){
        return responses.from(documents.listar(uotId,id,identity.resolve(a),false),r);
    }
    @PostMapping("/{id}/documentos/generar")
    @Operation(operationId="salidasDocumentosGenerar",summary="Generar Word de solicitud confirmada")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2DocumentService.Documento>> generar(
            @PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken a,
            @Parameter(hidden=true) HttpServletRequest r){
        return responses.from(documents.generar(uotId,id,identity.resolve(a)),r);
    }
    @PostMapping(value="/{id}/documentos/adjuntar",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(operationId="salidasDocumentosAdjuntar",summary="Adjuntar documento firmado o evidencia de campo")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2DocumentService.Documento>> adjuntar(
            @PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            @RequestParam("archivo") MultipartFile archivo,
            @RequestParam String tipo,
            @Parameter(hidden=true) JwtAuthenticationToken a,
            @Parameter(hidden=true) HttpServletRequest r){
        return responses.from(documents.adjuntar(uotId,id,identity.resolve(a),archivo,tipo,
                keys.required(r)),r);
    }
}
