package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.fieldtrip.port.in.E2UseCase;
import com.franco.desco.domain.fieldtrip.E2Models;
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
import java.util.Map;

@RestController
@RequestMapping("/api/v1/salidas-operativas")
@Tag(name="Salidas operativas",description="Etapa 2: solicitudes, autorización, visitas, entrega y retorno auditables")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class E2Controller {
    private final E2UseCase service;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identity;
    private final ClientRequestContextResolver metadata;
    private final JsonMapper json;

    public E2Controller(E2UseCase service,ApiResponseFactory responses,
                        JwtSessionIdentityResolver identity,ClientRequestContextResolver metadata,JsonMapper json) {
        this.service=service;this.responses=responses;this.identity=identity;this.metadata=metadata;this.json=json;
    }
    private <S,T> ResponseEntity<ApiResponse<T>> perform(String action,Long uotId,Long convenioId,Long salidaId,
         String estado,Integer pagina,Integer tamano,Object datos,Class<S> domain,Class<T> dto,
         JwtAuthenticationToken auth,HttpServletRequest request) {
        return responses.from(service.execute(new E2Commands.Execute(action,uotId,convenioId,salidaId,estado,pagina,tamano,datos),
            identity.resolve(auth),metadata.resolve(request),domain),request,value->json.convertValue(value,dto));
    }
    private ResponseEntity<ApiResponse<E2WebTypes.Operacion>> mutate(String action,Long id,Long uotId,Long convenioId,
         Object body,JwtAuthenticationToken a,HttpServletRequest r) {
        return perform(action,uotId,convenioId,id,null,null,null,body,E2Models.Operation.class,E2WebTypes.Operacion.class,a,r);
    }
    @GetMapping
    @Operation(operationId="salidasOperativasListar",summary="Listar salidas por ámbito y estado")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_LISTAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Lista>> listar(@RequestParam @Positive Long uotId,
         @RequestParam(required=false) Long convenioId,@RequestParam(required=false) String estado,
         @RequestParam(defaultValue="1") @Min(1) Integer pagina,
         @RequestParam(defaultValue="20") @Min(1) @Max(100) Integer tamano,
         @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
        return perform("LISTAR",uotId,convenioId,null,estado,pagina,tamano,null,E2Models.ListResult.class,E2WebTypes.Lista.class,a,r);
    }
    @GetMapping("/catalogos")
    @Operation(operationId="salidasOperativasCatalogos",summary="Consultar motivos, tipos de visita y bienes disponibles")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_LISTAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Catalogos>> catalogos(@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return perform("CATALOGOS",uotId,convenioId,null,null,null,null,null,E2Models.Catalogs.class,E2WebTypes.Catalogos.class,a,r);
    }
    @GetMapping("/{id}")
    @Operation(operationId="salidasOperativasVer",summary="Ficha de salida con destinos, visitas, custodia e historial")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<E2WebTypes.Detalle>> ver(@PathVariable @Positive Long id,
       @RequestParam @Positive Long uotId,@RequestParam(required=false) Long convenioId,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return perform("VER",uotId,convenioId,id,null,null,null,null,E2Models.Detail.class,E2WebTypes.Detalle.class,a,r);
    }
    @PostMapping @IdempotentOperation
    @Operation(operationId="salidasOperativasSolicitar",summary="Crear y enviar una solicitud con varios destinos y bienes opcionales")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CREAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> solicitar(@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.SolicitudRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("SOLICITAR",null,uotId,convenioId,q,a,r);
    }
    @PostMapping("/{id}/corregir") @IdempotentOperation
    @Operation(operationId="salidasOperativasCorregir",summary="Reenviar solicitud observada")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> corregir(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.CorreccionRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("CORREGIR",id,uotId,convenioId,q,a,r);
    }
    @PostMapping("/{id}/decision") @IdempotentOperation
    @Operation(operationId="salidasOperativasDecidir",summary="Aprobar, observar o rechazar, con segregación")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> decidir(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.DecisionRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("DECIDIR",id,uotId,convenioId,q,a,r);
    }
    @PostMapping("/{id}/entregar") @IdempotentOperation
    @Operation(operationId="salidasOperativasEntregar",summary="Despacho físico concurrente de bienes solicitados")
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> entregar(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("ENTREGAR",id,uotId,convenioId,Map.of(),a,r);
    }
    @PostMapping("/{id}/iniciar") @IdempotentOperation
    @Operation(operationId="salidasOperativasIniciar",summary="Iniciar salida aprobada y con bienes entregados")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> iniciar(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("INICIAR",id,uotId,convenioId,Map.of(),a,r);
    }
    @PostMapping("/{id}/visitas") @IdempotentOperation
    @Operation(operationId="salidasOperativasVisitar",summary="Iniciar visita para destino y tipo de catálogo")
    @PreAuthorize("@permissionGuard.has(authentication,'VISITAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> visitar(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.VisitaRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("VISITAR",id,uotId,convenioId,q,a,r);
    }
    @PostMapping("/{id}/visitas/{visitaId}/finalizar") @IdempotentOperation
    @Operation(operationId="salidasOperativasVisitaFinalizar",summary="Finalizar visita y registrar actuación cronológica")
    @PreAuthorize("@permissionGuard.has(authentication,'VISITAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> finalizarVisita(@PathVariable Long id,@PathVariable Long visitaId,
       @RequestParam Long uotId,@RequestParam(required=false) Long convenioId,
       @Valid @RequestBody E2WebTypes.VisitaCierreRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("FINALIZAR_VISITA",id,uotId,convenioId,Map.of("visitaId",visitaId,"resumen",q.resumen()),a,r);
    }
    @PostMapping("/{id}/retorno") @IdempotentOperation
    @Operation(operationId="salidasOperativasRetornar",summary="Declarar retorno con una observación general y estado físico por bien")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> retornar(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.RetornoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("RETORNAR",id,uotId,convenioId,q,a,r);
    }
    @PostMapping("/{id}/inspeccion") @IdempotentOperation
    @Operation(operationId="salidasOperativasInspeccionar",summary="Visto bueno: solo los bienes conformes vuelven a disponibles")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> inspeccionar(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.InspeccionRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("INSPECCIONAR",id,uotId,convenioId,q,a,r);
    }
    @PostMapping("/{id}/cerrar") @IdempotentOperation
    @Operation(operationId="salidasOperativasCerrar",summary="Cerrar salida con retorno inspeccionado e incidencias retenidas")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_CONFIRMAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> cerrar(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("CERRAR",id,uotId,convenioId,Map.of(),a,r);
    }

    @PostMapping("/{id}/destinos/vincular") @IdempotentOperation
    @Operation(operationId="salidasOperativasVincularDestino",summary="Asociar predio registrado en campo al destino existente")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> vincularDestino(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.VincularDestinoRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("VINCULAR_DESTINO",id,uotId,convenioId,q,a,r);
    }
    @PostMapping("/{id}/cancelar-operativa") @IdempotentOperation
    @Operation(operationId="salidasOperativasCancelar",summary="Cancelar solicitud sin entrega física")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_RETIRAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> cancelar(@PathVariable Long id,@RequestParam Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.CancelarRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("CANCELAR",id,uotId,convenioId,q,a,r);
    }

}
