package com.franco.desco.adapter.in.web.e4;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.e4.E4Commands.Execute;
import com.franco.desco.application.e4.port.in.E4UseCase;
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
@RequestMapping("/api/v1/apappss/acopio-e4")
@Tag(name="Acopio APAPPSS E4", description="Campaña, control unitario de jabas, balanza, retorno y prebalance")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public final class E4Controller {
    private final E4UseCase useCase;
    private final ApiResponseFactory response;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    public E4Controller(E4UseCase useCase,ApiResponseFactory response,
                        JwtSessionIdentityResolver identities,ClientRequestContextResolver metadata) {
        this.useCase=useCase;this.response=response;this.identities=identities;this.metadata=metadata;
    }
    private <T> ResponseEntity<ApiResponse<T>> doAction(String action,Long campaign,Long operatorSocio,
       Long assignment,Long unit,Long delivery,Object data,Class<T> type,JwtAuthenticationToken auth,HttpServletRequest req) {
        return response.from(useCase.execute(new Execute(action,campaign,operatorSocio,assignment,unit,delivery,data),
            identities.resolve(auth),metadata.resolve(req),type),req, item -> item);
    }
    @GetMapping("/campanias/{campaniaId}")
    @Operation(operationId="apappssE4Resumen",summary="Consultar cupo, tara y precios versionados de la campaña")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_VER')")
    public ResponseEntity<ApiResponse<E4WebTypes.Resumen>> resumen(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest req) {
        return doAction("RESUMEN",campaniaId,null,null,null,null,null,E4WebTypes.Resumen.class,auth,req);
    }
    @GetMapping("/campanias/{campaniaId}/socios-elegibles")
    @Operation(operationId="apappssE4SociosElegibles", summary="Socios activos disponibles en la campaña APAPPSS")
    @PreAuthorize("@permissionGuard.has(authentication,'PARTICIPANTES_LISTAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.SociosElegibles>> sociosElegibles(
            @PathVariable @Positive Long campaniaId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("SOCIOS", campaniaId, null, null, null, null, null,
                E4WebTypes.SociosElegibles.class, auth, req);
    }

    @PostMapping("/campanias/{campaniaId}/socios") @IdempotentOperation
    @Operation(operationId="apappssE4IncluirSocios", summary="Incluir varios socios elegibles en una sola transacción")
    @PreAuthorize("@permissionGuard.has(authentication,'PARTICIPANTES_CREAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.IncorporacionResultado>> incluirSocios(
            @PathVariable @Positive Long campaniaId,
            @Valid @RequestBody E4WebTypes.Incorporacion body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("INCLUIR_SOCIOS", campaniaId, null, null, null, null, body,
                E4WebTypes.IncorporacionResultado.class, auth, req);
    }

    @PutMapping("/campanias/{campaniaId}/configuracion") @IdempotentOperation
    @Operation(operationId="apappssE4Configurar",summary="Fijar cupo físico y tara para nuevos pesajes")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_EDITAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.ConfiguracionResultado>> configurar(@PathVariable @Positive Long campaniaId,
      @Valid @RequestBody E4WebTypes.Configuracion body,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("CONFIGURAR",campaniaId,null,null,null,null,body,E4WebTypes.ConfiguracionResultado.class,auth,req);
    }
    @PostMapping("/socios-operativo/{operativoSocioId}/jabas") @IdempotentOperation
    @Operation(operationId="apappssE4Asignar",summary="Asignar y crear N registros individuales de jabas")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.AsignacionResultado>> asignar(@PathVariable @Positive Long operativoSocioId,
      @Valid @RequestBody E4WebTypes.Asignacion body,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("ASIGNAR",null,operativoSocioId,null,null,null,body,E4WebTypes.AsignacionResultado.class,auth,req);
    }
    @GetMapping("/asignaciones/{asignacionId}/unidades")
    @Operation(operationId="apappssE4Unidades",summary="Consultar pesaje y devolución por unidad")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_VER')")
    public ResponseEntity<ApiResponse<E4WebTypes.Unidades>> unidades(@PathVariable @Positive Long asignacionId,
      @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest req) {
        return doAction("UNIDADES",null,null,asignacionId,null,null,null,E4WebTypes.Unidades.class,auth,req);
    }
    @PostMapping("/unidades/{unidadId}/clasificaciones") @IdempotentOperation
    @Operation(operationId="apappssE4Clasificar",summary="Clasificar una jaba con calidades mixtas y rechazo")
    @PreAuthorize("@permissionGuard.has(authentication,'ENTREGAS_CREAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.ClasificacionResultado>> clasificar(
            @PathVariable @Positive Long unidadId,
            @Valid @RequestBody E4WebTypes.Clasificacion body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("CLASIFICAR",null,null,null,unidadId,null,body,
                E4WebTypes.ClasificacionResultado.class,auth,req);
    }

    @PostMapping("/unidades/{unidadId}/pesar") @IdempotentOperation
    @Operation(operationId="apappssE4Pesar",summary="Pesar jaba, descontar tara y congelar precio vigente")
    @PreAuthorize("@permissionGuard.has(authentication,'ENTREGAS_CREAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.PesajeResultado>> pesar(@PathVariable @Positive Long unidadId,
      @Valid @RequestBody E4WebTypes.Pesaje body,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("PESAR",null,null,null,unidadId,null,body,E4WebTypes.PesajeResultado.class,auth,req);
    }
    @PostMapping("/asignaciones/{asignacionId}/devolucion") @IdempotentOperation
    @Operation(operationId="apappssE4Devolver",summary="Conciliar jabas llenas, vacías y faltantes")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_CREAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.DevolucionResultado>> devolver(@PathVariable @Positive Long asignacionId,
      @Valid @RequestBody E4WebTypes.Devolucion body,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("DEVOLVER",null,null,asignacionId,null,null,body,E4WebTypes.DevolucionResultado.class,auth,req);
    }
    @PostMapping("/asignaciones/{asignacionId}/entrega") @IdempotentOperation
    @Operation(operationId="apappssE4Confirmar",summary="Crear entrega y detalle desde pesos confirmados sin duplicar venta")
    @PreAuthorize("@permissionGuard.has(authentication,'ENTREGAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.EntregaResultado>> confirmar(@PathVariable @Positive Long asignacionId,
      @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest req) {
        return doAction("CONFIRMAR",null,null,asignacionId,null,null,null,E4WebTypes.EntregaResultado.class,auth,req);
    }
    @PostMapping("/entregas/{entregaId}/sanciones") @IdempotentOperation
    @Operation(operationId="apappssE4Sancionar",summary="Sanción individual con precio original y descuento histórico")
    @PreAuthorize("@permissionGuard.has(authentication,'AJUSTES_CREAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.SancionResultado>> sancionar(@PathVariable @Positive Long entregaId,
      @Valid @RequestBody E4WebTypes.Sancion body,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("SANCION",null,null,null,null,entregaId,body,E4WebTypes.SancionResultado.class,auth,req);
    }
    @PostMapping("/campanias/{campaniaId}/tarifas") @IdempotentOperation
    @Operation(operationId="apappssE4Tarifar",summary="Versionar tarifa individual por concepto")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_ADMINISTRAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.TarifaResultado>> tarifar(@PathVariable @Positive Long campaniaId,
      @Valid @RequestBody E4WebTypes.Tarifa body,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("TARIFA",campaniaId,null,null,null,null,body,E4WebTypes.TarifaResultado.class,auth,req);
    }
    @PostMapping("/asignaciones/{asignacionId}/faltantes/confirmar") @IdempotentOperation
    @Operation(operationId="apappssE4ValidarFaltantes",summary="Confirmar incidencia antes de un cargo particular")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_APROBAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.ValidacionFaltante>> validarFaltantes(
       @PathVariable @Positive Long asignacionId,@Valid @RequestBody E4WebTypes.Cargo body,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest req) {
        return doAction("VALIDAR_FALTANTE",null,null,asignacionId,null,null,body,
            E4WebTypes.ValidacionFaltante.class,auth,req);
    }
    @PostMapping("/asignaciones/{asignacionId}/cargos") @IdempotentOperation
    @Operation(operationId="apappssE4CobrarFaltantes",summary="Registrar cargo autorizado por jabas faltantes")
    @PreAuthorize("@permissionGuard.has(authentication,'JABAS_APROBAR')")
    public ResponseEntity<ApiResponse<E4WebTypes.CargoResultado>> cargo(@PathVariable @Positive Long asignacionId,
      @Valid @RequestBody E4WebTypes.Cargo body,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest req) {
        return doAction("CARGO",null,null,asignacionId,null,null,body,E4WebTypes.CargoResultado.class,auth,req);
    }
    @GetMapping("/campanias/{campaniaId}/prebalance")
    @Operation(operationId="apappssE4Prebalance",summary="Prebalance comercial sin prorrateo ni pagos")
    @PreAuthorize("@permissionGuard.has(authentication,'CAMPANIAS_VER')")
    public ResponseEntity<ApiResponse<E4WebTypes.Prebalance>> balance(@PathVariable @Positive Long campaniaId,
      @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest req) {
        return doAction("BALANCE",campaniaId,null,null,null,null,null,E4WebTypes.Prebalance.class,auth,req);
    }
}
