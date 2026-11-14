
package com.franco.desco.adapter.in.web.e5;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.adapter.out.persistence.e5.E5ExtrasSqlServerAdapter;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.PersistenceResult;
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

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/apappss/finanzas-e5")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Tag(name="Finanzas APAPPSS E5",description="Gráficos filtrados y beneficiarios de pagos auditados")
@Validated
public class E5ExtrasController {
    private final E5ExtrasSqlServerAdapter sql;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identity;
    private final ClientRequestContextResolver metadata;
    public E5ExtrasController(E5ExtrasSqlServerAdapter sql,ApiResponseFactory responses,
        JwtSessionIdentityResolver identity,ClientRequestContextResolver metadata) {
        this.sql=sql;this.responses=responses;this.identity=identity;this.metadata=metadata;
    }

    private <T> ResponseEntity<ApiResponse<T>> fromPersistence(PersistenceResult<T> result,
        HttpServletRequest request) {
        return responses.from(ApplicationResults.ok(result,"E5_OK","E5_ERROR",AppStatus.BAD_REQUEST),request);
    }

    @GetMapping("/campanias/{campaniaId}/graficos")
    @Operation(operationId="apappssE5Graficos",summary="Series temporales y por variedad con segmentadores aplicados en SQL")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_LISTAR')")
    public ResponseEntity<ApiResponse<E5ExtrasWebTypes.Graficos>> graficos(@PathVariable @Positive Long campaniaId,
        @RequestParam(required=false) String fechaInicio,@RequestParam(required=false) String fechaFin,
        @RequestParam(required=false) Short variedadPaltaId,
        @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        Map<String,Object> d=new LinkedHashMap<>();
        d.put("fechaInicio",fechaInicio);d.put("fechaFin",fechaFin);d.put("variedadPaltaId",variedadPaltaId);
        return fromPersistence(sql.execute("GRAFICOS",campaniaId,null,d,identity.resolve(a),metadata.resolve(r),
            E5ExtrasWebTypes.Graficos.class),r);
    }

    @GetMapping("/participaciones/{participacionId}/entregas")
    @Operation(operationId="apappssE5EntregasSocio",summary="Entregas confirmadas, pesajes y precio aplicado por socio")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_LISTAR')")
    public ResponseEntity<ApiResponse<E5ExtrasWebTypes.EntregasSocio>> entregas(
        @PathVariable @Positive Long participacionId,
        @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return fromPersistence(sql.execute("ENTREGAS",null,null,Map.of("participacionId",participacionId),
            identity.resolve(a),metadata.resolve(r),E5ExtrasWebTypes.EntregasSocio.class),r);
    }

    @GetMapping("/campanias/{campaniaId}/cobros-detalle")
    @Operation(operationId="apappssE5CobrosDetalle",summary="Cobros individuales del comprador y sus medios de pago")
    @PreAuthorize("@permissionGuard.has(authentication,'COBROS_VER')")
    public ResponseEntity<ApiResponse<E5ExtrasWebTypes.CobrosDetalle>> cobrosDetalle(
        @PathVariable @Positive Long campaniaId,
        @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return fromPersistence(sql.execute("COBROS_DETALLE",campaniaId,null,Map.of(),
            identity.resolve(a),metadata.resolve(r),E5ExtrasWebTypes.CobrosDetalle.class),r);
    }

    @GetMapping("/liquidaciones/{liquidacionId}/beneficiario")
    @Operation(operationId="apappssE5Beneficiario",summary="Socio beneficiario registrado y auditoría de destinatarios")
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_LISTAR') and (@permissionGuard.has(authentication,'APAPPSS_PAGOS_VER') or @permissionGuard.has(authentication,'APAPPSS_PAGOS_PAGAR'))")
    public ResponseEntity<ApiResponse<E5ExtrasWebTypes.Beneficiario>> beneficiario(@PathVariable @Positive Long liquidacionId,
        @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return fromPersistence(sql.execute("BENEFICIARIO",null,liquidacionId,Map.of(),identity.resolve(a),metadata.resolve(r),
            E5ExtrasWebTypes.Beneficiario.class),r);
    }

    @PostMapping("/liquidaciones/{liquidacionId}/receptores") @IdempotentOperation
    @Operation(operationId="apappssE5AsegurarReceptor",summary="Reutilizar identidad local o registrar receptor manual sin crear socio")
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_CONFIRMAR') and @permissionGuard.has(authentication,'APAPPSS_PAGOS_PAGAR')")
    public ResponseEntity<ApiResponse<E5ExtrasWebTypes.ReceptorRegistrado>> asegurarReceptor(
        @PathVariable @Positive Long liquidacionId,@Valid @RequestBody E5ExtrasWebTypes.Receptor q,
        @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        Map<String,Object> d=new LinkedHashMap<>();
        d.put("tipoDocumento",q.tipoDocumento());d.put("numeroDocumento",q.numeroDocumento());
        d.put("nombres",q.nombres());d.put("apellidoPaterno",q.apellidoPaterno());
        d.put("apellidoMaterno",q.apellidoMaterno());d.put("telefono",q.telefono());
        d.put("correo",q.correo());d.put("fechaNacimiento",q.fechaNacimiento());
        d.put("sexo",q.sexo());d.put("identityId",q.identityId());
        return fromPersistence(sql.execute("RECEPTOR",null,liquidacionId,d,identity.resolve(a),metadata.resolve(r),
            E5ExtrasWebTypes.ReceptorRegistrado.class),r);
    }

    @PostMapping("/liquidaciones/{liquidacionId}/pagar-beneficiario") @IdempotentOperation
    @Operation(operationId="apappssE5PagarBeneficiario",summary="Pago verificado y beneficiario auditado en una transacción")
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_CONFIRMAR') and @permissionGuard.has(authentication,'APAPPSS_PAGOS_PAGAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidacion>> pagar(@PathVariable @Positive Long liquidacionId,
        @Valid @RequestBody E5ExtrasWebTypes.Pago q,
        @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        Map<String,Object> d=new LinkedHashMap<>();
        d.put("importe",q.importe());d.put("medioPago",q.medioPago());d.put("referencia",q.referencia());
        d.put("beneficiarioPersonaId",q.beneficiarioPersonaId());
        d.put("motivoEntrega",q.motivoEntrega());
        d.put("comprobanteArchivoId",q.comprobanteArchivoId());
        return fromPersistence(sql.execute("PAGAR",null,liquidacionId,d,identity.resolve(a),metadata.resolve(r),
            E5WebTypes.Liquidacion.class),r);
    }
}
