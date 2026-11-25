package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.fieldtrip.documental.SalidaDocumentalCommand;
import com.franco.desco.application.fieldtrip.documental.port.in.SalidaDocumentalUseCase;
import io.swagger.v3.oas.annotations.Operation;
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

@RestController
@RequestMapping("/api/v1/salidas-tecnicas")
@Tag(name = "Salidas técnicas documentales", description = "Un solo expediente de correspondencia y salida E2")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class SalidaDocumentalController {
    private final SalidaDocumentalUseCase service;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    private final ApiResponseFactory responses;

    public SalidaDocumentalController(SalidaDocumentalUseCase service,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata,
            ApiResponseFactory responses) {
        this.service = service;
        this.identities = identities;
        this.metadata = metadata;
        this.responses = responses;
    }

    private ResponseEntity<ApiResponse<Object>> execute(String action, Long uotId,
            Long salidaId, Long documentoId, Object body,
            JwtAuthenticationToken authentication, HttpServletRequest request) {
        return responses.from(service.ejecutar(
                new SalidaDocumentalCommand(action, uotId, salidaId, documentoId, body),
                identities.resolve(authentication), metadata.resolve(request)), request);
    }

    @GetMapping("/contexto")
    @Operation(operationId = "salidasTecnicasContexto")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CREAR')")
    public ResponseEntity<ApiResponse<Object>> contexto(@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("CONTEXTO", uotId, null, null, null, auth, request);
    }

    @GetMapping("/responsables")
    @Operation(operationId = "salidasTecnicasResponsablesListar")
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> responsables(@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("RESPONSABLES", uotId, null, null, null, auth, request);
    }

    @PostMapping("/responsables")
    @IdempotentOperation
    @Operation(operationId = "salidasTecnicasResponsablesGuardar")
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> responsableGuardar(@RequestParam @Positive Long uotId,
            @Valid @RequestBody SalidaDocumentalWebTypes.Responsable body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("GUARDAR_RESPONSABLE", uotId, null, null, body, auth, request);
    }

    @PostMapping
    @IdempotentOperation
    @Operation(operationId = "salidasTecnicasSolicitar")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CREAR')")
    public ResponseEntity<ApiResponse<Object>> solicitar(@RequestParam @Positive Long uotId,
            @Valid @RequestBody SalidaDocumentalWebTypes.Solicitud body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("SOLICITAR", uotId, null, null, body, auth, request);
    }

    @PostMapping("/{salidaId}/enviar-borrador")
    @IdempotentOperation
    @Operation(operationId = "salidasTecnicasEnviarBorrador")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> enviarBorrador(@PathVariable @Positive Long salidaId,
            @RequestParam @Positive Long uotId,
            @Valid @RequestBody E2WebTypes.CorreccionRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("ENVIAR_BORRADOR", uotId, salidaId, null, body, auth, request);
    }

    @PostMapping("/{salidaId}/corregir")
    @IdempotentOperation
    @Operation(operationId = "salidasTecnicasCorregir")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> corregir(@PathVariable @Positive Long salidaId,
            @RequestParam @Positive Long uotId,
            @Valid @RequestBody E2WebTypes.CorreccionRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("CORREGIR", uotId, salidaId, null, body, auth, request);
    }

    @PostMapping("/{salidaId}/decision")
    @IdempotentOperation
    @Operation(operationId = "salidasTecnicasDecidir")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<Object>> decidir(@PathVariable @Positive Long salidaId,
            @RequestParam @Positive Long uotId,
            @Valid @RequestBody E2WebTypes.DecisionRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("DECIDIR", uotId, salidaId, null, body, auth, request);
    }

    @PostMapping("/{salidaId}/cancelar")
    @IdempotentOperation
    @Operation(operationId = "salidasTecnicasCancelar")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_RETIRAR')")
    public ResponseEntity<ApiResponse<Object>> cancelar(@PathVariable @Positive Long salidaId,
            @RequestParam @Positive Long uotId,
            @Valid @RequestBody E2WebTypes.CancelarRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("CANCELAR", uotId, salidaId, null, body, auth, request);
    }

    @GetMapping("/{salidaId}/expediente")
    @Operation(operationId = "salidasTecnicasExpediente")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<Object>> expediente(@PathVariable @Positive Long salidaId,
            @RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("VINCULO", uotId, salidaId, null, null, auth, request);
    }

    @GetMapping("/documentos/{documentoId}/expediente")
    @Operation(operationId = "salidasTecnicasDocumentoExpediente")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<Object>> expedienteDocumento(@PathVariable @Positive Long documentoId,
            @RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return execute("DOCUMENTO", uotId, null, documentoId, null, auth, request);
    }
}
