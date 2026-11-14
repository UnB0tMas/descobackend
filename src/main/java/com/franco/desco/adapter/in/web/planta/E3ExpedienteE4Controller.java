package com.franco.desco.adapter.in.web.planta;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.adapter.out.persistence.planta.E3ExpedienteE4SqlAdapter;
import com.franco.desco.application.shared.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
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

import java.math.BigDecimal;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDate;
import java.util.List;

/** Ampliación aditiva: no sustituye los endpoints E3 ni el catálogo de GP. */
@RestController
@RequestMapping("/api/v1/apappss")
@Tag(name="Expediente individual y materia seca APAPPSS")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class E3ExpedienteE4Controller {
    public record Nota(@NotBlank @Size(max=1500) String comentario) {}
    public record TratamientosLote(@NotEmpty @Size(max=20) List<@NotNull @Positive Integer> tratamientoIds,
            @NotNull LocalDate fechaAplicacion, @Size(max=1000) String comentario,
            @Size(max=600) String resultado) {}
    public record MateriaSecaIndividual(@NotNull @DecimalMin("0.001") @DecimalMax("100.000") BigDecimal porcentaje,
            @NotNull LocalDate fechaMuestreo, @Size(max=2000) String informe) {}
    public record MateriaSecaGlobal(@NotNull @DecimalMin("0.001") @DecimalMax("100.000") BigDecimal porcentaje,
            @NotNull @Positive Integer cantidadPlantas,
            @NotNull @Positive Integer cantidadFrutos,
            @NotBlank @Pattern(regexp="LABORATORIO|HORNO|MICROONDAS|NIR|OTRO") String metodo,
            @NotNull LocalDate fechaMuestreo, @NotBlank @Size(max=2000) String informe,
            @PositiveOrZero Long version, @Size(max=500) String motivoEdicion) {}
    public record MateriaSecaBaja(@NotNull @PositiveOrZero Long version,
            @NotBlank @Size(min=10,max=500) String motivo) {}

    private final E3ExpedienteE4SqlAdapter adapter;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;

    public E3ExpedienteE4Controller(E3ExpedienteE4SqlAdapter adapter, ApiResponseFactory responses,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata) {
        this.adapter = adapter;
        this.responses = responses;
        this.identities = identities;
        this.metadata = metadata;
    }

    private ResponseEntity<ApiResponse<Object>> run(String action, Long uotId, Long convenioId,
            Long predioId, Long plantaId, Long episodioId, Object body,
            JwtAuthenticationToken auth, HttpServletRequest request) {
        var result = adapter.execute(action, uotId, convenioId, predioId, plantaId, episodioId,
                body, identities.resolve(auth), metadata.resolve(request));
        return responses.from(ApplicationResults.ok(result,"E4_OK","E4_ERROR",AppStatus.BAD_REQUEST), request);
    }

    @GetMapping("/plantas/{plantaId}/enfermedades/{episodioId}/notas")
    @Operation(operationId="apappssE4EnfermedadNotasListar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> notas(@PathVariable @Positive Long plantaId,
            @PathVariable @Positive Long episodioId, @RequestParam @Positive Long uotId,
            @RequestParam @Positive Long convenioId, @RequestParam @Positive Long predioId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("NOTAS_LISTAR",uotId,convenioId,predioId,plantaId,episodioId,null,auth,request);
    }

    @PostMapping("/plantas/{plantaId}/enfermedades/{episodioId}/notas") @IdempotentOperation
    @Operation(operationId="apappssE4EnfermedadNotaRegistrar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR') and @permissionGuard.has(authentication,'APAPPSS_PLANTAS_SALUD_COMENTAR')")
    public ResponseEntity<ApiResponse<Object>> nota(@PathVariable @Positive Long plantaId,
            @PathVariable @Positive Long episodioId, @RequestParam @Positive Long uotId,
            @RequestParam @Positive Long convenioId, @RequestParam @Positive Long predioId,
            @Valid @RequestBody Nota body, @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("NOTA_REGISTRAR",uotId,convenioId,predioId,plantaId,episodioId,body,auth,request);
    }

    @PostMapping("/plantas/{plantaId}/enfermedades/{episodioId}/tratamientos/lote") @IdempotentOperation
    @Operation(operationId="apappssE4TratamientosLoteRegistrar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR') and @permissionGuard.has(authentication,'APAPPSS_PLANTAS_TRATAMIENTO_LOTE')")
    public ResponseEntity<ApiResponse<Object>> tratamientos(@PathVariable @Positive Long plantaId,
            @PathVariable @Positive Long episodioId, @RequestParam @Positive Long uotId,
            @RequestParam @Positive Long convenioId, @RequestParam @Positive Long predioId,
            @Valid @RequestBody TratamientosLote body, @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("TRATAMIENTOS_LOTE",uotId,convenioId,predioId,plantaId,episodioId,body,auth,request);
    }

    @GetMapping("/plantas/{plantaId}/materia-seca")
    @Operation(operationId="apappssE4MateriaSecaPlantaListar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> materiaPlanta(@PathVariable @Positive Long plantaId,
            @RequestParam @Positive Long uotId, @RequestParam @Positive Long convenioId,
            @RequestParam @Positive Long predioId, @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("SECA_PLANTA_LISTAR",uotId,convenioId,predioId,plantaId,null,null,auth,request);
    }

    @PostMapping("/plantas/{plantaId}/materia-seca") @IdempotentOperation
    @Operation(operationId="apappssE4MateriaSecaIndividualRegistrar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR') and @permissionGuard.has(authentication,'APAPPSS_PLANTAS_SECA_REGISTRAR')")
    public ResponseEntity<ApiResponse<Object>> materiaIndividual(@PathVariable @Positive Long plantaId,
            @RequestParam @Positive Long uotId, @RequestParam @Positive Long convenioId,
            @RequestParam @Positive Long predioId, @Valid @RequestBody MateriaSecaIndividual body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        throw new ResponseStatusException(HttpStatus.GONE,
                "La materia seca se registra exclusivamente desde el fundo.");
    }

    @GetMapping("/predios/{predioId}/materia-seca")
    @Operation(operationId="apappssE4MateriaSecaPredioListar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Object>> materiaPredio(@PathVariable @Positive Long predioId,
            @RequestParam @Positive Long uotId, @RequestParam @Positive Long convenioId,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("SECA_PREDIO_LISTAR",uotId,convenioId,predioId,null,null,null,auth,request);
    }

    @PostMapping("/predios/{predioId}/materia-seca") @IdempotentOperation
    @Operation(operationId="apappssE4MateriaSecaGlobalRegistrar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR') and @permissionGuard.has(authentication,'APAPPSS_PREDIOS_SECA_LOTE')")
    public ResponseEntity<ApiResponse<Object>> materiaGlobal(@PathVariable @Positive Long predioId,
            @RequestParam @Positive Long uotId, @RequestParam @Positive Long convenioId,
            @Valid @RequestBody MateriaSecaGlobal body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("SECA_GLOBAL",uotId,convenioId,predioId,null,null,body,auth,request);
    }

    @PutMapping("/predios/{predioId}/materia-seca/{informeId}") @IdempotentOperation
    @Operation(operationId="apappssE4MateriaSecaGlobalEditar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR') and @permissionGuard.has(authentication,'APAPPSS_PREDIOS_SECA_EDITAR')")
    public ResponseEntity<ApiResponse<Object>> editarMateriaGlobal(@PathVariable @Positive Long predioId,
            @PathVariable @Positive Long informeId, @RequestParam @Positive Long uotId,
            @RequestParam @Positive Long convenioId, @Valid @RequestBody MateriaSecaGlobal body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("SECA_GLOBAL_EDITAR",uotId,convenioId,predioId,null,null,
                java.util.Map.of("informeId",informeId,"version",body.version()==null?-1L:body.version(),
                        "porcentaje",body.porcentaje(),"cantidadPlantas",body.cantidadPlantas(),
                        "cantidadFrutos",body.cantidadFrutos(),"metodo",body.metodo(),
                        "fechaMuestreo",body.fechaMuestreo(),"informe",body.informe(),
                        "motivoEdicion",body.motivoEdicion()==null?"":body.motivoEdicion()),auth,request);
    }

    @DeleteMapping("/predios/{predioId}/materia-seca/{informeId}") @IdempotentOperation
    @Operation(operationId="apappssE4MateriaSecaGlobalEliminar")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR') and @permissionGuard.has(authentication,'APAPPSS_PREDIOS_SECA_ELIMINAR')")
    public ResponseEntity<ApiResponse<Object>> eliminarMateriaGlobal(@PathVariable @Positive Long predioId,
            @PathVariable @Positive Long informeId, @RequestParam @Positive Long uotId,
            @RequestParam @Positive Long convenioId, @Valid @RequestBody MateriaSecaBaja body,
            @Parameter(hidden=true) JwtAuthenticationToken auth,
            @Parameter(hidden=true) HttpServletRequest request) {
        return run("SECA_GLOBAL_ELIMINAR",uotId,convenioId,predioId,null,null,
                java.util.Map.of("informeId",informeId,"version",body.version(),"motivo",body.motivo()),auth,request);
    }

}
