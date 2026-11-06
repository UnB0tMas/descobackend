package com.franco.desco.adapter.in.web.expediente;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.application.expediente.port.in.E1UseCase;
import com.franco.desco.domain.expediente.E1Models;
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

@RestController
@RequestMapping("/api/v1/expedientes-productivos")
@Tag(name="Expedientes productivos",description="Expediente productivo tradicional y ámbito controlado de convenio")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public final class E1Controller {
    private final E1UseCase service;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identity;
    private final ClientRequestContextResolver context;
    private final ObjectMapper mapper;

    public E1Controller(E1UseCase service,ApiResponseFactory responses,JwtSessionIdentityResolver identity,
                        ClientRequestContextResolver context,ObjectMapper mapper) {
        this.service=service;this.responses=responses;this.identity=identity;this.context=context;this.mapper=mapper;
    }
    private <S,T> ResponseEntity<ApiResponse<T>> perform(String action,Long uotId,Long convenioId,Long predioId,
        String buscar,Object datos,Class<S> domain,Class<T> web,JwtAuthenticationToken auth,HttpServletRequest request) {
        return responses.from(service.ejecutar(new E1Commands.Ejecutar(action,uotId,convenioId,predioId,buscar,datos),
          identity.resolve(auth),context.resolve(request),domain),request,value->mapper.convertValue(value,web));
    }
    private <T> ResponseEntity<ApiResponse<E1WebTypes.Id>> mutate(String action,Long uotId,Long convenioId,Long predioId,
        Object body,JwtAuthenticationToken auth,HttpServletRequest request){
        return perform(action,uotId,convenioId,predioId,null,body,E1Models.Identificador.class,E1WebTypes.Id.class,auth,request);
    }
    @GetMapping("/convenios")
    @Operation(operationId="expedientesConveniosListar",summary="Convenios APAPPSS habilitados para esta UOT")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Convenios>> convenios(@RequestParam @Positive Long uotId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return perform("CONVENIOS",uotId,null,null,null,null,E1Models.Convenios.class,E1WebTypes.Convenios.class,a,r);
    }
    @GetMapping("/personas")
    @Operation(operationId="expedientesPersonasBuscar",summary="Buscar personas registradas sin exigir condición de socio")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Personas>> personas(@RequestParam @Positive Long uotId,
      @RequestParam String buscar,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return perform("PERSONAS",uotId,null,null,buscar,null,E1Models.Personas.class,E1WebTypes.Personas.class,a,r);
    }
    @PostMapping("/personas") @IdempotentOperation
    @Operation(operationId="expedientesPersonaCrear",summary="Reutilizar persona por documento o registrar la mínima identidad")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> personaCrear(@RequestParam @Positive Long uotId,
      @Valid @RequestBody E1WebTypes.PersonaRequest q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return mutate("PERSONA_CREAR",uotId,null,null,q,a,r);
    }
    @GetMapping("/predios")
    @Operation(operationId="expedientesPrediosListar",summary="Listar predios del ámbito autorizado")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Predios>> predios(@RequestParam @Positive Long uotId,
      @RequestParam(required=false) @Positive Long convenioId,@RequestParam(required=false) String buscar,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return perform("PREDIOS",uotId,convenioId,null,buscar,null,E1Models.Predios.class,E1WebTypes.Predios.class,a,r);
    }
    @PostMapping("/predios") @IdempotentOperation
    @Operation(operationId="expedientesPredioAltaRapida",summary="Crear o reutilizar fundo con titular persona")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> alta(@RequestParam @Positive Long uotId,
      @RequestParam(required=false) @Positive Long convenioId,@Valid @RequestBody E1WebTypes.PredioRequest q,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return mutate("PREDIO_CREAR",uotId,convenioId,null,q,a,r);
    }
    @GetMapping("/predios/{id}")
    @Operation(operationId="expedientesPredioDetalle",summary="Expediente mixto y cronología por ámbito")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Expediente>> expediente(@PathVariable Long id,@RequestParam @Positive Long uotId,
      @RequestParam(required=false) @Positive Long convenioId,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r){
      return perform("EXPEDIENTE",uotId,convenioId,id,null,null,E1Models.Expediente.class,E1WebTypes.Expediente.class,a,r);
    }
    @GetMapping("/catalogos")
    @Operation(operationId="expedientesCatalogos",summary="Catálogos de cultivos, variedades y especies pecuarias")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Catalogos>> catalogos(@RequestParam @Positive Long uotId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return perform("CATALOGOS",uotId,null,null,null,null,E1Models.Catalogos.class,E1WebTypes.Catalogos.class,a,r);
    }
    @PostMapping("/predios/{id}/cultivos") @IdempotentOperation
    @Operation(operationId="expedientesCultivoAgregar",summary="Registrar cultivo genérico en parcela propia o nueva")
    @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> cultivo(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.CultivoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return mutate("CULTIVO_CREAR",uotId,convenioId,id,q,a,r);
    }
    @PostMapping("/predios/{id}/crianzas") @IdempotentOperation
    @Operation(operationId="expedientesCrianzaAgregar",summary="Registrar especie o lote pecuario")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> crianza(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.CrianzaRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return mutate("CRIANZA_CREAR",uotId,convenioId,id,q,a,r);
    }
    @PostMapping("/predios/{id}/conteos") @IdempotentOperation
    @Operation(operationId="expedientesConteoAgregar",summary="Anexar conteo pecuario histórico")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> conteo(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.ConteoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return mutate("CONTEO_CREAR",uotId,convenioId,id,q,a,r);
    }
    @PostMapping("/predios/{id}/actuaciones") @IdempotentOperation
    @Operation(operationId="expedientesActuacionRegistrar",summary="Agregar actuación fechada e inmutable")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> actuacion(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.ActuacionRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return mutate("ACTUACION_CREAR",uotId,convenioId,id,q,a,r);
    }
    @PutMapping("/predios/{id}/ficha") @IdempotentOperation
    @Operation(operationId="expedientesFichaCompletar",summary="Completar progresivamente características sin borrar versiones")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> ficha(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.FichaRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return mutate("FICHA_COMPLETAR",uotId,convenioId,id,q,a,r);
    }
    @PostMapping("/predios/{id}/convenio") @IdempotentOperation
    @Operation(operationId="expedientesVincularConvenio",summary="Vincular predio existente mediante socio vigente y convenio habilitado")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> vinculo(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam @Positive Long convenioId,@Valid @RequestBody E1WebTypes.VinculoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return mutate("AMBITO_VINCULAR",uotId,convenioId,id,q,a,r);
    }
}
