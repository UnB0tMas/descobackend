package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.shared.SessionIdentity;
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
@RequestMapping("/api/v1/gestion-productiva-general")
@Tag(name="Gestion productiva general",description="Seguimiento agregado de cultivos y crianzas. Excluye convenios especiales.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class GpController {
  private final GpRepository db;
  private final JwtSessionIdentityResolver identities;
  private final IdempotencyKeyResolver idempotency;
  public GpController(GpRepository db,JwtSessionIdentityResolver identities,IdempotencyKeyResolver idempotency){
    this.db=db;this.identities=identities;this.idempotency=idempotency;
  }
  private SessionIdentity user(JwtAuthenticationToken authentication){return identities.resolve(authentication);}
  private <T> ResponseEntity<ApiResponse<T>> ok(T value,HttpServletRequest request){
    return ResponseEntity.ok(new ApiResponse<>(true,"GP_OK","Operación realizada correctamente.",value,
      CorrelationIdFilter.correlationId(request),Instant.now()));
  }
  private ResponseEntity<ApiResponse<GpWebTypes.Id>> created(Long id,HttpServletRequest r){
    return ResponseEntity.status(201).body(new ApiResponse<>(true,"GP_CREADO","Registro guardado.",
       new GpWebTypes.Id(id),CorrelationIdFilter.correlationId(r),Instant.now()));
  }
  @GetMapping("/predios/{predioId}/parcelas")
  @Operation(operationId="gpParcelasListar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_LISTAR')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.Parcela>>> parcelas(@RequestParam @Positive long uotId,@PathVariable @Positive long predioId,
     @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(db.parcelas(user(a),uotId,predioId),r);
  }
  @PostMapping("/parcelas") @IdempotentOperation
  @Operation(operationId="gpParcelaCrear",summary="Registrar parcela con distrito y GPS opcional")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearParcela(@RequestParam @Positive long uotId,
      @Valid @RequestBody GpWebTypes.ParcelaAlta q,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return created(db.crearParcela(user(a),uotId,q,idempotency.required(r)),r);
  }
  @PutMapping("/parcelas/{id}") @IdempotentOperation
  @Operation(operationId="gpParcelaEditar",summary="Actualizar parcela, ubicación administrativa y punto GPS")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_EDITAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> editarParcela(@RequestParam @Positive long uotId,
      @PathVariable @Positive long id,@Valid @RequestBody GpWebTypes.ParcelaEditar q,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.editarParcela(user(a),uotId,id,q,idempotency.required(r))),r);
  }
  @GetMapping("/catalogos")
  @Operation(operationId="gpCatalogosListar")
  @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER') or @permissionGuard.has(authentication,'CATALOGOS_LISTAR')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.Catalogo>>> catalogos(@RequestParam @Positive long uotId,
     @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return ok(db.catalogos(user(a),uotId),r);}
  @GetMapping("/parcelas/{parcelaId}/actividades")
  @Operation(operationId="gpActividadesListar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_VER')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.Actividad>>> actividades(@RequestParam @Positive long uotId,@PathVariable @Positive long parcelaId,
     @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return ok(db.actividades(user(a),uotId,parcelaId),r);}
  @PostMapping("/actividades") @IdempotentOperation
  @Operation(operationId="gpActividadCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearActividad(@RequestParam @Positive long uotId,@Valid @RequestBody GpWebTypes.ActividadAlta q,
     @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return created(db.crearActividad(user(a),uotId,q,idempotency.required(r)),r);
  }
  @PutMapping("/actividades/{id}") @IdempotentOperation
  @Operation(operationId="gpActividadEditar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_EDITAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> editarActividad(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
       @Valid @RequestBody GpWebTypes.ActividadEditar q,@Parameter(hidden=true) JwtAuthenticationToken a,
       @Parameter(hidden=true) HttpServletRequest r){return ok(new GpWebTypes.Id(db.editarActividad(user(a),uotId,id,q,idempotency.required(r))),r);}
  @GetMapping("/actividades/{id}/revisiones")
  @Operation(operationId="gpActividadRevisionesListar",summary="Consultar cambios de la ficha de actividad")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_VER')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.ActividadRevision>>> revisiones(
      @RequestParam @Positive long uotId,@PathVariable @Positive long id,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(db.revisiones(user(a),uotId,id),r);
  }
  @GetMapping("/actividades/{id}/censos")
  @Operation(operationId="gpCensosListar")
  @PreAuthorize("@permissionGuard.has(authentication,'CENSOS_LISTAR')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.Censo>>> censos(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return ok(db.censos(user(a),uotId,id),r);}
  @PostMapping("/actividades/{id}/censos") @IdempotentOperation
  @Operation(operationId="gpCensoCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'CENSOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearCenso(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
       @Valid @RequestBody GpWebTypes.CensoAlta q,@Parameter(hidden=true) JwtAuthenticationToken a,
       @Parameter(hidden=true) HttpServletRequest r){return created(db.crearCenso(user(a),uotId,id,q,idempotency.required(r)),r);}
  @GetMapping("/actividades/{id}/eventos")
  @Operation(operationId="gpEventosListar")
  @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.Evento>>> eventos(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){return ok(db.eventos(user(a),uotId,id),r);}
  @PostMapping("/actividades/{id}/eventos") @IdempotentOperation
  @Operation(operationId="gpEventoCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR') or @permissionGuard.has(authentication,'SANIDAD_CREAR') or @permissionGuard.has(authentication,'EVALUACIONES_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearEvento(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
       @Valid @RequestBody GpWebTypes.EventoAlta q,@Parameter(hidden=true) JwtAuthenticationToken a,
       @Parameter(hidden=true) HttpServletRequest r){return created(db.crearEvento(user(a),uotId,id,q,idempotency.required(r)),r);}
  @GetMapping("/actividades/{id}/incidencias")
  @Operation(operationId="gpIncidenciasListar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_VER')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.Incidencia>>> incidencias(@RequestParam @Positive long uotId,
    @PathVariable @Positive long id,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(db.incidencias(user(a),uotId,id),r);
  }
  @GetMapping("/actividades/{id}/tratamientos")
  @Operation(operationId="gpIncidenciasTratamientosListar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_VER')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.TratamientoSeguimiento>>> tratamientosSeguimiento(@RequestParam @Positive long uotId,
    @PathVariable @Positive long id,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(db.tratamientosIncidencias(user(a),uotId,id),r);
  }
  @PostMapping("/actividades/{id}/incidencias") @IdempotentOperation
  @Operation(operationId="gpIncidenciaCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearIncidencia(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.IncidenciaAlta q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return created(db.crearIncidencia(user(a),uotId,id,q,idempotency.required(r)),r);
  }
  @PutMapping("/incidencias/{id}") @IdempotentOperation
  @Operation(operationId="gpIncidenciaEditar",summary="Corregir incidencia abierta con trazabilidad")
  @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_EDITAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> editarIncidencia(@RequestParam @Positive long uotId,
     @PathVariable @Positive long id,@Valid @RequestBody GpWebTypes.IncidenciaEditar q,
     @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.editarIncidencia(user(a),uotId,id,q,idempotency.required(r))),r);
  }
  @PostMapping("/incidencias/{id}/retirar") @IdempotentOperation
  @Operation(operationId="gpIncidenciaRetirar",summary="Retirar lógicamente incidencia y tratamientos")
  @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_RETIRAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> retirarIncidencia(@RequestParam @Positive long uotId,
     @PathVariable @Positive long id,@Valid @RequestBody GpWebTypes.Motivo q,
     @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.retirarIncidencia(user(a),uotId,id,q.motivo(),idempotency.required(r))),r);
  }
  @GetMapping("/incidencias/{id}/revisiones")
  @Operation(operationId="gpIncidenciaRevisionesListar",summary="Consultar valores previos y motivos de corrección")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_VER')")
  public ResponseEntity<ApiResponse<List<GpWebTypes.IncidenciaRevision>>> revisionesIncidencia(
     @RequestParam @Positive long uotId,@PathVariable @Positive long id,
     @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(db.revisionesIncidencia(user(a),uotId,id),r);
  }
  @PostMapping("/actividades/{id}/incidencias/tratamientos") @IdempotentOperation
  @Operation(operationId="gpIncidenciaTratamientoCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> aplicarTratamiento(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.TratamientoAplicar q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return created(db.aplicarTratamiento(user(a),uotId,id,q,idempotency.required(r)),r);
  }
  @PostMapping("/tratamientos/{id}/finalizar") @IdempotentOperation
  @Operation(operationId="gpIncidenciaTratamientoFinalizar")
  @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> finalizarTratamiento(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.TratamientoFinalizar q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.finalizarTratamiento(user(a),uotId,id,q,idempotency.required(r))),r);
  }
  @PostMapping("/incidencias/{id}/cerrar") @IdempotentOperation
  @Operation(operationId="gpIncidenciaCerrar")
  @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> cerrarIncidencia(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.IncidenciaCerrar q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.cerrarIncidencia(user(a),uotId,id,q,idempotency.required(r))),r);
  }
  @PostMapping("/actividades/{id}/finalizar") @IdempotentOperation
  @Operation(operationId="gpActividadFinalizar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_EDITAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> finalizarActividad(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.Motivo q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.finalizarActividad(user(a),uotId,id,q.motivo(),idempotency.required(r))),r);
  }
  @PostMapping("/actividades/{id}/eliminar") @IdempotentOperation
  @Operation(operationId="gpActividadEliminar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_RETIRAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> eliminarActividad(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.Motivo q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.eliminarActividad(user(a),uotId,id,q.motivo(),idempotency.required(r))),r);
  }
  @PostMapping("/parcelas/{id}/eliminar") @IdempotentOperation
  @Operation(operationId="gpParcelaEliminar")
  @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_RETIRAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> eliminarParcela(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.Motivo q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.eliminarParcela(user(a),uotId,id,q.motivo(),idempotency.required(r))),r);
  }
  @PostMapping("/predios/{id}/eliminar") @IdempotentOperation
  @Operation(operationId="gpPredioEliminar")
  @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_RETIRAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> eliminarPredio(@RequestParam @Positive long uotId,@PathVariable @Positive long id,
    @Valid @RequestBody GpWebTypes.Motivo q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.eliminarPredio(user(a),uotId,id,q.motivo(),idempotency.required(r))),r);
  }
  @PostMapping("/catalogos/cultivos")
  @Operation(operationId="gpCatalogoCultivoCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearCultivo(@RequestParam @Positive long uotId,@Valid @RequestBody GpWebTypes.CatalogoCultivo q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
     return created(db.crearCultivo(user(a),uotId,q),r);
  }
  @PostMapping("/catalogos/especies")
  @Operation(operationId="gpCatalogoEspecieCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearEspecie(@RequestParam @Positive long uotId,@Valid @RequestBody GpWebTypes.CatalogoEspecie q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
     return created(db.crearEspecie(user(a),uotId,q),r);
  }
  @PostMapping("/catalogos/razas")
  @Operation(operationId="gpCatalogoRazaCrear",summary="Registrar raza asociada a una especie pecuaria")
  @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearRaza(@RequestParam @Positive long uotId,
      @Valid @RequestBody GpWebTypes.CatalogoRaza q,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return created(db.crearRaza(user(a),uotId,q),r);
  }
  @PostMapping("/catalogos/problemas")
  @Operation(operationId="gpCatalogoProblemaCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearProblema(@RequestParam @Positive long uotId,@Valid @RequestBody GpWebTypes.CatalogoProblema q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
     return created(db.crearProblema(user(a),uotId,q),r);
  }
  @PostMapping("/catalogos/tratamientos")
  @Operation(operationId="gpCatalogoTratamientoCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearTratamiento(@RequestParam @Positive long uotId,@Valid @RequestBody GpWebTypes.CatalogoTratamiento q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
     return created(db.crearTratamiento(user(a),uotId,q),r);
  }
  @PostMapping("/catalogos/variedades")
  @Operation(operationId="gpCatalogoVariedadCrear")
  @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_CREAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> crearVariedad(@RequestParam @Positive long uotId,
      @Valid @RequestBody GpWebTypes.CatalogoVariedad q,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
     return created(db.crearVariedad(user(a),uotId,q),r);
  }
  @PutMapping("/catalogos/{tipo}/{id}")
  @Operation(operationId="gpCatalogoActualizar")
  @PreAuthorize("@permissionGuard.has(authentication,'CATALOGOS_EDITAR')")
  public ResponseEntity<ApiResponse<GpWebTypes.Id>> actualizarCatalogo(
      @RequestParam @Positive long uotId,@PathVariable String tipo,@PathVariable @Positive long id,
      @Valid @RequestBody GpWebTypes.CatalogoActualizar q,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
    return ok(new GpWebTypes.Id(db.actualizarCatalogo(user(a),uotId,tipo,id,q)),r);
  }

}
