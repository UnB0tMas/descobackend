package com.franco.desco.adapter.in.web.campaign;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.shared.*;
import com.franco.desco.infrastructure.persistence.campaign.CampaignPlanningSqlAdapter;
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
import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@Tag(name="Sanciones de campaña",description="Catálogo, descuentos de campaña y sanción por socio")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class CampaignSanctionController {
    private final CampaignPlanningSqlAdapter sql;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    public CampaignSanctionController(CampaignPlanningSqlAdapter sql,ApiResponseFactory responses,
            JwtSessionIdentityResolver identities,ClientRequestContextResolver metadata) {
        this.sql=sql;this.responses=responses;this.identities=identities;this.metadata=metadata;
    }
    public record CatalogCreate(@NotBlank @Size(max=120) String nombre, @Size(max=300) String descripcion) {}
    public record CatalogUpdate(@NotBlank @Size(max=120) String nombre,@Size(max=300) String descripcion) {}
    public record TariffLine(@NotNull @Positive Long sancionId, @NotNull @DecimalMin("0.0001")
        @Digits(integer=10,fraction=4) BigDecimal descuentoKg) {}
    public record TariffBatch(@NotNull @Size(max=30) java.util.List<@Valid TariffLine> tarifas) {}
    public record Tariff(@NotNull @Positive Long sancionId,@NotNull @DecimalMin("0.0001")
        @Digits(integer=10,fraction=4) BigDecimal descuentoKg) {}
    public record Assignment(@NotNull @Positive Long tarifaId,
        @NotBlank @Pattern(regexp="TODAS|CANTIDAD") String alcance,@Positive Integer cantidad,
        @NotBlank @Size(min=10,max=500) String comentario) {}
    public record Reason(@NotBlank @Size(min=10,max=500) String motivo) {}

    private ResponseEntity<ApiResponse<Map<String,Object>>> call(String pa,Map<String,?> filter,Object body,
            JwtAuthenticationToken a,HttpServletRequest r) {
        PersistenceResult<Map<String,Object>> x=sql.execute(pa,filter,body,identities.resolve(a),metadata.resolve(r));
        AppStatus status=AppStatus.fromHttp(x.httpSugerido(),x.exitoso()?AppStatus.OK:AppStatus.BAD_REQUEST);
        return responses.from(new AppResult<>(x.exitoso(),x.codigo(),x.mensaje(),x.datos(),status),r);
    }
    @GetMapping("/campanias/sanciones/catalogo")
    @Operation(operationId="sancionesCatalogoListar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> catalog(@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_SancionCatalogo_Sel_Listado",Map.of(),null,a,r);
    }
    @PostMapping("/campanias/sanciones/catalogo") @IdempotentOperation
    @Operation(operationId="sancionesCatalogoCrear")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_CREAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> catalogCreate(@Valid @RequestBody CatalogCreate body,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_SancionCatalogo_Ins_Registro",Map.of(),body,a,r);
    }
    @PutMapping("/campanias/sanciones/catalogo/{id}") @IdempotentOperation
    @Operation(operationId="sancionesCatalogoEditar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_EDITAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> catalogEdit(@PathVariable @Positive Long id,@Valid @RequestBody CatalogUpdate body,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_SancionCatalogo_Upd_Registro",Map.of("id",id),body,a,r);
    }
    @PostMapping("/campanias/sanciones/catalogo/{id}/deshabilitar") @IdempotentOperation
    @Operation(operationId="sancionesCatalogoDeshabilitar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_RETIRAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> catalogDisable(@PathVariable @Positive Long id,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_SancionCatalogo_Upd_Deshabilitar",Map.of("id",id),Map.of(),a,r);
    }
    @GetMapping("/campanias/{campaniaId}/sanciones")
    @Operation(operationId="campaniaSancionesListar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> rates(@PathVariable @Positive Long campaniaId,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_CampaniaSancion_Sel_Listado",Map.of("campaniaId",campaniaId),null,a,r);
    }
    @PutMapping("/campanias/{campaniaId}/sanciones") @IdempotentOperation
    @Operation(operationId="campaniaSancionesConfigurar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_CONFIGURAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> rateSave(@PathVariable @Positive Long campaniaId,@Valid @RequestBody Tariff body,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_CampaniaSancion_Upd_Configurar",Map.of("campaniaId",campaniaId),body,a,r);
    }
    @PutMapping("/campanias/{campaniaId}/sanciones/lote") @IdempotentOperation
    @Operation(operationId="campaniaSancionesConfigurarLote")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_CONFIGURAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> rateBatch(@PathVariable @Positive Long campaniaId,
        @Valid @RequestBody TariffBatch body, @Parameter(hidden=true) JwtAuthenticationToken a,
        @Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_CampaniaSancion_Upd_Lote", Map.of("campaniaId",campaniaId), body, a, r);
    }
    @PostMapping("/campanias/{campaniaId}/sanciones/{tarifaId}/deshabilitar") @IdempotentOperation
    @Operation(operationId="campaniaSancionesDeshabilitar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_CONFIGURAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> rateDisable(@PathVariable @Positive Long campaniaId,@PathVariable @Positive Long tarifaId,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_CampaniaSancion_Upd_Deshabilitar",Map.of("campaniaId",campaniaId,"tarifaId",tarifaId),Map.of(),a,r);
    }
    @GetMapping("/campanias/{campaniaId}/sanciones/socios/{participacionId}")
    @Operation(operationId="campaniaSocioSancionVer")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> partner(@PathVariable @Positive Long campaniaId,@PathVariable @Positive Long participacionId,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_CampaniaSocioSancion_Sel_Detalle",Map.of("campaniaId",campaniaId,"participacionId",participacionId),null,a,r);
    }
    @PutMapping("/campanias/{campaniaId}/sanciones/socios/{participacionId}") @IdempotentOperation
    @Operation(operationId="campaniaSocioSancionAsignar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_APLICAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> assign(@PathVariable @Positive Long campaniaId,@PathVariable @Positive Long participacionId,@Valid @RequestBody Assignment body,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_CampaniaSocioSancion_Upd_Asignar",Map.of("campaniaId",campaniaId,"participacionId",participacionId),body,a,r);
    }
    @PostMapping("/campanias/{campaniaId}/sanciones/socios/{participacionId}/retirar") @IdempotentOperation
    @Operation(operationId="campaniaSocioSancionRetirar")
    @PreAuthorize("@permissionGuard.has(authentication,'SANCIONES_APLICAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> unassign(@PathVariable @Positive Long campaniaId,@PathVariable @Positive Long participacionId,@Valid @RequestBody Reason body,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return call("PA_CampaniaSocioSancion_Upd_Retirar",Map.of("campaniaId",campaniaId,"participacionId",participacionId),body,a,r);
    }
}
