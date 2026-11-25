package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.productive.service.GpProductorService;
import com.franco.desco.domain.productive.GpProductorModels;
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
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/v1/gestion-productiva-general/productores")
@Tag(name = "Gestion productiva general", description = "Padrón técnico y parcelas directas")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class GpProductorController {
    private final GpProductorService service;
    private final JwtSessionIdentityResolver identity;
    private final IdempotencyKeyResolver idempotency;

    public GpProductorController(GpProductorService service, JwtSessionIdentityResolver identity,
                                  IdempotencyKeyResolver idempotency) {
        this.service = service;
        this.identity = identity;
        this.idempotency = idempotency;
    }

    private <T> ResponseEntity<ApiResponse<T>> ok(T datos, HttpServletRequest r) {
        return ResponseEntity.ok(new ApiResponse<>(true, "GP_OK", "Operación realizada.", datos,
                CorrelationIdFilter.correlationId(r), Instant.now()));
    }

    private ResponseEntity<ApiResponse<GpWebTypes.Id>> saved(long id, HttpServletRequest r, boolean crear) {
        var value = new ApiResponse<>(true, "GP_OK", "Registro guardado.", new GpWebTypes.Id(id),
                CorrelationIdFilter.correlationId(r), Instant.now());
        return crear ? ResponseEntity.status(201).body(value) : ResponseEntity.ok(value);
    }

    private static GpProductorWebTypes.Productor toWeb(GpProductorModels.Productor p) {
        return new GpProductorWebTypes.Productor(p.personaId(), p.tipoDocumento(), p.numeroDocumento(),
                p.nombres(), p.apellidoPaterno(), p.apellidoMaterno(), p.nombreCompleto(),
                p.telefono(), p.correo(), p.fechaNacimiento(), p.distritoCodigo(),
                p.centroPobladoId(), p.referencia());
    }

    private static GpWebTypes.Parcela toWeb(GpProductorModels.Parcela p) {
        return new GpWebTypes.Parcela(p.parcelaId(), p.predioId(), p.codigo(), p.nombre(), p.areaHa(),
                p.estado(), p.distritoCodigo(), p.centroPobladoId(), p.latitud(), p.longitud(),
                p.referencia(), p.observacion());
    }

    @GetMapping
    @Operation(operationId = "gpProductoresListar", summary = "Listar productores activos de la UOT")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_LISTAR')")
    public ResponseEntity<ApiResponse<List<GpProductorWebTypes.Productor>>> listar(
            @RequestParam @Positive long uotId, @RequestParam(required = false) String buscar,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return ok(service.listar(identity.resolve(auth), uotId, buscar).stream()
                .map(GpProductorController::toWeb).toList(), request);
    }

    @GetMapping("/{personaId}/parcelas")
    @Operation(operationId = "gpProductorParcelasListar", summary = "Listar parcelas de un productor")
    @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_LISTAR')")
    public ResponseEntity<ApiResponse<List<GpWebTypes.Parcela>>> parcelas(
            @RequestParam @Positive long uotId, @PathVariable @Positive long personaId,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return ok(service.parcelas(identity.resolve(auth), uotId, personaId).stream()
                .map(GpProductorController::toWeb).toList(), request);
    }

    @PostMapping("/{personaId}/parcelas")
    @IdempotentOperation
    @Operation(operationId = "gpProductorParcelaCrear", summary = "Registrar parcela sin crear fundo en la interfaz")
    @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_CREAR')")
    public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearParcela(
            @RequestParam @Positive long uotId, @PathVariable @Positive long personaId,
            @Valid @RequestBody GpProductorWebTypes.ParcelaAlta q,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        var ficha = new GpProductorModels.FichaParcela(q.nombre(), q.areaHa(), q.distritoCodigo(),
                q.centroPobladoId(), q.latitud(), q.longitud(), q.referencia(), q.observacion());
        return saved(service.crearParcela(identity.resolve(auth), uotId, personaId, ficha,
                idempotency.required(request)), request, true);
    }

    @PutMapping("/{personaId}")
    @IdempotentOperation
    @Operation(operationId = "gpProductorEditar", summary = "Editar datos de persona del padrón")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<GpWebTypes.Id>> editar(
            @RequestParam @Positive long uotId, @PathVariable @Positive long personaId,
            @Valid @RequestBody GpProductorWebTypes.Editar q,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        var ficha = new GpProductorModels.FichaPersona(q.nombres(), q.apellidoPaterno(),
                q.apellidoMaterno(), q.telefono(), q.correo(), q.distritoCodigo(),
                q.centroPobladoId(), q.referencia());
        return saved(service.editar(identity.resolve(auth), uotId, personaId, ficha,
                idempotency.required(request)), request, false);
    }

    @PostMapping("/{personaId}/retirar")
    @IdempotentOperation
    @Operation(operationId = "gpProductorRetirar", summary = "Desactivar rol territorial del productor")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_RETIRAR')")
    public ResponseEntity<ApiResponse<GpWebTypes.Id>> retirar(
            @RequestParam @Positive long uotId, @PathVariable @Positive long personaId,
            @Valid @RequestBody GpProductorWebTypes.Retirar q,
            @Parameter(hidden = true) JwtAuthenticationToken auth,
            @Parameter(hidden = true) HttpServletRequest request) {
        return saved(service.desactivar(identity.resolve(auth), uotId, personaId, q.motivo(),
                idempotency.required(request)), request, false);
    }
}
