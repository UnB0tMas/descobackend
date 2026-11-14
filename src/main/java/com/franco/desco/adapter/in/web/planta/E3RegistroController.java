package com.franco.desco.adapter.in.web.planta;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.adapter.out.persistence.planta.registro.E3RegistroPersistence;
import com.franco.desco.application.shared.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/apappss/plantas")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class E3RegistroController {
 public record AltaIndividual(@NotNull @Positive Long variedadId,@Positive Long socioId,
    @PastOrPresent LocalDate fechaPlantacion,@Min(0) @Max(200) Integer edadReferenciaAnios,
    @Size(max=1000) String observacion) {}
 public record EstadoInicial(Long totalHistorico,Boolean puedeCargaInicial) {}
 public record Creada(Long plantaId,String codigo,String estado) {}
 private final E3RegistroPersistence repo;
 private final ApiResponseFactory respuestas;
 private final JwtSessionIdentityResolver identidad;
 private final ClientRequestContextResolver contexto;
 public E3RegistroController(E3RegistroPersistence repo,ApiResponseFactory respuestas,
   JwtSessionIdentityResolver identidad,ClientRequestContextResolver contexto){
  this.repo=repo;this.respuestas=respuestas;this.identidad=identidad;this.contexto=contexto;
 }
 @GetMapping("/alta-inicial")
 @Operation(operationId="apappssPlantasEstadoAltaInicial",summary="Verificar si el predio admite una carga masiva inicial")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
 public ResponseEntity<ApiResponse<EstadoInicial>> inicial(@RequestParam @Positive Long uotId,
   @RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  var r=repo.ejecutar("prod.PA_E3_Planta_Sel_AltaInicial",uotId,convenioId,predioId,
    null,identidad.resolve(auth),contexto.resolve(request),EstadoInicial.class);
  return respuestas.from(ApplicationResults.ok(r,"E3_OK","E3_ERROR",AppStatus.BAD_REQUEST),request);
 }
 @PostMapping("/individuales") @IdempotentOperation
 @Operation(operationId="apappssPlantaCrearIndividual",summary="Registrar una planta nueva individualmente")
 @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_CREAR')")
 public ResponseEntity<ApiResponse<Creada>> crear(@RequestParam @Positive Long uotId,
   @RequestParam @Positive Long convenioId,@RequestParam @Positive Long predioId,
   @Valid @RequestBody AltaIndividual body,
   @Parameter(hidden=true) JwtAuthenticationToken auth,@Parameter(hidden=true) HttpServletRequest request){
  var r=repo.ejecutar("prod.PA_E3_Planta_Ins_Individual",uotId,convenioId,predioId,
    body,identidad.resolve(auth),contexto.resolve(request),Creada.class);
  return respuestas.from(ApplicationResults.created(r,"E3_OK","E3_ERROR"),request);
 }
}
