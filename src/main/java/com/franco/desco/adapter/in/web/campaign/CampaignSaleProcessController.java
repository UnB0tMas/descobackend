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
import java.util.List;
import java.util.Map;

/** La recepción de jabas NO liquida ni registra pagos; cada operación delega a su propio PA. */
@RestController
@RequestMapping("/api/v1/campanias/{campaniaId}/venta")
@Tag(name="Proceso de venta APAPPSS", description="Pesajes por jaba, calibres y peso neto de cada participante")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class CampaignSaleProcessController {
    private final CampaignPlanningSqlAdapter sql;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;

    public CampaignSaleProcessController(CampaignPlanningSqlAdapter sql, ApiResponseFactory responses,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata) {
        this.sql=sql;
        this.responses=responses;
        this.identities=identities;
        this.metadata=metadata;
    }

    public record JabaInput(@NotNull @DecimalMin("0") @Digits(integer=6,fraction=3) BigDecimal pesoBrutoKg,
                            @Positive Long calibreId, @Positive Integer version,
                            @Size(max=400) String observacion) {}
    public record CorrectionInput(@NotNull @DecimalMin("0") @Digits(integer=6,fraction=3) BigDecimal pesoBrutoKg,
                                  @Positive Long calibreId, @NotNull @Positive Integer version,
                                  @NotBlank @Size(min=10,max=500) String motivo,
                                  @Size(max=400) String observacion) {}
    public record GradeInput(@NotNull @Positive Integer variedadPaltaId,
            @NotBlank @Pattern(regexp="PRIMERA|SEGUNDA|DESCARTE") String calibre,
            @NotNull @Min(0) Integer gramosDesde, @Min(0) Integer gramosHasta,
            @NotNull @DecimalMin("0.0001") BigDecimal precioKg) {
        @AssertTrue(message="El rango de calibre es inválido")
        public boolean isRangoValido() { return gramosDesde!=null && (gramosHasta==null || gramosHasta>=gramosDesde); }
    }
    public record GradeListItem(@Positive Long calibreId, @Positive Integer version,
            @NotNull @Positive Integer variedadPaltaId,
            @NotBlank @Pattern(regexp="PRIMERA|SEGUNDA|DESCARTE") String calibre,
            @NotNull @Min(0) Integer gramosDesde, @Min(0) Integer gramosHasta,
            @NotNull @DecimalMin("0.0001") BigDecimal precioKg) {
        @AssertTrue(message="Revise el rango del calibre")
        public boolean isRangoValido() { return gramosHasta==null || gramosDesde!=null && gramosHasta>=gramosDesde; }
    }
    public record GradesListInput(@NotEmpty @Size(max=20) List<@Valid GradeListItem> calibres) {}
    public record PriceInput(@NotNull @DecimalMin("0.0001") BigDecimal precioKg,
                             @NotNull @Positive Integer version) {}
    public record DiscountInput(@DecimalMin("0") @DecimalMax("9.999") BigDecimal descuentoJabaKg) {}

    private ResponseEntity<ApiResponse<Map<String,Object>>> call(String procedure, Map<String,?> filters,
            Object data, JwtAuthenticationToken auth, HttpServletRequest request) {
        PersistenceResult<Map<String,Object>> outcome=sql.execute(procedure,filters,data,
                identities.resolve(auth),metadata.resolve(request));
        AppStatus status=AppStatus.fromHttp(outcome.httpSugerido(),
                outcome.exitoso()?AppStatus.OK:AppStatus.BAD_REQUEST);
        return responses.from(new AppResult<>(outcome.exitoso(),outcome.codigo(),outcome.mensaje(),outcome.datos(),status),request);
    }

    @GetMapping
    @Operation(operationId="campaniaVentaProcesoVer",summary="Consultar campaña, calibres y pesos de socios")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_VER') && @permissionGuard.has(authentication,'JABAS_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> detail(@PathVariable @Positive Long campaniaId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaVentaProceso_Sel_Detalle",Map.of("campaniaId",campaniaId),null,auth,request);
    }

    @GetMapping("/indicadores")
    @Operation(operationId="campaniaVentaIndicadores",summary="Indicadores de recepción por fecha y variedad")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_VER') && @permissionGuard.has(authentication,'JABAS_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> indicators(@PathVariable @Positive Long campaniaId,
            @RequestParam @NotNull java.time.LocalDate fechaInicio,
            @RequestParam @NotNull java.time.LocalDate fechaFin,
            @RequestParam(required=false) @Positive Integer variedadPaltaId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> filters=new java.util.LinkedHashMap<>();
        filters.put("campaniaId",campaniaId);
        filters.put("fechaInicio",fechaInicio.toString());
        filters.put("fechaFin",fechaFin.toString());
        if (variedadPaltaId!=null) filters.put("variedadPaltaId",variedadPaltaId);
        return call("PA_CampaniaVentaProceso_Sel_Indicadores",filters,null,auth,request);
    }

    @GetMapping("/socios/{participacionId}/jabas")
    @Operation(operationId="campaniaVentaProcesoJabas",summary="Consultar página de pesajes del socio")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_LISTAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> jabas(@PathVariable @Positive Long campaniaId,
            @PathVariable @Positive Long participacionId,
            @RequestParam(defaultValue="1") @Min(1) Integer pagina,
            @RequestParam(defaultValue="25") @Min(1) @Max(100) Integer tamano,
            @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaRecepcion_Sel_Pagina",
                Map.of("campaniaId",campaniaId,"participacionId",participacionId,"pagina",pagina,"tamano",tamano),null,auth,request);
    }

    @PutMapping("/socios/{participacionId}/jabas/{numero}") @IdempotentOperation
    @Operation(operationId="campaniaVentaProcesoRegistrarJaba",summary="Registrar o corregir el peso de una jaba")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> weigh(@PathVariable @Positive Long campaniaId,
            @PathVariable @Positive Long participacionId,@PathVariable @Positive Integer numero,
            @Valid @RequestBody JabaInput body,@Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaRecepcion_Upd_Registro",
                Map.of("campaniaId",campaniaId,"participacionId",participacionId,"numero",numero),body,auth,request);
    }

    @PutMapping("/socios/{participacionId}/jabas/{numero}/corregir") @IdempotentOperation
    @Operation(operationId="campaniaVentaProcesoCorregirJaba",summary="Corregir un pesaje con motivo obligatorio")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> correct(@PathVariable @Positive Long campaniaId,
            @PathVariable @Positive Long participacionId,@PathVariable @Positive Integer numero,
            @Valid @RequestBody CorrectionInput body,@Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaRecepcion_Upd_Corregir",
                Map.of("campaniaId",campaniaId,"participacionId",participacionId,"numero",numero),body,auth,request);
    }

    @PostMapping("/socios/{participacionId}/confirmar-entrega") @IdempotentOperation
    @Operation(operationId="campaniaVentaProcesoConfirmarEntrega",summary="Confirmar la entrega final con todas las jabas pesadas")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> confirmDelivery(@PathVariable @Positive Long campaniaId,
            @PathVariable @Positive Long participacionId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaJabaRecepcion_Upd_Confirmar",
                Map.of("campaniaId",campaniaId,"participacionId",participacionId),Map.of(),auth,request);
    }

    @PostMapping("/calibres") @IdempotentOperation
    @Operation(operationId="campaniaVentaProcesoAgregarCalibre",summary="Registrar calibre y precio en la campaña")
    @PreAuthorize("@permissionGuard.has(authentication,'PRECIOS_CREAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> grade(@PathVariable @Positive Long campaniaId,
            @Valid @RequestBody GradeInput body,@Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaCalibre_Ins_Registro",Map.of("campaniaId",campaniaId),body,auth,request);
    }

    @PutMapping("/calibres/configurar") @IdempotentOperation
    @Operation(operationId="campaniaVentaProcesoConfigurarCalibres",summary="Actualizar los calibres de la campaña")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_EDITAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> configureGrades(@PathVariable @Positive Long campaniaId,
            @Valid @RequestBody GradesListInput body,@Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaCalibre_Upd_Lista",Map.of("campaniaId",campaniaId),body,auth,request);
    }

    @PutMapping("/calibres/{calibreId}/precio") @IdempotentOperation
    @Operation(operationId="campaniaVentaProcesoVersionarPrecio",summary="Registrar versión del precio por calibre")
    @PreAuthorize("@permissionGuard.has(authentication,'PRECIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> price(@PathVariable @Positive Long campaniaId,
            @PathVariable @Positive Long calibreId,@Valid @RequestBody PriceInput body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaCalibre_Upd_Precio",Map.of("campaniaId",campaniaId,"calibreId",calibreId),body,auth,request);
    }

    @PutMapping("/descuento-jaba") @IdempotentOperation
    @Operation(operationId="campaniaVentaProcesoDescuento",summary="Configurar descuento por jaba antes del primer pesaje")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_EDITAR')")
    public ResponseEntity<ApiResponse<Map<String,Object>>> discount(@PathVariable @Positive Long campaniaId,
            @Valid @RequestBody DiscountInput body,@Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return call("PA_CampaniaDescuentoJaba_Upd_Configurar",Map.of("campaniaId",campaniaId),body,auth,request);
    }
}
