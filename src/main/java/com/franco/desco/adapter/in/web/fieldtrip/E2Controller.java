package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.fieldtrip.port.in.E2UseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/salidas-operativas")
@Tag(name = "Salidas operativas", description = "Etapa 2: solicitudes, autorización, visitas, entrega y retorno auditables")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class E2Controller {
    private final E2UseCase service;
    private final E2WebMapper mapper;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identity;
    private final ClientRequestContextResolver metadata;

    public E2Controller(E2UseCase service, E2WebMapper mapper, ApiResponseFactory responses,
                        JwtSessionIdentityResolver identity, ClientRequestContextResolver metadata) {
        this.service = service;
        this.mapper = mapper;
        this.responses = responses;
        this.identity = identity;
        this.metadata = metadata;
    }

    @GetMapping
    @Operation(operationId = "salidasOperativasListar", summary = "Listar salidas por ámbito y estado")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_LISTAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Lista>> listar(
            @RequestParam @Positive Long uotId, @RequestParam(required = false) Long convenioId,
            @RequestParam(required = false) String estado,
            @RequestParam(defaultValue = "1") @Min(1) Integer pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) Integer tamano,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.listar(new E2Commands.Listar(uotId, convenioId, estado, pagina, tamano),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @GetMapping("/catalogos")
    @Operation(operationId = "salidasOperativasCatalogos", summary = "Consultar motivos, visitas, recursos y participantes disponibles")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_LISTAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Catalogos>> catalogos(
            @RequestParam @Positive Long uotId, @RequestParam(required = false) Long convenioId,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.catalogos(new E2Commands.Catalogos(uotId, convenioId),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @GetMapping("/{id}")
    @Operation(operationId = "salidasOperativasVer", summary = "Ficha integral de la salida")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<E2WebTypes.Detalle>> ver(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.ver(new E2Commands.Ver(uotId, convenioId, id),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasSolicitar", summary = "Crear y enviar una solicitud agrupada")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CREAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> solicitar(
            @RequestParam @Positive Long uotId, @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.SolicitudRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.solicitar(new E2Commands.Solicitar(uotId, convenioId, mapper.solicitud(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/corregir")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasCorregir", summary = "Corregir y reenviar una solicitud observada")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> corregir(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.CorreccionRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.corregir(new E2Commands.Corregir(uotId, convenioId, id, mapper.correccion(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/decision")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasDecidir", summary = "Aprobar, observar o rechazar una solicitud")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> decidir(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.DecisionRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.decidir(new E2Commands.Decidir(uotId, convenioId, id, mapper.decision(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/entregar")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasEntregar", summary = "Confirmar la entrega física de recursos autorizados")
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> entregar(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.entregar(new E2Commands.Entregar(uotId, convenioId, id),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/iniciar")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasIniciar", summary = "Iniciar una salida autorizada")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> iniciar(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.iniciar(new E2Commands.Iniciar(uotId, convenioId, id),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/visitas")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasVisitar", summary = "Iniciar una visita de un destino autorizado")
    @PreAuthorize("@permissionGuard.has(authentication,'VISITAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> visitar(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.VisitaRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.visitar(new E2Commands.Visitar(uotId, convenioId, id, mapper.visita(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/visitas/{visitaId}/finalizar")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasVisitaFinalizar", summary = "Finalizar visita y registrar su actuación")
    @PreAuthorize("@permissionGuard.has(authentication,'VISITAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> finalizarVisita(
            @PathVariable @Positive Long id, @PathVariable @Positive Long visitaId,
            @RequestParam @Positive Long uotId, @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.VisitaCierreRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.finalizarVisita(new E2Commands.FinalizarVisita(
                        uotId, convenioId, id, visitaId, mapper.visitaCierre(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/retorno")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasRetornar", summary = "Registrar un retorno general con el estado de todos los recursos")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> retornar(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.RetornoRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.retornar(new E2Commands.Retornar(uotId, convenioId, id, mapper.retorno(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/inspeccion")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasInspeccionar", summary = "Validar la devolución física de los recursos")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> inspeccionar(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.InspeccionRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.inspeccionar(new E2Commands.Inspeccionar(uotId, convenioId, id, mapper.inspeccion(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/fecha-fin")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasRegularizarFin", summary = "Regularizar la fecha final prevista")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> regularizarFin(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.FechaFinRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.regularizarFin(new E2Commands.RegularizarFin(
                        uotId, convenioId, id, body.fechaFinPrevista()),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/cerrar")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasCerrar", summary = "Cerrar la salida validando visitas y devoluciones")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> cerrar(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody(required = false) E2WebTypes.CierreRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.cerrar(new E2Commands.Cerrar(uotId, convenioId, id, mapper.cierre(body)),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/destinos/vincular")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasVincularDestino", summary = "Vincular un predio registrado durante la salida")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> vincularDestino(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.VincularDestinoRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.vincularDestino(new E2Commands.VincularDestino(
                        uotId, convenioId, id, body.destinoId(), body.predioId()),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }

    @PostMapping("/{id}/cancelar-operativa")
    @IdempotentOperation
    @Operation(operationId = "salidasOperativasCancelar", summary = "Cancelar una salida sin entrega física")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_RETIRAR') or @permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> cancelar(
            @PathVariable @Positive Long id, @RequestParam @Positive Long uotId,
            @RequestParam(required = false) Long convenioId,
            @Valid @RequestBody E2WebTypes.CancelarRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.cancelar(new E2Commands.Cancelar(uotId, convenioId, id, body.motivo()),
                identity.resolve(auth), metadata.resolve(request)), request, mapper::response);
    }
}
