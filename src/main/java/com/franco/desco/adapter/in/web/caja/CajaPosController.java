package com.franco.desco.adapter.in.web.caja;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.caja.CajaPosService;
import com.franco.desco.application.caja.FiscalPdfService;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.dao.DataAccessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;

@RestController
@RequestMapping("/api/v1/cajas-pos")
@Tag(name="Cajas POS",description="Cajas, apertura, arqueo y comprobantes internos")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class CajaPosController {
    private static final Logger log=LoggerFactory.getLogger(CajaPosController.class);
    private final CajaPosService service;
    private final FiscalPdfService pdf;
    private final com.franco.desco.application.caja.CajaArqueoPdfService arqueoPdf;
    private final JwtSessionIdentityResolver identities;
    private final ApiResponseFactory responses;
    public CajaPosController(CajaPosService service, FiscalPdfService pdf,
            com.franco.desco.application.caja.CajaArqueoPdfService arqueoPdf,
            JwtSessionIdentityResolver identities,ApiResponseFactory responses) {
        this.service=service;this.pdf=pdf;this.arqueoPdf=arqueoPdf;
        this.identities=identities;this.responses=responses;
    }
    public record Crear(@NotNull @Positive Long uotId,@NotBlank @Size(min=3,max=120) String nombre) {}
    public record Editar(@NotNull @Positive Long uotId,@NotBlank @Size(min=3,max=120) String nombre) {}
    public record Retirar(@NotNull @Positive Long uotId) {}
    public record ObservacionVenta(@NotNull @Positive Long uotId,@NotBlank @Size(max=500) String observacion) {}
    public record Abrir(@NotNull @Positive Long uotId,@NotNull @Positive Long cajaId,
                        @NotNull @DecimalMin("0.00") BigDecimal saldoInicial,
                        @Size(max=500) String observacion,List<@Positive Long> archivos) {}
    public record Asignar(@NotNull @Positive Long uotId,@NotNull @Positive Long operadorId) {}
    public record Movimiento(@NotNull @Positive Long uotId,@NotBlank @Pattern(regexp="INGRESO|EGRESO") String tipo,
                             @NotNull @DecimalMin(value="0.00",inclusive=false) BigDecimal importe,
                             @NotBlank @Size(min=5,max=300) String motivo) {}
    public record Cerrar(@NotNull @Positive Long uotId,@NotNull @DecimalMin("0.00") BigDecimal saldoDeclarado,
                         @Size(max=500) String observacion,List<@Positive Long> archivos) {}

    private long user(JwtAuthenticationToken a) { return identities.resolve(a).usuarioId(); }
    private <T> ResponseEntity<ApiResponse<T>> reply(Supplier<T> action,HttpServletRequest r,boolean created) {
        try {
            T value=action.get();
            return responses.from(created?AppResult.created("CAJA_OK","Operación registrada.",value)
                    :AppResult.ok("CAJA_OK","Consulta correcta.",value),r);
        } catch(CajaPosService.Regla e) {
            return responses.from(AppResult.<T>error(AppStatus.CONFLICT,"CAJA_REGLA",e.getMessage()),r);
        } catch(DataAccessException e) {
            log.error("Fallo SQL en gestión de caja; consulta el correlacionId de la respuesta",e);
            return responses.from(AppResult.<T>error(AppStatus.SERVICE_UNAVAILABLE,"CAJA_BD",
                    "No se completó la operación de caja. Revise su estado actual."),r);
        }
    }
    @GetMapping
    @Operation(operationId="cajasPosListar")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_LISTAR')")
    public ResponseEntity<ApiResponse<List<CajaPosService.Caja>>> cajas(@RequestParam @Positive Long uotId,
            @RequestParam(defaultValue="false") boolean incluirInactivas,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.cajas(user(authentication),uotId,incluirInactivas),request,false);
    }
    @PatchMapping("/ventas/{id}/observacion")
    @IdempotentOperation
    @Operation(operationId="cajasPosEditarObservacionVenta")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'VENTAS_EDITAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> editarObservacionVenta(
            @PathVariable @Positive Long id,@Valid @RequestBody ObservacionVenta body,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.editarObservacionVenta(user(authentication),body.uotId(),id,body.observacion()),request,false);
    }
    @GetMapping("/disponibles")
    @Operation(operationId="cajasPosDisponibles",summary="Cajas que pueden abrirse")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_ABRIR')")
    public ResponseEntity<ApiResponse<List<CajaPosService.CajaDisponible>>> disponibles(
            @RequestParam @Positive Long uotId,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.disponibles(user(authentication),uotId),request,false);
    }
    @GetMapping("/operadores")
    @Operation(operationId="cajasPosOperadores",summary="Operadores habilitados en la UOT")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_LISTAR')")
    public ResponseEntity<ApiResponse<List<CajaPosService.Operador>>> operadores(@RequestParam @Positive Long uotId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.operadores(user(authentication),uotId),request,false);
    }
    @GetMapping("/sesiones")
    @Operation(operationId="cajasPosSesiones")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_LISTAR')")
    public ResponseEntity<ApiResponse<List<CajaPosService.Sesion>>> sesiones(@RequestParam @Positive Long uotId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.sesiones(user(authentication),uotId),request,false);
    }
    @GetMapping("/activa")
    @Operation(operationId="cajasPosActiva")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'POS_OPERAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Sesion>> activa(@RequestParam @Positive Long uotId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.activa(user(authentication),uotId),request,false);
    }
    @PostMapping
    @IdempotentOperation
    @Operation(operationId="cajasPosCrear")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'CAJAS_CREAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> crear(@Valid @RequestBody Crear body,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.crear(user(authentication),body.uotId(),body.nombre()),request,true);
    }
    @PutMapping("/{id}")
    @IdempotentOperation
    @Operation(operationId="cajasPosEditar")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'CAJAS_EDITAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> editar(@PathVariable @Positive Long id,
            @Valid @RequestBody Editar body,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.editar(user(authentication),body.uotId(),id,body.nombre()),request,false);
    }
    @DeleteMapping("/{id}")
    @Operation(operationId="cajasPosRetirar",summary="Deshabilitar sin borrar su historial")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_RETIRAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> retirar(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.retirar(user(authentication),uotId,id),request,false);
    }
    @GetMapping("/{id}")
    @Operation(operationId="cajasPosDetalle",summary="Historial de turnos, movimientos y operadores de una caja")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_SUPERVISAR')")
    public ResponseEntity<ApiResponse<CajaPosService.CajaDetalle>> detalle(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.detalle(user(authentication),uotId,id),request,false);
    }
    @PostMapping("/abrir")
    @IdempotentOperation
    @Operation(operationId="cajasPosAbrir")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'CAJAS_ABRIR')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> abrir(@Valid @RequestBody Abrir body,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.abrir(user(authentication),body.uotId(),body.cajaId(),
               body.saldoInicial(),body.observacion(),body.archivos()),request,true);
    }
    @PostMapping("/sesiones/{id}/asignar")
    @IdempotentOperation
    @Operation(operationId="cajasPosAsignar")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'CAJAS_ASIGNAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> asignar(@PathVariable @Positive Long id,
            @Valid @RequestBody Asignar body,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.asignar(user(authentication),body.uotId(),id,body.operadorId()),request,true);
    }
    @GetMapping("/sesiones/{id}/operadores")
    @Operation(operationId="cajasPosAsignados")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_LISTAR')")
    public ResponseEntity<ApiResponse<List<CajaPosService.Operador>>> asignados(
            @PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.asignados(user(authentication),uotId,id),request,false);
    }
    @DeleteMapping("/sesiones/{id}/operadores/{operadorId}")
    @IdempotentOperation
    @Operation(operationId="cajasPosQuitarOperador")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_ASIGNAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> quitarOperador(
            @PathVariable @Positive Long id,@PathVariable @Positive Long operadorId,
            @RequestParam @Positive Long uotId,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.quitar(user(authentication),uotId,id,operadorId),request,false);
    }
    @PostMapping("/sesiones/{id}/movimientos")
    @IdempotentOperation
    @Operation(operationId="cajasPosMovimiento")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'CAJAS_MOVIMIENTOS')")
    public ResponseEntity<ApiResponse<CajaPosService.Resultado>> movimiento(@PathVariable @Positive Long id,
            @Valid @RequestBody Movimiento body,
            @RequestHeader("X-Idempotency-Key") UUID key,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.movimiento(user(authentication),body.uotId(),id,body.tipo(),body.importe(),body.motivo(),key),request,true);
    }
    @GetMapping("/sesiones/{id}/arqueo")
    @Operation(operationId="cajasPosArqueo",summary="Balance y ventas de una sola sesión")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_CERRAR') || @permissionGuard.hasUot(authentication,#uotId,'CAJAS_SUPERVISAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Arqueo>> arqueo(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId, JwtAuthenticationToken authentication, HttpServletRequest request) {
        return reply(() -> service.arqueo(user(authentication), uotId, id), request, false);
    }

    @GetMapping(value="/sesiones/{id}/arqueo.pdf",produces="application/pdf")
    @Operation(operationId="cajasPosArqueoPdf")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'CAJAS_CERRAR') || @permissionGuard.hasUot(authentication,#uotId,'CAJAS_SUPERVISAR')")
    public ResponseEntity<byte[]> arqueoPdf(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId, JwtAuthenticationToken authentication) {
        try {
            var arqueo = service.arqueo(user(authentication), uotId, id);
            if (!"CERRADA".equals(arqueo.estado())) {
                return ResponseEntity.status(409).build();
            }
            return ResponseEntity.ok().contentType(MediaType.APPLICATION_PDF)
                    .header("Content-Disposition", "attachment; filename=cierre-caja-" + id + ".pdf")
                    .body(arqueoPdf.generar(arqueo));
        } catch (CajaPosService.Regla ex) {
            return ResponseEntity.status(403).build();
        }
    }

    @PostMapping("/sesiones/{id}/cerrar")
    @IdempotentOperation
    @Operation(operationId="cajasPosCerrar")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'CAJAS_CERRAR')")
    public ResponseEntity<ApiResponse<CajaPosService.Cierre>> cerrar(@PathVariable @Positive Long id,
            @Valid @RequestBody Cerrar body,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.cerrar(user(authentication),body.uotId(),id,body.saldoDeclarado(),body.observacion(),body.archivos()),request,true);
    }
    @GetMapping("/reportes")
    @Operation(operationId="cajasPosReporte")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'VENTAS_REPORTES')")
    public ResponseEntity<ApiResponse<List<CajaPosService.Reporte>>> reporte(@RequestParam @Positive Long uotId,
         @RequestParam(defaultValue="DIA") String agrupacion,@RequestParam String desde,@RequestParam String hasta,
         JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.reporte(user(authentication),uotId,agrupacion,desde,hasta),request,false);
    }
    @GetMapping(value="/ventas/{id}/comprobante.pdf", produces="application/pdf")
    @Operation(operationId="cajasPosComprobantePdf", summary="Descargar PDF A4 del comprobante")
    @PreAuthorize("@permissionGuard.has(authentication,'POS_OPERAR') || @permissionGuard.has(authentication,'COMPROBANTES_VER')")
    public ResponseEntity<byte[]> comprobantePdf(@PathVariable @Positive Long id,
            JwtAuthenticationToken authentication) {
        // La consulta de negocio comprueba la UOT y que sea venta propia o autorizada.
        var comprobante = service.comprobante(user(authentication), id);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header("Content-Disposition", "attachment; filename=venta-"+id+".pdf")
                .body(pdf.generar(comprobante));
    }

    @GetMapping("/ventas/{id}/comprobante-interno")
    @Operation(operationId="cajasPosComprobanteInterno",summary="Consultar los datos del comprobante comercial")
    @PreAuthorize("@permissionGuard.has(authentication,'POS_OPERAR') || @permissionGuard.has(authentication,'COMPROBANTES_VER')")
    public ResponseEntity<ApiResponse<CajaPosService.Comprobante>> comprobante(@PathVariable @Positive Long id,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return reply(()->service.comprobante(user(authentication),id),request,false);
    }
}
