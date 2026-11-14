package com.franco.desco.adapter.in.web.apappss;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.infrastructure.persistence.campaign.CampaignPlanningSqlAdapter;
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

import java.util.Map;

/** El controlador valida entradas; las identidades, permisos y cambios se realizan en PA separados. */
@RestController
@RequestMapping("/api/v1/apappss")
@Tag(name = "Compradores APAPPSS", description = "Registro de personas y empresas compradoras en el convenio APAPPSS")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class ApappssBuyerController {
    private final CampaignPlanningSqlAdapter sql;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;

    public ApappssBuyerController(CampaignPlanningSqlAdapter sql, ApiResponseFactory responses,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata) {
        this.sql = sql;
        this.responses = responses;
        this.identities = identities;
        this.metadata = metadata;
    }

    public record BuyerRequest(
            @NotBlank @Pattern(regexp = "PERSONA|EMPRESA") String tipo,
            @NotBlank @Size(max = 30) String documento,
            @NotBlank @Size(max = 15) String tipoDocumento,
            @Size(max = 100) String nombres,
            @Size(max = 80) String apellidoPaterno,
            @Size(max = 80) String apellidoMaterno,
            @Size(max = 200) String razonSocial,
            @Size(max = 160) String nombreComercial,
            String fechaNacimiento,
            @Size(max = 20) String sexo,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            @Size(max = 6) String distritoCodigo,
            @Positive Long centroPobladoId,
            @Size(max = 300) String referencia) {
        @AssertTrue(message = "El tipo de documento no corresponde al comprador")
        public boolean isIdentidadValida() {
            if (tipo == null || tipoDocumento == null || documento == null) return true;
            String doc = documento.trim().toUpperCase();
            String documentType = tipoDocumento.trim().toUpperCase();
            if (!documentType.matches("[A-Z0-9_]{2,15}")) return false;
            if ("RUC".equals(documentType)) {
                return "EMPRESA".equals(tipo) && doc.matches("\\d{11}");
            }
            return "PERSONA".equals(tipo) &&
                ("DNI".equals(documentType) ? doc.matches("\\d{8}") :
                 "CE".equals(documentType) ? doc.matches("[A-Z0-9]{6,20}") :
                 doc.matches("[A-Z0-9]{5,30}"));
        }
    }

    private ResponseEntity<ApiResponse<Map<String, Object>>> call(String procedure,
            Map<String, ?> filters, Object data, JwtAuthenticationToken auth, HttpServletRequest request) {
        PersistenceResult<Map<String, Object>> outcome = sql.execute(procedure, filters, data,
                identities.resolve(auth), metadata.resolve(request));
        AppStatus status = AppStatus.fromHttp(outcome.httpSugerido(),
                outcome.exitoso() ? AppStatus.OK : AppStatus.BAD_REQUEST);
        return responses.from(new AppResult<>(outcome.exitoso(), outcome.codigo(),
                outcome.mensaje(), outcome.datos(), status), request);
    }

    @GetMapping("/contexto")
    @Operation(operationId = "apappssContexto", summary = "Asociación APAPPSS autorizada para la UOT seleccionada")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> context(@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth, @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_APAPPSS_Contexto_Sel", Map.of("uotId", uotId), null, auth, request);
    }

    @GetMapping("/compradores")
    @Operation(operationId = "apappssCompradoresListar", summary = "Buscar compradores de APAPPSS")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_COMPRADORES_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> list(@RequestParam @Positive Long uotId,
            @RequestParam(required=false) String buscar, @RequestParam(required=false) String tipo,
            @RequestParam(defaultValue="1") @Min(1) int pagina,
            @RequestParam(defaultValue="20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden=true) JwtAuthenticationToken auth, @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_APAPPSS_Comprador_Sel_Listado", Map.of("uotId", uotId,
                "buscar", buscar == null ? "" : buscar, "tipo", tipo == null ? "" : tipo,
                "pagina", pagina, "tamano", tamano), null, auth, request);
    }

    @GetMapping("/compradores/tipos-documento")
    @Operation(operationId = "apappssCompradoresTiposDocumento", summary = "Tipos de documento administrables para compradores")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_COMPRADORES_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> documentTypes(@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth, @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_APAPPSS_TipoDocumento_Sel_Listado", Map.of("uotId", uotId), null, auth, request);
    }

    @GetMapping("/compradores/identidad-local")
    @Operation(operationId = "apappssCompradoresIdentidadLocal", summary = "Buscar la identidad en DESCO antes de consultar Factiliza")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_COMPRADORES_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> localIdentity(@RequestParam @Positive Long uotId,
            @RequestParam @NotBlank @Size(max=15) String tipoDocumento,
            @RequestParam @NotBlank @Size(max=30) String documento,
            @Parameter(hidden=true) JwtAuthenticationToken auth, @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_APAPPSS_Comprador_Sel_IdentidadLocal", Map.of("uotId", uotId,
                "tipoDocumento", tipoDocumento, "documento", documento), null, auth, request);
    }

    @PostMapping("/compradores")
    @IdempotentOperation
    @Operation(operationId = "apappssCompradoresCrear", summary = "Registrar comprador persona o empresa sin duplicar identidad")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_COMPRADORES_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(@RequestParam @Positive Long uotId,
            @Valid @RequestBody BuyerRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken auth, @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_APAPPSS_Comprador_Ins_Registro", Map.of("uotId", uotId), body, auth, request);
    }

    public record BuyerUpdateRequest(
            @Size(max = 100) String nombres,
            @Size(max = 80) String apellidoPaterno,
            @Size(max = 80) String apellidoMaterno,
            @Size(max = 200) String razonSocial,
            @Size(max = 160) String nombreComercial,
            String fechaNacimiento,
            @Size(max = 20) String sexo,
            @Size(max = 30) String telefono,
            @Email @Size(max = 180) String correo,
            @Size(max = 6) String distritoCodigo,
            @Positive Long centroPobladoId,
            @Size(max = 300) String referencia) {
    }

    @GetMapping("/compradores/{id}")
    @Operation(operationId = "apappssCompradoresDetalle", summary = "Consultar datos completos del comprador")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_COMPRADORES_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> detail(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_APAPPSS_Comprador_Sel_Detalle", Map.of("uotId", uotId, "compradorId", id),
                null, auth, request);
    }

    @PutMapping("/compradores/{id}")
    @IdempotentOperation
    @Operation(operationId = "apappssCompradoresActualizar", summary = "Editar los datos de un comprador sin cambiar su identidad")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_COMPRADORES_EDITAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> update(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @Valid @RequestBody BuyerUpdateRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_APAPPSS_Comprador_Upd_Datos", Map.of("uotId", uotId, "compradorId", id),
                body, auth, request);
    }

}
