package com.franco.desco.adapter.in.web.e5;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.e5.E5Commands;
import com.franco.desco.application.e5.port.in.E5UseCase;
import io.swagger.v3.oas.annotations.*;
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
@RequestMapping("/api/v1/apappss/finanzas-e5")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Tag(name="Finanzas APAPPSS E5",description="Repartos, liquidaciones oficiales, pagos y cierre de campaña")
@Validated
public class E5Controller {
    private final E5UseCase service;
    private final ApiResponseFactory response;
    private final JwtSessionIdentityResolver identity;
    private final ClientRequestContextResolver metadata;
    public E5Controller(E5UseCase service,ApiResponseFactory response,
        JwtSessionIdentityResolver identity,ClientRequestContextResolver metadata) {
        this.service=service;this.response=response;this.identity=identity;this.metadata=metadata;
    }
    private <T> ResponseEntity<ApiResponse<T>> run(String accion,Long camp,Long gasto,Long part,
        Long liq,Long pago,Object datos,Class<T> type,JwtAuthenticationToken auth,HttpServletRequest req) {
        return response.from(service.execute(new E5Commands.Execute(accion,camp,gasto,part,liq,pago,datos),
           identity.resolve(auth),metadata.resolve(req),type),req,v->v);
    }
    @GetMapping("/campanias/{campaniaId}/tablero")
    @Operation(operationId="apappssE5Tablero",summary="Balance de campaña con ventas, jabas, liquidaciones y pagos")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_LISTAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Tablero>> tablero(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("TABLERO",campaniaId,null,null,null,null,null,E5WebTypes.Tablero.class,a,r);
    }
    @GetMapping("/campanias/{campaniaId}/gastos")
    @Operation(operationId="apappssE5Gastos",summary="Gastos existentes y prorrateos asociados")
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_LISTAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Gastos>> gastos(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("GASTOS",campaniaId,null,null,null,null,null,E5WebTypes.Gastos.class,a,r);
    }
    @GetMapping("/gastos/{gastoId}/repartos")
    @Operation(operationId="apappssE5Repartos",summary="Historial de versiones de prorrateo")
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_VER')")
    public ResponseEntity<ApiResponse<E5WebTypes.Repartos>> repartos(@PathVariable @Positive Long gastoId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("REPARTO",null,gastoId,null,null,null,null,E5WebTypes.Repartos.class,a,r);
    }
    @PostMapping("/gastos/{gastoId}/repartir") @IdempotentOperation
    @Operation(operationId="apappssE5Repartir",summary="Proponer reparto equitativo entre vendedores confirmados")
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_CREAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Reparto>> repartir(@PathVariable @Positive Long gastoId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("REPARTIR",null,gastoId,null,null,null,null,E5WebTypes.Reparto.class,a,r);
    }
    @PostMapping("/gastos/{gastoId}/repartos/aprobar") @IdempotentOperation
    @Operation(operationId="apappssE5AprobarReparto",summary="Congelar y aprobar el reparto del gasto")
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_APROBAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Reparto>> aprobarReparto(@PathVariable @Positive Long gastoId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("APROBAR_REPARTO",null,gastoId,null,null,null,null,E5WebTypes.Reparto.class,a,r);
    }
    @PostMapping("/gastos/{gastoId}/repartos/rectificar") @IdempotentOperation
    @Operation(operationId="apappssE5RectificarReparto",summary="Rectificar con autorización preservando historial")
    @PreAuthorize("@permissionGuard.has(authentication,'GASTOS_APROBAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Reparto>> rectificarReparto(@PathVariable @Positive Long gastoId,
      @Valid @RequestBody E5WebTypes.Observacion q,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r) {
        return run("RECTIFICAR_REPARTO",null,gastoId,null,null,null,q,E5WebTypes.Reparto.class,a,r);
    }
    @GetMapping("/campanias/{campaniaId}/liquidaciones")
    @Operation(operationId="apappssE5Liquidaciones",summary="Versiones de liquidación por campaña")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_LISTAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidaciones>> liquidaciones(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("LIQUIDACIONES",campaniaId,null,null,null,null,null,E5WebTypes.Liquidaciones.class,a,r);
    }
    @PostMapping("/participaciones/{participacionId}/liquidar") @IdempotentOperation
    @Operation(operationId="apappssE5Liquidar",summary="Crear versión exacta con snapshot de fuentes confirmadas")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_CREAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidacion>> liquidar(@PathVariable @Positive Long participacionId,
      @RequestBody(required=false) E5WebTypes.Rectificacion q,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r) {
        return run("LIQUIDAR",null,null,participacionId,null,null,q,E5WebTypes.Liquidacion.class,a,r);
    }
    @GetMapping("/liquidaciones/{liquidacionId}")
    @Operation(operationId="apappssE5Liquidacion",summary="Desglose histórico, pagos y saldo de liquidación")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_VER')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidacion>> liquidacion(@PathVariable @Positive Long liquidacionId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("LIQUIDACION",null,null,null,liquidacionId,null,null,E5WebTypes.Liquidacion.class,a,r);
    }
    @PostMapping("/liquidaciones/{liquidacionId}/aprobar") @IdempotentOperation
    @Operation(operationId="apappssE5AprobarLiquidacion",summary="Aprobar versión si fuentes no cambiaron")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_APROBAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidacion>> aprobar(@PathVariable @Positive Long liquidacionId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("APROBAR",null,null,null,liquidacionId,null,null,E5WebTypes.Liquidacion.class,a,r);
    }
    @PostMapping("/liquidaciones/{liquidacionId}/observar") @IdempotentOperation
    @Operation(operationId="apappssE5ObservarLiquidacion",summary="Observar versión pendiente con motivo")
    @PreAuthorize("@permissionGuard.has(authentication,'LIQUIDACIONES_EDITAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidacion>> observar(@PathVariable @Positive Long liquidacionId,
      @Valid @RequestBody E5WebTypes.Observacion q,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r) {
        return run("OBSERVAR",null,null,null,liquidacionId,null,q,E5WebTypes.Liquidacion.class,a,r);
    }
    @PostMapping("/liquidaciones/{liquidacionId}/pagar") @IdempotentOperation
    @Operation(operationId="apappssE5Pagar",summary="Pago total o parcial de saldo congelado, con concurrencia e idempotencia")
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidacion>> pagar(@PathVariable @Positive Long liquidacionId,
      @Valid @RequestBody E5WebTypes.Pago q,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r) {
        return run("PAGAR",null,null,null,liquidacionId,null,q,E5WebTypes.Liquidacion.class,a,r);
    }
    @PostMapping("/pagos/{pagoId}/reversar") @IdempotentOperation
    @Operation(operationId="apappssE5ReversarPago",summary="Reversión auditada, sin borrar el pago")
    @PreAuthorize("@permissionGuard.has(authentication,'PAGOS_RETIRAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Liquidacion>> reversar(@PathVariable @Positive Long pagoId,
      @Valid @RequestBody E5WebTypes.Observacion q,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r) {
        return run("REVERSAR",null,null,null,null,pagoId,q,E5WebTypes.Liquidacion.class,a,r);
    }
    @GetMapping("/campanias/{campaniaId}/reporte")
    @Operation(operationId="apappssE5Reporte",summary="Reporte oficial por socio y variedad")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_VER')")
    public ResponseEntity<ApiResponse<E5WebTypes.Tablero>> reporte(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("REPORTE",campaniaId,null,null,null,null,null,E5WebTypes.Tablero.class,a,r);
    }
    @GetMapping("/campanias/{campaniaId}/exportacion")
    @Operation(operationId="apappssE5Exportar",summary="Datos financieros autorizados para exportación")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_EXPORTAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Tablero>> exportar(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("EXPORTAR",campaniaId,null,null,null,null,null,E5WebTypes.Tablero.class,a,r);
    }
    @GetMapping("/campanias/{campaniaId}/cobros")
    @Operation(operationId="apappssE5Cobros",summary="Cobros efectivamente confirmados, separados de ventas")
    @PreAuthorize("@permissionGuard.has(authentication,'COBROS_VER')")
    public ResponseEntity<ApiResponse<E5WebTypes.Cobros>> cobros(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("COBROS",campaniaId,null,null,null,null,null,E5WebTypes.Cobros.class,a,r);
    }
    @GetMapping("/campanias/{campaniaId}/cierre")
    @Operation(operationId="apappssE5ValidarCierre",summary="Diferencias que bloquean el cierre")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_VER')")
    public ResponseEntity<ApiResponse<E5WebTypes.ValidacionCierre>> validarCierre(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return run("CIERRE_VALIDAR",campaniaId,null,null,null,null,null,E5WebTypes.ValidacionCierre.class,a,r);
    }
    @PostMapping("/campanias/{campaniaId}/cerrar") @IdempotentOperation
    @Operation(operationId="apappssE5Cerrar",summary="Cierre auditado con balance congelado o excepción autorizada")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_ADMINISTRAR')")
    public ResponseEntity<ApiResponse<E5WebTypes.Cierre>> cerrar(@PathVariable @Positive Long campaniaId,
      @Valid @RequestBody E5WebTypes.CierreRequest q,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r) {
        return run("CERRAR",campaniaId,null,null,null,null,q,E5WebTypes.Cierre.class,a,r);
    }
}
