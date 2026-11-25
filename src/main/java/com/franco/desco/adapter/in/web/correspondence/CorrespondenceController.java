package com.franco.desco.adapter.in.web.correspondence;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.correspondence.CorrespondenceService;
import com.franco.desco.application.correspondence.CorrespondenceEvents;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import com.franco.desco.application.localdocument.LocalDocumentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/gestion-documentaria")
@Tag(name = "Correspondencia interna", description = "Documentos administrativos entre usuarios por UOT, independientes de evidencias técnicas y APAPPSS")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class CorrespondenceController {
    private final CorrespondenceService service;
    private final CorrespondenceEvents events;
    private final LocalDocumentService files;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;

    public CorrespondenceController(CorrespondenceService service, CorrespondenceEvents events, LocalDocumentService files,
            ApiResponseFactory responses, JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata) {
        this.service = service;
        this.events = events;
        this.files = files;
        this.responses = responses;
        this.identities = identities;
        this.metadata = metadata;
    }

    public record SendRequest(@NotNull @Positive Long uotId,
            @Positive Long destinoUotId, @Positive Long reemplazaDocumentoId,
            @Positive Long documentoPadreId, @NotNull @Positive Long tipoDocumentoId,
            @NotBlank @Size(max = 240) String asunto, @Size(max = 3000) String cuerpo,
            @Pattern(regexp="RESPUESTA|REENVIO|DERIVACION|RECTIFICACION|OBSERVACION") String tipoMovimiento,
            Boolean requiereRespuesta, Instant fechaLimite,
            @NotEmpty @Size(max = 50) List<@NotNull @Positive Long> destinatarioIds,
            @NotNull @Size(max = 10) List<@NotNull @Positive Long> archivoIds) {}

    public record DecisionRequest(@NotBlank @Pattern(regexp="OBSERVAR|FINALIZAR") String accion,
            @Size(max=400) String motivo) {}

    public record DraftRequest(@Positive Long borradorId, @NotNull Map<String, Object> contenido) {}

    public record TypeRequest(@NotBlank @Size(max = 40) String codigo,
            @NotBlank @Size(max = 120) String nombre, @Size(max = 300) String descripcion) {}

    private ResponseEntity<ApiResponse<Object>> query(String action, Map<String, ?> data,
            JwtAuthenticationToken auth, HttpServletRequest request) {
        return responses.from(service.execute(action, data, identities.resolve(auth), metadata.resolve(request), Object.class), request);
    }

    private Map<String, Object> sendData(SendRequest body, Long parentId, Long replacedId) {
        Map<String, Object> data = new java.util.LinkedHashMap<>();
        data.put("uotId", body.uotId());
        data.put("destinoUotId", body.destinoUotId() == null ? body.uotId() : body.destinoUotId());
        if (parentId != null) data.put("documentoPadreId", parentId);
        if (replacedId != null) data.put("reemplazaDocumentoId", replacedId);
        data.put("tipoDocumentoId", body.tipoDocumentoId());
        data.put("asunto", body.asunto());
        data.put("cuerpo", body.cuerpo());
        data.put("destinatarioIds", body.destinatarioIds());
        data.put("archivoIds", body.archivoIds());
        data.put("requiereRespuesta", Boolean.TRUE.equals(body.requiereRespuesta()));
        if (body.fechaLimite() != null) data.put("fechaLimite", body.fechaLimite());
        if (body.tipoMovimiento() != null) data.put("tipoMovimiento", body.tipoMovimiento());
        return data;
    }


    @GetMapping("/bandeja")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaBandeja",summary="Recibidos, enviados y expedientes en los que participa")
    public ResponseEntity<ApiResponse<Object>> inbox(@RequestParam @Positive Long uotId,
            @RequestParam(defaultValue="RECIBIDOS") String bandeja,
            @RequestParam(defaultValue="1") @Min(1) int pagina,
            @RequestParam(defaultValue="20") @Min(1) @Max(100) int tamano,
            @RequestParam(required=false) @Positive Long tipoFiltroId,
            @RequestParam(required=false) @Size(max=240) String buscar,
            @RequestParam(required=false) String estadoFiltro,
            @RequestParam(required=false) @Size(max=120) String unidad,
            @RequestParam(required=false) @Size(max=120) String destinatario,
            @RequestParam(required=false) @org.springframework.format.annotation.DateTimeFormat(iso=org.springframework.format.annotation.DateTimeFormat.ISO.DATE) java.time.LocalDate desde,
            @RequestParam(required=false) @org.springframework.format.annotation.DateTimeFormat(iso=org.springframework.format.annotation.DateTimeFormat.ISO.DATE) java.time.LocalDate hasta,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> data=new java.util.LinkedHashMap<>();
        data.put("uotId",uotId);data.put("bandeja",bandeja);data.put("pagina",pagina);data.put("tamano",tamano);
        if (tipoFiltroId!=null) data.put("tipoFiltroId",tipoFiltroId);
        if (buscar!=null && !buscar.isBlank()) data.put("buscar",buscar);
        if (estadoFiltro!=null && !estadoFiltro.isBlank()) data.put("estadoFiltro",estadoFiltro);
        if (unidad!=null && !unidad.isBlank()) data.put("unidad",unidad);
        if (destinatario!=null && !destinatario.isBlank()) data.put("destinatario",destinatario);
        if (desde!=null) data.put("desde",desde.toString());
        if (hasta!=null) data.put("hasta",hasta.toString());
        return query("LISTAR",data,authentication,request);
    }

    @GetMapping("/archivos")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaArchivos",summary="Inventario de adjuntos en expedientes donde participa el usuario")
    public ResponseEntity<ApiResponse<Object>> archives(@RequestParam @Positive Long uotId,
            @RequestParam(defaultValue="1") @Min(1) int pagina,
            @RequestParam(defaultValue="20") @Min(1) @Max(100) int tamano,
            @RequestParam(required=false) @Size(max=240) String buscar,
            @RequestParam(required=false) @Pattern(regexp="PDF|IMAGEN|OTROS") String formato,
            @RequestParam(required=false) @org.springframework.format.annotation.DateTimeFormat(iso=org.springframework.format.annotation.DateTimeFormat.ISO.DATE) java.time.LocalDate desde,
            @RequestParam(required=false) @org.springframework.format.annotation.DateTimeFormat(iso=org.springframework.format.annotation.DateTimeFormat.ISO.DATE) java.time.LocalDate hasta,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> data=new java.util.LinkedHashMap<>();
        data.put("uotId",uotId);data.put("pagina",pagina);data.put("tamano",tamano);
        if (buscar!=null && !buscar.isBlank()) data.put("buscar",buscar);
        if (formato!=null && !formato.isBlank()) data.put("formato",formato);
        if (desde!=null) data.put("desde",desde.toString());
        if (hasta!=null) data.put("hasta",hasta.toString());
        return query("LISTAR_ARCHIVOS",data,authentication,request);
    }

    @GetMapping("/pendientes")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaPendientes",summary="Cantidad de documentos sin abrir por el usuario actual")
    public ResponseEntity<ApiResponse<Object>> pending(@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("CONTADOR",Map.of("uotId",uotId),authentication,request);
    }

    @GetMapping(value="/eventos",produces=MediaType.TEXT_EVENT_STREAM_VALUE)
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaEventos",summary="Avisos en tiempo real sin contenido documental")
    public SseEmitter events(@Parameter(hidden=true) JwtAuthenticationToken authentication) {
        return events.subscribe(identities.resolve(authentication).usuarioId());
    }

    @GetMapping("/contexto")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaContexto",summary="Unidad principal del usuario actual")
    public ResponseEntity<ApiResponse<Object>> context(
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("CONTEXTO",Map.of(),authentication,request);
    }

    @PostMapping("/{id}/atender")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaAtender",summary="Confirmar inicio de atención")
    public ResponseEntity<ApiResponse<Object>> attend(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("ATENDER",Map.of("uotId",uotId,"documentoId",id),authentication,request);
    }

    @PostMapping("/{id}/conforme")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaConformar",summary="Confirmar respuesta de una asignación interna")
    public ResponseEntity<ApiResponse<Object>> confirm(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("CONFORMAR",Map.of("uotId",uotId,"documentoId",id),authentication,request);
    }

    @GetMapping("/destinatarios")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaDestinatarios",summary="Usuarios empleados disponibles en la UOT")
    public ResponseEntity<ApiResponse<Object>> recipients(@RequestParam @Positive Long uotId,
            @RequestParam(required=false) @Positive Long destinoUotId,
            @RequestParam(required=false) @Positive Long documentoPadreId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> data=new java.util.LinkedHashMap<>();
        data.put("uotId",uotId);
        if (destinoUotId!=null) data.put("destinoUotId",destinoUotId);
        if (documentoPadreId!=null) data.put("documentoPadreId",documentoPadreId);
        return query("DESTINATARIOS",data,authentication,request);
    }

    @GetMapping("/tipos")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaTipos",summary="Tipos activos de documentos internos")
    public ResponseEntity<ApiResponse<Object>> types(@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("TIPOS",Map.of("uotId",uotId),authentication,request);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaEnviar",summary="Enviar documento a uno o varios usuarios")
    public ResponseEntity<ApiResponse<Object>> send(@Valid @RequestBody SendRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("ENVIAR", sendData(body, body.documentoPadreId(), body.reemplazaDocumentoId()), authentication, request);
    }

    @PostMapping("/{id}/responder")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaResponder",summary="Responder o derivar dentro del mismo expediente")
    public ResponseEntity<ApiResponse<Object>> reply(@PathVariable @Positive Long id,
            @Valid @RequestBody SendRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("ENVIAR", sendData(body, id, null), authentication, request);
    }

    @PostMapping("/{id}/rectificar")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaRectificar", summary="Enviar una nueva versión sin eliminar la anterior")
    public ResponseEntity<ApiResponse<Object>> rectify(@PathVariable @Positive Long id,
            @Valid @RequestBody SendRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("ENVIAR", sendData(body, id, id), authentication, request);
    }

    @GetMapping("/uot-destinos")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaUnidadesDestino", summary="Unidades disponibles para correspondencia")
    public ResponseEntity<ApiResponse<Object>> units(@RequestParam @Positive Long uotId,
            @RequestParam(required=false) @Positive Long documentoPadreId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> data=new java.util.LinkedHashMap<>();
        data.put("uotId",uotId);
        if (documentoPadreId!=null) data.put("documentoPadreId",documentoPadreId);
        return query("UOTS_DESTINO",data,authentication,request);
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaVer",summary="Detalle y estados individuales por destinatario")
    public ResponseEntity<ApiResponse<Object>> detail(@PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("VER",Map.of("uotId",uotId,"documentoId",id),authentication,request);
    }

    @PostMapping("/{id}/abrir")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaAbrir",summary="Marcar la primera lectura solamente para el destinatario actual")
    public ResponseEntity<ApiResponse<Object>> open(@PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("ABRIR",Map.of("uotId",uotId,"documentoId",id),authentication,request);
    }

    @PostMapping("/{id}/anular")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaAnular", summary="Anular el trámite conservando su historial")
    public ResponseEntity<ApiResponse<Object>> cancel(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId, @Valid @RequestBody CancellationRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("ANULAR",Map.of("uotId",uotId,"documentoId",id,"motivo",body.motivo()),authentication,request);
    }

    public record CancellationRequest(@NotBlank @Size(max=400) String motivo) {}

    @PostMapping("/{id}/revision")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaRevisar",summary="Observar o dar conformidad al trámite")
    public ResponseEntity<ApiResponse<Object>> review(@PathVariable @Positive Long id,
            @RequestParam @Positive Long uotId,@Valid @RequestBody DecisionRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        if ("OBSERVAR".equals(body.accion()) && (body.motivo()==null || body.motivo().isBlank()))
            return ResponseEntity.badRequest().build();
        return query(body.accion(),Map.of("uotId",uotId,"documentoId",id,
            "motivo",body.motivo()==null ? "" : body.motivo().trim()),authentication,request);
    }

    @GetMapping("/{id}/historial")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaHistorial",summary="Seguimiento completo por participantes del expediente")
    public ResponseEntity<ApiResponse<Object>> history(@PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("HISTORIAL",Map.of("uotId",uotId,"documentoId",id),authentication,request);
    }

    @GetMapping("/{id}/adjuntos/{archivoId}/contenido")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaContenido",summary="Contenido protegido de adjunto administrativo")
    public ResponseEntity<?> content(@PathVariable @Positive Long id,@PathVariable @Positive Long archivoId,
            @RequestParam @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        var identity=identities.resolve(authentication);
        var allowed=service.execute("DESCARGAR",Map.of("uotId",uotId,"documentoId",id,"archivoId",archivoId),
                identity,metadata.resolve(request),Object.class);
        if (!allowed.exitoso()) return responses.from(allowed,request);
        var result=files.content(identity,archivoId);
        if (!result.exitoso() || result.datos()==null) return responses.from(result,request);
        var data=result.datos();
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(data.info().contentType()))
                .contentLength(data.info().size())
                .header(HttpHeaders.CONTENT_DISPOSITION,ContentDisposition.inline()
                        .filename(data.info().originalName(),StandardCharsets.UTF_8).build().toString())
                .header("X-Content-Type-Options","nosniff")
                .header(HttpHeaders.CACHE_CONTROL,"no-store")
                .body(data.resource());
    }

    @GetMapping("/borradores")
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaBorradores",summary="Consultar borradores personales")
    public ResponseEntity<ApiResponse<Object>> drafts(
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("BORRADORES",Map.of(),authentication,request);
    }

    @PostMapping("/borradores")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaGuardarBorrador",summary="Guardar un borrador personal")
    public ResponseEntity<ApiResponse<Object>> saveDraft(@Valid @RequestBody DraftRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> data=new java.util.LinkedHashMap<>();
        if (body.borradorId()!=null) data.put("borradorId",body.borradorId());
        data.put("contenido",body.contenido());
        return query("BORRADOR_GUARDAR",data,authentication,request);
    }

    @DeleteMapping("/borradores/{id}")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaEliminarBorrador",summary="Descartar borrador personal")
    public ResponseEntity<ApiResponse<Object>> deleteDraft(@PathVariable @Positive Long id,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("BORRADOR_ELIMINAR",Map.of("borradorId",id),authentication,request);
    }

    @PostMapping("/{id}/recordar")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaRecordar",summary="Recordar un encargo pendiente")
    public ResponseEntity<ApiResponse<Object>> remind(@PathVariable @Positive Long id,
            @RequestParam(required=false) @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> data=new java.util.LinkedHashMap<>();
        data.put("documentoId",id);
        if(uotId!=null)data.put("uotId",uotId);
        return query("RECORDAR",data,authentication,request);
    }

    @PostMapping("/{id}/abrir-hilo")
    @IdempotentOperation
    @PreAuthorize("isAuthenticated()")
    @Operation(operationId="correspondenciaLeerHilo",summary="Registrar lectura individual de los mensajes visibles")
    public ResponseEntity<ApiResponse<Object>> readThread(@PathVariable @Positive Long id,
            @RequestParam(required=false) @Positive Long uotId,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        Map<String,Object> data=new java.util.LinkedHashMap<>();
        data.put("documentoId",id);
        if(uotId!=null)data.put("uotId",uotId);
        return query("ABRIR_HILO",data,authentication,request);
    }

    @GetMapping("/catalogo/tipos")
    @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_LISTAR')")
    @Operation(operationId="correspondenciaCatalogoTipos",summary="Administrar tipos de documento desde Catálogos")
    public ResponseEntity<ApiResponse<Object>> allTypes(
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("TIPO_LISTAR",Map.of(),authentication,request);
    }

    @PostMapping("/catalogo/tipos")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
    @Operation(operationId="correspondenciaCatalogoTipoCrear",summary="Crear tipo administrable")
    public ResponseEntity<ApiResponse<Object>> createType(@Valid @RequestBody TypeRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.execute("TIPO_CREAR",body,identities.resolve(authentication),metadata.resolve(request),Object.class),request);
    }

    @PutMapping("/catalogo/tipos/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_EDITAR')")
    @Operation(operationId="correspondenciaCatalogoTipoEditar",summary="Editar tipo administrable")
    public ResponseEntity<ApiResponse<Object>> updateType(@PathVariable @Positive Long id,@Valid @RequestBody TypeRequest body,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(service.execute("TIPO_EDITAR",Map.of("documentoId",id,"nombre",body.nombre(),
                "descripcion",body.descripcion()==null?"":body.descripcion()),identities.resolve(authentication),metadata.resolve(request),Object.class),request);
    }

    @PostMapping("/catalogo/tipos/{id}/deshabilitar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_RETIRAR')")
    @Operation(operationId="correspondenciaCatalogoTipoDeshabilitar",summary="Deshabilitar tipo no utilizado")
    public ResponseEntity<ApiResponse<Object>> disableType(@PathVariable @Positive Long id,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return query("TIPO_DESHABILITAR",Map.of("documentoId",id),authentication,request);
    }
}
