package com.franco.desco.adapter.in.web.expediente;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.application.expediente.port.in.E1UseCase;
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
public class E1Controller {
    private final E1UseCase service;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identity;
    private final ClientRequestContextResolver context;
    private final E1WebMapper mapper;

    public E1Controller(E1UseCase service,ApiResponseFactory responses,JwtSessionIdentityResolver identity,
                        ClientRequestContextResolver context,E1WebMapper mapper) {
        this.service=service;this.responses=responses;this.identity=identity;this.context=context;this.mapper=mapper;
    }
    @GetMapping("/convenios")
    @Operation(operationId="expedientesConveniosListar",summary="Convenios APAPPSS habilitados para esta UOT")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Convenios>> convenios(@RequestParam @Positive Long uotId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return responses.from(service.listConvenios(new E1Commands.ListConvenios(uotId),
          identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @GetMapping("/personas")
    @Operation(operationId="expedientesPersonasBuscar",summary="Buscar personas registradas sin exigir condición de socio")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Personas>> personas(@RequestParam @Positive Long uotId,
      @RequestParam String buscar,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return responses.from(service.searchPersonas(new E1Commands.SearchPersonas(uotId,buscar),
          identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PostMapping("/personas") @IdempotentOperation
    @Operation(operationId="expedientesPersonaCrear",summary="Reutilizar persona por documento o registrar la mínima identidad")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> personaCrear(@RequestParam @Positive Long uotId,
      @Valid @RequestBody E1WebTypes.PersonaRequest q,@Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return responses.from(service.createPersona(new E1Commands.CreatePersona(uotId,mapper.persona(q)),
          identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @GetMapping("/predios")
    @Operation(operationId="expedientesPrediosListar",summary="Listar predios del ámbito autorizado")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Predios>> predios(@RequestParam @Positive Long uotId,
      @RequestParam(required=false) @Positive Long convenioId,@RequestParam(required=false) String buscar,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return responses.from(service.listPredios(new E1Commands.ListPredios(uotId,convenioId,buscar),
          identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PostMapping("/predios") @IdempotentOperation
    @Operation(operationId="expedientesPredioAltaRapida",summary="Crear o reutilizar fundo con titular persona")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> alta(@RequestParam @Positive Long uotId,
      @RequestParam(required=false) @Positive Long convenioId,@Valid @RequestBody E1WebTypes.PredioRequest q,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return responses.from(service.createPredio(new E1Commands.CreatePredio(uotId,convenioId,mapper.predio(q)),
          identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @GetMapping("/predios/{id}")
    @Operation(operationId="expedientesPredioDetalle",summary="Expediente mixto y cronología por ámbito")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Expediente>> expediente(@PathVariable Long id,@RequestParam @Positive Long uotId,
      @RequestParam(required=false) @Positive Long convenioId,@Parameter(hidden=true) JwtAuthenticationToken a,
      @Parameter(hidden=true) HttpServletRequest r){
      return responses.from(service.getExpediente(new E1Commands.GetExpediente(uotId,convenioId,id),
          identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @GetMapping("/catalogos")
    @Operation(operationId="expedientesCatalogos",summary="Catálogos de cultivos, variedades y especies pecuarias")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<ApiResponse<E1WebTypes.Catalogos>> catalogos(@RequestParam @Positive Long uotId,
      @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
      return responses.from(service.getCatalogos(new E1Commands.GetCatalogos(uotId),
          identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PostMapping("/predios/{id}/cultivos") @IdempotentOperation
    @Operation(operationId="expedientesCultivoAgregar",summary="Registrar cultivo genérico en parcela propia o nueva")
    @PreAuthorize("@permissionGuard.has(authentication,'CULTIVOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> cultivo(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.CultivoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return responses.from(service.addCultivo(new E1Commands.AddCultivo(uotId,convenioId,id,mapper.cultivo(q)),
           identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PostMapping("/predios/{id}/crianzas") @IdempotentOperation
    @Operation(operationId="expedientesCrianzaAgregar",summary="Registrar especie o lote pecuario")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> crianza(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.CrianzaRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return responses.from(service.addCrianza(new E1Commands.AddCrianza(uotId,convenioId,id,mapper.crianza(q)),
           identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PostMapping("/predios/{id}/conteos") @IdempotentOperation
    @Operation(operationId="expedientesConteoAgregar",summary="Anexar conteo pecuario histórico")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> conteo(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.ConteoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return responses.from(service.addConteo(new E1Commands.AddConteo(uotId,convenioId,id,mapper.conteo(q)),
           identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PostMapping("/predios/{id}/actuaciones") @IdempotentOperation
    @Operation(operationId="expedientesActuacionRegistrar",summary="Agregar actuación fechada e inmutable")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> actuacion(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.ActuacionRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return responses.from(service.addActuacion(new E1Commands.AddActuacion(uotId,convenioId,id,mapper.actuacion(q)),
           identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PutMapping("/predios/{id}/ficha") @IdempotentOperation
    @Operation(operationId="expedientesFichaCompletar",summary="Completar progresivamente características sin borrar versiones")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> ficha(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E1WebTypes.FichaRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return responses.from(service.completeFicha(new E1Commands.CompleteFicha(uotId,convenioId,id,mapper.ficha(q)),
           identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
    @PostMapping("/predios/{id}/convenio") @IdempotentOperation
    @Operation(operationId="expedientesVincularConvenio",summary="Vincular predio existente mediante socio vigente y convenio habilitado")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_CREAR')")
    public ResponseEntity<ApiResponse<E1WebTypes.Id>> vinculo(@PathVariable Long id,@RequestParam @Positive Long uotId,
       @RequestParam @Positive Long convenioId,@Valid @RequestBody E1WebTypes.VinculoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r){
       return responses.from(service.linkConvenio(new E1Commands.LinkConvenio(uotId,convenioId,id,
           new E1Commands.Vinculo(q.personaId())),identity.resolve(a),context.resolve(r)),r,mapper::response);
    }
}
