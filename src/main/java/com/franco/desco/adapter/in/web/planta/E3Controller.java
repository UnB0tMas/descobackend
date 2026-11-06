package com.franco.desco.adapter.in.web.planta;
import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.planta.port.in.E3UseCase;
import com.franco.desco.domain.planta.E3Models;
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
import tools.jackson.databind.json.JsonMapper;
@RestController
@RequestMapping("/api/v1/apappss/plantas")
@Tag(name="Plantas de palta",description="Expediente vegetal individual por UOT y convenio")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class E3Controller {
 private final E3UseCase useCase;private final ApiResponseFactory responses;
 private final JwtSessionIdentityResolver identities;private final ClientRequestContextResolver metadata;
 private final JsonMapper mapper;
 public E3Controller(E3UseCase useCase,ApiResponseFactory responses,JwtSessionIdentityResolver identities,
   ClientRequestContextResolver metadata,JsonMapper mapper){
  this.useCase=useCase;this.responses=responses;this.identities=identities;this.metadata=metadata;this.mapper=mapper;
 }
 private <S,T> ResponseEntity<ApiResponse<T>> execute(String action,Long uotId,Long convenioId,Long predioId,Long plantaId,
   String buscar,String estado,Long variedadId,Integer pagina,Integer tamano,Object data,
   Class<S> source,Class<T> result,JwtAuthenticationToken auth,HttpServletRequest request){
  return responses.from(useCase.execute(new Execute(action,uotId,convenioId,predioId,plantaId,buscar,estado,variedadId,pagina,tamano,data),
   identities.resolve(auth),metadata.resolve(request),source),request,value->mapper.convertValue(value,result));
 }
 private ResponseEntity<ApiResponse<E3WebTypes.Operacion>> update(String action,Long uotId,Long convenioId,Long predioId,
   Long plantaId,Object data,JwtAuthenticationToken auth,HttpServletRequest request){
  return execute(action,uotId,convenioId,predioId,plantaId,null,null,null,null,null,data,
   E3Models.Operation.class,E3WebTypes.Operacion.class,auth,request);
 }
 @GetMapping("/catalogos")
 @Operation(operationId="apappssPlantasCatalogos",summary="Variedades, diagnósticos y parcelas válidos")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
 public ResponseEntity<ApiResponse<E3WebTypes.Catalogos>> catalogos(@RequestParam @Positive Long uotId,
   @RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return execute("CATALOGOS",uotId,convenioId,predioId,null,null,null,null,null,null,null,
   E3Models.Catalogs.class,E3WebTypes.Catalogos.class,auth,request);
 }
 @GetMapping
 @Operation(operationId="apappssPlantasListar",summary="Plantas individuales, filtros y totales por variedad")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
 public ResponseEntity<ApiResponse<E3WebTypes.Pagina>> listar(@RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,
   @RequestParam @Positive Long predioId,@RequestParam(required=false) String buscar,
   @RequestParam(required=false) String estado,@RequestParam(required=false) Long variedadId,
   @RequestParam(defaultValue="1") @Min(1) Integer pagina,@RequestParam(defaultValue="20") @Min(1) @Max(100) Integer tamano,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return execute("LISTAR",uotId,convenioId,predioId,null,buscar,estado,variedadId,pagina,tamano,null,
   E3Models.Page.class,E3WebTypes.Pagina.class,auth,request);
 }
 @GetMapping("/{plantaId}")
 @Operation(operationId="apappssPlantaVer",summary="Expediente completo de la planta")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
 public ResponseEntity<ApiResponse<E3WebTypes.Detalle>> ver(@PathVariable @Positive Long plantaId,
   @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return execute("VER",uotId,convenioId,predioId,plantaId,null,null,null,null,null,null,
   E3Models.Detail.class,E3WebTypes.Detalle.class,auth,request);
 }
 @PostMapping("/lotes") @IdempotentOperation
 @Operation(operationId="apappssPlantasCrearLote",summary="Generar identificadores estables a partir de variedad y cantidad")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_CREAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.ResultadoLote>> crear(@RequestParam @Positive Long uotId,
  @RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,@Valid @RequestBody E3WebTypes.Lote body,
  @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return execute("LOTE",uotId,convenioId,predioId,null,null,null,null,null,null,body,
   E3Models.Batch.class,E3WebTypes.ResultadoLote.class,auth,request);
 }
 @PutMapping("/{plantaId}/ficha") @IdempotentOperation
 @Operation(operationId="apappssPlantaCompletarFicha",summary="Completar fecha de plantación o edad de referencia")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.Operacion>> ficha(@PathVariable Long plantaId,@RequestParam Long uotId,
  @RequestParam Long convenioId,@RequestParam Long predioId,@Valid @RequestBody E3WebTypes.Ficha body,
  @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return update("FICHA",uotId,convenioId,predioId,plantaId,body,auth,request);
 }
 @PostMapping("/{plantaId}/estado") @IdempotentOperation
 @Operation(operationId="apappssPlantaEvaluar",summary="Cambiar estado y abrir/cerrar episodio sanitario")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.Operacion>> estado(@PathVariable Long plantaId,@RequestParam Long uotId,
  @RequestParam Long convenioId,@RequestParam Long predioId,@Valid @RequestBody E3WebTypes.Estado body,
  @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return update("ESTADO",uotId,convenioId,predioId,plantaId,body,auth,request);
 }
 @PostMapping("/{plantaId}/tratamientos") @IdempotentOperation
 @Operation(operationId="apappssPlantaTratar",summary="Anexar tratamiento al episodio activo")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.Operacion>> tratar(@PathVariable Long plantaId,@RequestParam Long uotId,
  @RequestParam Long convenioId,@RequestParam Long predioId,@Valid @RequestBody E3WebTypes.Tratamiento body,
  @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return update("TRATAMIENTO",uotId,convenioId,predioId,plantaId,body,auth,request);
 }
 @PostMapping("/{plantaId}/seguimientos") @IdempotentOperation
 @Operation(operationId="apappssPlantaSeguimiento",summary="Registrar seguimiento sin enfermedad ficticia")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.Operacion>> seguir(@PathVariable Long plantaId,@RequestParam Long uotId,
  @RequestParam Long convenioId,@RequestParam Long predioId,@Valid @RequestBody E3WebTypes.Seguimiento body,
  @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return update("SEGUIMIENTO",uotId,convenioId,predioId,plantaId,body,auth,request);
 }
 @PostMapping("/{plantaId}/producciones") @IdempotentOperation
 @Operation(operationId="apappssPlantaProduccion",summary="Guardar un nuevo snapshot de producción anual opcional")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.Operacion>> produccion(@PathVariable Long plantaId,@RequestParam Long uotId,
  @RequestParam Long convenioId,@RequestParam Long predioId,@Valid @RequestBody E3WebTypes.Produccion body,
  @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return update("PRODUCCION",uotId,convenioId,predioId,plantaId,body,auth,request);
 }
 @PostMapping("/seguimientos/masivo") @IdempotentOperation
 @Operation(operationId="apappssPlantasSeguimientoMasivo",summary="Registrar una actuación común en las plantas seleccionadas")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.ResultadoMasivo>> seguimientoMasivo(
   @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,
   @RequestParam @Positive Long predioId,@Valid @RequestBody E3WebTypes.SeguimientoMasivo body,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return execute("MASIVO",uotId,convenioId,predioId,null,null,null,null,null,null,body,
   E3Models.BatchFollowUp.class,E3WebTypes.ResultadoMasivo.class,auth,request);
 }
 @GetMapping("/{plantaId}/mediciones")
 @Operation(operationId="apappssPlantaMediciones",summary="Consultar materia seca de una planta")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
 public ResponseEntity<ApiResponse<E3WebTypes.Mediciones>> mediciones(@PathVariable @Positive Long plantaId,
   @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,
   @RequestParam @Positive Long predioId,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return execute("MEDICIONES",uotId,convenioId,predioId,plantaId,null,null,null,null,null,null,
   E3Models.Measurements.class,E3WebTypes.Mediciones.class,auth,request);
 }
 @PostMapping("/{plantaId}/mediciones") @IdempotentOperation
 @Operation(operationId="apappssPlantaMedirMateriaSeca",summary="Registrar una medición de materia seca con visita autorizada")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.Operacion>> medir(@PathVariable @Positive Long plantaId,
   @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,
   @RequestParam @Positive Long predioId,@Valid @RequestBody E3WebTypes.Medicion body,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return update("MEDIR",uotId,convenioId,predioId,plantaId,body,auth,request);
 }
 @PostMapping("/{plantaId}/evidencias") @IdempotentOperation
 @Operation(operationId="apappssPlantaVincularEvidencia",summary="Asociar documento existente de predio a planta")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
 public ResponseEntity<ApiResponse<E3WebTypes.Operacion>> evidencia(@PathVariable Long plantaId,@RequestParam Long uotId,
  @RequestParam Long convenioId,@RequestParam Long predioId,@Valid @RequestBody E3WebTypes.Evidencia body,
  @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  return update("EVIDENCIA",uotId,convenioId,predioId,plantaId,body,auth,request);
 }
}
