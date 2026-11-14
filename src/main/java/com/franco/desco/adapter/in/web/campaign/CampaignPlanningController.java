package com.franco.desco.adapter.in.web.campaign;

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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/** Endpoints de planificación APAPPSS; no implementan negocio ni actualizan tablas desde Java. */
@RestController
@RequestMapping("/api/v1/campanias")
@Tag(name = "Campañas de venta", description = "Planificación de variedades, socios y jabas")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class CampaignPlanningController {
    private final CampaignPlanningSqlAdapter sql;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;

    public CampaignPlanningController(CampaignPlanningSqlAdapter sql, ApiResponseFactory responses,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata) {
        this.sql = sql;
        this.responses = responses;
        this.identities = identities;
        this.metadata = metadata;
    }

    public record PriceLine(@NotNull @Positive Integer variedadPaltaId,
                            @NotNull @DecimalMin("0.0001") BigDecimal precio) {}
    public record GradeLine(@NotNull @Positive Integer variedadPaltaId,
                            @NotBlank @Pattern(regexp="PRIMERA|SEGUNDA|DESCARTE") String calibre,
                            @NotNull @Min(0) Integer gramosDesde,@Min(0) Integer gramosHasta,
                            @NotNull @DecimalMin("0.0001") BigDecimal precioKg) {
        @AssertTrue(message="Los gramos del calibre son incoherentes")
        public boolean isRangoValido() {
            return gramosDesde != null && (gramosHasta == null || gramosHasta >= gramosDesde);
        }
    }

    public record CreatePlan(@NotNull @Positive Long uotId,
                             @NotNull @Positive Long asociacionId,
                             @NotNull @Positive Integer modalidadVentaId,
                             @NotNull @Positive Long compradorId,
                             @NotBlank @Size(max=180) String nombre,
                             @NotNull LocalDate fechaInicio,
                             @NotNull LocalDate fechaFin,
                             @Size(max=400) String observacion,
                             @Min(1) @Max(100000) Integer cupoJabas,
                             @Pattern(regexp="UOT|ASOCIACION") String origenJabas,
                             @DecimalMin("0") @DecimalMax("9.999") BigDecimal descuentoJabaKg,
                             @NotEmpty @Size(max=20) List<@Valid PriceLine> precios,
                             @NotEmpty @Size(max=60) List<@Valid GradeLine> calibres) {
        @AssertTrue(message="La campaña debe comenzar desde hoy y finalizar después de su inicio")
        public boolean isFechasValidas() {
            LocalDate hoy = LocalDate.now(java.time.ZoneId.of("America/Lima"));
            return fechaInicio != null && fechaFin != null
                && !fechaInicio.isBefore(hoy) && !fechaFin.isBefore(fechaInicio);
        }
    }

    public record UpdatePlan(@NotNull @Positive Long compradorId,
                             @NotBlank @Size(max=180) String nombre,
                             @NotNull LocalDate fechaInicio,
                             @NotNull LocalDate fechaFin,
                             @Size(max=400) String observacion,
                             @Pattern(regexp="UOT|ASOCIACION") String origenJabas,
                             @DecimalMin("0") @DecimalMax("9.999") BigDecimal descuentoJabaKg) {
        @AssertTrue(message="La campaña debe conservar fechas coherentes")
        public boolean isFechasValidas() {
            LocalDate hoy = LocalDate.now(java.time.ZoneId.of("America/Lima"));
            return fechaInicio != null && fechaFin != null && !fechaFin.isBefore(hoy)
                    && !fechaFin.isBefore(fechaInicio);
        }
    }

    public record Quantity(@NotNull @Min(0) @Max(100000) Integer cantidad, @Positive Long version,
                           @Size(max=500) String comentario) {}
    public record Retire(@NotBlank @Size(min=5, max=500) String motivo) {}
    public record Members(@NotEmpty @Size(max=100) List<@NotNull @Positive Long> sociosIds) {}

    private ResponseEntity<ApiResponse<Map<String, Object>>> call(String procedure,
            Map<String, ?> filters, Object data, JwtAuthenticationToken auth, HttpServletRequest request) {
        PersistenceResult<Map<String, Object>> outcome = sql.execute(procedure, filters, data,
                identities.resolve(auth), metadata.resolve(request));
        AppStatus status = AppStatus.fromHttp(outcome.httpSugerido(),
                outcome.exitoso() ? AppStatus.OK : AppStatus.BAD_REQUEST);
        return responses.from(new AppResult<>(outcome.exitoso(), outcome.codigo(),
                outcome.mensaje(), outcome.datos(), status), request);
    }

    @PostMapping("/plan") @IdempotentOperation
    @Operation(operationId="campaniasPlanCrear", summary="Crear campaña con variedades, precios y cupo opcional atómicamente")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_CREAR') && @permissionGuard.has(authentication,'PRECIOS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(@Valid @RequestBody CreatePlan input,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaPlan_Ins_Crear", Map.of(), input, auth, request);
    }

    @PutMapping("/{id}/plan-datos") @IdempotentOperation
    @Operation(operationId="campaniasPlanActualizarDatos", summary="Editar comprador y datos de planificación de campaña")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_EDITAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updatePlan(@PathVariable @Positive Long id,
            @Valid @RequestBody UpdatePlan input,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaPlan_Upd_Datos", Map.of("campaniaId", id), input, auth, request);
    }

    @GetMapping("/{id}/plan")
    @Operation(operationId="campaniasPlanVer", summary="Consultar cupo y asignación de jabas por participante")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_VER') && @permissionGuard.has(authentication,'PARTICIPANTES_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> detail(@PathVariable @Positive Long id,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaPlan_Sel_Detalle", Map.of("campaniaId", id), null, auth, request);
    }

    @GetMapping("/{id}/socios-elegibles")
    @Operation(operationId="campaniasPlanSociosElegibles", summary="Listar socios activos que aún no participan en campaña")
    @PreAuthorize("@permissionGuard.has(authentication,'PARTICIPANTES_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> eligible(@PathVariable @Positive Long id,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaPlan_Sel_SociosElegibles", Map.of("campaniaId", id), null, auth, request);
    }

    @PostMapping("/{id}/socios-lote") @IdempotentOperation
    @Operation(operationId="campaniasPlanIncluirSocios", summary="Guardar una selección de socios sin duplicados")
    @PreAuthorize("@permissionGuard.has(authentication,'PARTICIPANTES_CREAR') && @permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> include(@PathVariable @Positive Long id,
            @Valid @RequestBody Members body, @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaPlan_Ins_SociosLote", Map.of("campaniaId", id), body, auth, request);
    }

    @PostMapping("/{id}/participantes/{participacionId}/retirar") @IdempotentOperation
    @Operation(operationId="campaniasPlanRetirarSocio", summary="Retirar socio y liberar jabas pendientes en una operación")
    @PreAuthorize("@permissionGuard.has(authentication,'PARTICIPANTES_RETIRAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> retire(@PathVariable @Positive Long id,
            @PathVariable @Positive Long participacionId, @Valid @RequestBody Retire body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaPlan_Upd_RetirarSocio",
                Map.of("campaniaId", id, "participacionId", participacionId), body, auth, request);
    }

    @PutMapping("/{id}/participantes/{participacionId}/jabas") @IdempotentOperation
    @Operation(operationId="campaniasPlanAsignarJabas", summary="Registrar o ajustar jabas pendientes de recojo")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> assign(@PathVariable @Positive Long id,
            @PathVariable @Positive Long participacionId, @Valid @RequestBody Quantity body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaPlan_Upd_Cantidad",
                Map.of("campaniaId", id, "participacionId", participacionId), body, auth, request);
    }

    @PostMapping("/{id}/participantes/{participacionId}/jabas/entregar") @IdempotentOperation
    @Operation(operationId="campaniasPlanEntregarJabas", summary="Confirmar recojo físico con control de stock certificado")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> deliver(@PathVariable @Positive Long id,
            @PathVariable @Positive Long participacionId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaPlan_Upd_Entregar",
                Map.of("campaniaId", id, "participacionId", participacionId), null, auth, request);
    }

    @PostMapping("/{id}/participantes/{participacionId}/jabas/devolver") @IdempotentOperation
    @Operation(operationId="campaniasPlanDevolverJabas", summary="Confirmar devolución física de jabas pendientes")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> returnCrates(@PathVariable @Positive Long id,
            @PathVariable @Positive Long participacionId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaPlan_Upd_Devolver",
                Map.of("campaniaId", id, "participacionId", participacionId), null, auth, request);
    }

}
