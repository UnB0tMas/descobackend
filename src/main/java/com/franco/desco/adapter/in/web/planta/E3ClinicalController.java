package com.franco.desco.adapter.in.web.planta;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.adapter.out.persistence.planta.clinical.E3ClinicalOperation;
import com.franco.desco.application.shared.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Cada endpoint tiene una intención; cada implementación JDBC invoca un solo PA. */
@RestController
@RequestMapping("/api/v1/apappss/plantas/{plantaId}")
@Tag(name="Expediente fitosanitario de planta")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class E3ClinicalController {
    public record ComentarioRequest(@NotBlank @Size(max=1500) String comentario) {}
    public record EliminarRequest(@NotBlank @Size(min=5,max=1000) String motivo,@NotNull Long version) {}
    public record EnfermedadRequest(@NotNull @Positive Integer diagnosticoId,Instant inicio,@Size(max=1000) String observacion) {}
    public record EnfermedadEditarRequest(@Positive Integer diagnosticoId,@Size(max=1000) String observacion) {}
    public record RecuperarRequest(Instant fechaCuracion,@Size(max=600) String comentario) {}
    public record RetirarRequest(@NotBlank @Size(min=5,max=600) String motivo) {}
    public record TratamientoRequest(@NotNull @Positive Integer catalogoTratamientoId,Instant fechaAplicacion,
       @Size(max=600) String resultado,@Size(max=1000) String comentario) {}
    public record TratamientoEditarRequest(@NotNull @Positive Integer catalogoTratamientoId,
       @NotBlank @Pattern(regexp="\\d{4}-\\d{2}-\\d{2}") String fechaAplicacion,
       @Size(max=600) String resultado,@Size(max=1000) String comentario) {}
    private record TratamientoEditarDatos(Long tratamientoId,Integer catalogoTratamientoId,
       String fechaAplicacion,String resultado,String comentario) {}
    public record TratamientoArchivoRequest(@NotNull @Positive Long aplicacionId,@NotNull @Positive Long archivoId) {}

    private final Map<String,E3ClinicalOperation> operations;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    public E3ClinicalController(List<E3ClinicalOperation> repositories,ApiResponseFactory responses,
       JwtSessionIdentityResolver identities,ClientRequestContextResolver metadata) {
        this.operations=repositories.stream().collect(Collectors.toUnmodifiableMap(E3ClinicalOperation::key,Function.identity()));
        this.responses=responses;this.identities=identities;this.metadata=metadata;
    }
    private ResponseEntity<ApiResponse<Object>> run(String action,Long plantaId,Long episodioId,
       Long uotId,Long convenioId,Long predioId,Object body,JwtAuthenticationToken auth,HttpServletRequest request) {
        E3ClinicalOperation operation=operations.get(action);
        if(operation==null)throw new IllegalStateException("Operación no registrada");
        Long parcelaCultivoId=null;
        String parcela=request.getParameter("parcelaCultivoId");
        if(parcela!=null){
            try{parcelaCultivoId=Long.parseLong(parcela);}
            catch(NumberFormatException ex){throw new IllegalArgumentException("Parcela no válida");}
            if(parcelaCultivoId<=0)throw new IllegalArgumentException("Parcela no válida");
        }
        var value=operation.execute(uotId,convenioId,predioId,parcelaCultivoId,plantaId,episodioId,body,
            identities.resolve(auth),metadata.resolve(request));
        return responses.from(ApplicationResults.ok(value,"E3_OK","E3_ERROR",AppStatus.BAD_REQUEST),request);
    }
    @DeleteMapping @IdempotentOperation
    @Operation(operationId="apappssPlantaEliminar",summary="Eliminar lógicamente la planta sin confundirla con MUERTA")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> eliminar(@PathVariable @Positive Long plantaId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody EliminarRequest body,@Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request) {
        return run("eliminarPlanta",plantaId,null,uotId,convenioId,predioId,body,auth,request);
    }
    @PostMapping("/comentarios") @IdempotentOperation
    @Operation(operationId="apappssPlantaComentarioRegistrar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> comentario(@PathVariable @Positive Long plantaId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody ComentarioRequest body,@Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request){
        return run("registrarComentario",plantaId,null,uotId,convenioId,predioId,body,auth,request);
    }
    @GetMapping("/comentarios")
    @Operation(operationId="apappssPlantaComentariosListar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> comentarios(@PathVariable @Positive Long plantaId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return run("listarComentarios",plantaId,null,uotId,convenioId,predioId,null,auth,request);
    }
    @GetMapping("/enfermedades")
    @Operation(operationId="apappssPlantaEnfermedadesListar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> enfermedades(@PathVariable @Positive Long plantaId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return run("listarEnfermedades",plantaId,null,uotId,convenioId,predioId,null,auth,request);
    }
    @PostMapping("/enfermedades") @IdempotentOperation
    @Operation(operationId="apappssPlantaEnfermedadRegistrar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> registrar(@PathVariable @Positive Long plantaId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody EnfermedadRequest body,@Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request){
        return run("registrarEnfermedad",plantaId,null,uotId,convenioId,predioId,body,auth,request);
    }
    @GetMapping("/enfermedades/{episodioId}")
    @Operation(operationId="apappssPlantaEnfermedadDetalle")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> detalle(@PathVariable @Positive Long plantaId,@PathVariable @Positive Long episodioId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return run("detalleEnfermedad",plantaId,episodioId,uotId,convenioId,predioId,null,auth,request);
    }
    @PutMapping("/enfermedades/{episodioId}") @IdempotentOperation
    @Operation(operationId="apappssPlantaEnfermedadEditar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> editar(@PathVariable @Positive Long plantaId,@PathVariable @Positive Long episodioId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody EnfermedadEditarRequest body,@Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request){
        return run("editarEnfermedad",plantaId,episodioId,uotId,convenioId,predioId,body,auth,request);
    }
    @PostMapping("/enfermedades/{episodioId}/recuperar") @IdempotentOperation
    @Operation(operationId="apappssPlantaEnfermedadRecuperar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> recuperar(@PathVariable @Positive Long plantaId,@PathVariable @Positive Long episodioId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody RecuperarRequest body,@Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request){
        return run("recuperarEnfermedad",plantaId,episodioId,uotId,convenioId,predioId,body,auth,request);
    }
    @DeleteMapping("/enfermedades/{episodioId}") @IdempotentOperation
    @Operation(operationId="apappssPlantaEnfermedadEliminar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> eliminarEnfermedad(@PathVariable @Positive Long plantaId,@PathVariable @Positive Long episodioId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody RetirarRequest body,@Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request){
        return run("eliminarEnfermedad",plantaId,episodioId,uotId,convenioId,predioId,body,auth,request);
    }
    @GetMapping("/enfermedades/{episodioId}/tratamientos")
    @Operation(operationId="apappssPlantaTratamientosListar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> tratamientos(@PathVariable @Positive Long plantaId,@PathVariable @Positive Long episodioId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return run("listarTratamientos",plantaId,episodioId,uotId,convenioId,predioId,null,auth,request);
    }
    @PostMapping("/enfermedades/{episodioId}/tratamientos") @IdempotentOperation
    @Operation(operationId="apappssPlantaTratamientoRegistrar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> tratamiento(@PathVariable @Positive Long plantaId,@PathVariable @Positive Long episodioId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody TratamientoRequest body,@Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request){
        return run("registrarTratamiento",plantaId,episodioId,uotId,convenioId,predioId,body,auth,request);
    }
    @PutMapping("/enfermedades/{episodioId}/tratamientos/{tratamientoId}") @IdempotentOperation
    @Operation(operationId="apappssPlantaTratamientoEditar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR') and @permissionGuard.has(authentication,'APAPPSS_PLANTAS_TRATAMIENTO_LOTE')")
    public ResponseEntity<ApiResponse<Object>> editarTratamiento(@PathVariable @Positive Long plantaId,
       @PathVariable @Positive Long episodioId,@PathVariable @Positive Long tratamientoId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody TratamientoEditarRequest body,
       @Parameter(hidden=true) JwtAuthenticationToken auth,
       @Parameter(hidden=true) HttpServletRequest request){
        return run("editarTratamiento",plantaId,episodioId,uotId,convenioId,predioId,
          new TratamientoEditarDatos(tratamientoId,body.catalogoTratamientoId(),body.fechaAplicacion(),
           body.resultado(),body.comentario()),auth,request);
    }
    @GetMapping("/archivos")
    @Operation(operationId="apappssPlantaArchivosListar",summary="Archivos generales y evidencias de tratamientos")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> archivos(@PathVariable @Positive Long plantaId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return run("listarArchivos",plantaId,null,uotId,convenioId,predioId,null,auth,request);
    }
    @PostMapping("/enfermedades/{episodioId}/tratamientos/archivos") @IdempotentOperation
    @Operation(operationId="apappssPlantaTratamientoArchivoVincular",summary="Vincular un archivo del servidor a un tratamiento aplicado")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> vincularArchivoTratamiento(@PathVariable @Positive Long plantaId,
       @PathVariable @Positive Long episodioId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Valid @RequestBody TratamientoArchivoRequest body,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return run("vincularArchivoTratamiento",plantaId,episodioId,uotId,convenioId,predioId,body,auth,request);
    }
    @GetMapping("/analisis-fitosanitario")
    @Operation(operationId="apappssPlantaAnalisisFitosanitario")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> analisis(@PathVariable @Positive Long plantaId,
       @RequestParam @Positive Long uotId,@RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
       @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
        return run("analisisFitosanitario",plantaId,null,uotId,convenioId,predioId,null,auth,request);
    }
}
