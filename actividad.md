# DESCO — ETAPA 2 — actividad.md (backend)

## Resumen de propósito
Etapa 2 DESCO/APAPPSS: flujo de solicitud, aprobación, entrega física, visitas, retorno, inspección y cierre.
Se conserva la información histórica y el kardex existente.

## Pasos de validación
1. Ejecutar `--simular` con el reemplazador de cada proyecto.
2. Aplicar backend, resolver previamente colisiones Flyway existentes y ejecutar las nuevas migraciones.
3. Levantar el backend, regenerar OpenAPI Angular con la configuración del proyecto y aplicar frontend.
4. Compilar y ejecutar pruebas; verificar T05, T06, T07, 3 destinos, permisos y reintentos contra SQL Server real.

## Advertencia de migraciones vigentes
La exportación contiene **dos `V439` y dos `V440`** con nombres diferentes. Flyway exigirá resolver esa colisión a partir del historial real de despliegues antes de ejecutar `V441`; este parche no renombra ni altera V previas.

## Mapa de archivos afectados
`src/main/java/com/franco/desco/application/fieldtrip/port/out/E2PersistencePort.java`, `src/main/java/com/franco/desco/adapter/out/persistence/fieldtrip/E2SqlServerAdapter.java`, `src/test/java/com/franco/desco/adapter/in/web/fieldtrip/E2WebValidationTest.java`, `src/test/java/com/franco/desco/adapter/out/persistence/fieldtrip/E2SqlServerAdapterTest.java`, `src/main/java/com/franco/desco/adapter/in/web/fieldtrip/E2WebTypes.java`, `src/main/java/com/franco/desco/adapter/in/web/fieldtrip/E2Controller.java`, `src/main/resources/db/migration/V441__CP_campo.PA_SalidaOperativaE2_Refuerzo.sql`, `src/test/resources/sql/etapa2_refuerzo_invariantes.sql`

## Contratos OpenAPI y sincronización

| Backend controlador / esquema | operationId | Angular generado | Adaptador consumidor |
|---|---|---|---|
| `E2Controller.solicitar / E2SolicitudRequest` | `salidasOperativasSolicitar` | `SalidasOperativasService.salidasOperativasSolicitar / E2SolicitudRequest` | `salidas-e2-http.adapter.ts` |
| `E2Controller.corregir / E2CorreccionRequest` | `salidasOperativasCorregir` | `SalidasOperativasService.salidasOperativasCorregir / E2CorreccionRequest` | mismo adaptador |
| `E2Controller.regularizarFin / E2FechaFinRequest` | `salidasOperativasRegularizarFin` | `SalidasOperativasService.salidasOperativasRegularizarFin / E2FechaFinRequest` | mismo adaptador |
| `E2Controller.listar/ver/catalogos / E2SalidasResponse, E2SalidaDetalleResponse, E2CatalogosResponse` | `salidasOperativasListar`, `salidasOperativasVer`, `salidasOperativasCatalogos` | `SalidasOperativasService`, modelos E2 existentes | mismo adaptador |
| `E2Controller.decidir, entregar, iniciar, visitar, finalizarVisita, retornar, inspeccionar, cerrar, vincularDestino, cancelar` | `salidasOperativasDecidir`, `salidasOperativasEntregar`, `salidasOperativasIniciar`, `salidasOperativasVisitar`, `salidasOperativasVisitaFinalizar`, `salidasOperativasRetornar`, `salidasOperativasInspeccionar`, `salidasOperativasCerrar`, `salidasOperativasVincularDestino`, `salidasOperativasCancelar` | `SalidasOperativasService` y los modelos E2 vigentes | mismo adaptador |

## Operaciones completas

Ruta: `src/main/java/com/franco/desco/application/fieldtrip/port/out/E2PersistencePort.java`
Contenido: completo
```java
package com.franco.desco.application.fieldtrip.port.out;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface E2PersistencePort {
    <T> PersistenceResult<T> execute(
            E2Commands.Execute command,
            SessionIdentity identity,
            RequestMetadata metadata,
            Class<T> resultType
    );
}
```

Ruta: `src/main/java/com/franco/desco/adapter/out/persistence/fieldtrip/E2SqlServerAdapter.java`
Contenido: completo
```java
package com.franco.desco.adapter.out.persistence.fieldtrip;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.fieldtrip.port.out.E2PersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

/** E2 solo ejecuta su PA: ninguna transición de inventario se replica en Java. */
@Repository
public final class E2SqlServerAdapter implements E2PersistencePort {
    private static final String PROCEDURE = "{call campo.PA_SalidaOperativaE2_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public E2SqlServerAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public <T> PersistenceResult<T> execute(E2Commands.Execute command,
                                            SessionIdentity identity,
                                            RequestMetadata metadata,
                                            Class<T> resultType) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null) {
            return PersistenceResult.error("E2_SESION_INVALIDA", "La sesión no está disponible.", 401);
        }
        Map<String, Object> contexto = new LinkedHashMap<>();
        contexto.put("sesionPublicaId", identity.sesionPublicaId());
        contexto.put("correlacionId", metadata.correlacionId());
        contexto.put("solicitudId", metadata.solicitudId());
        contexto.put("claveIdempotencia", metadata.claveIdempotencia());
        contexto.put("ip", metadata.ip());
        contexto.put("endpoint", metadata.endpoint());
        contexto.put("userAgent", metadata.userAgent());
        contexto.put("deviceId", metadata.deviceId());

        Map<String, Object> filtros = new LinkedHashMap<>();
        filtros.put("uotId", command.uotId());
        filtros.put("convenioId", command.convenioId());
        filtros.put("salidaId", command.salidaId());
        filtros.put("estado", command.estado());
        filtros.put("pagina", command.pagina());
        filtros.put("tamano", command.tamano());

        Map<String, Object> peticion = new LinkedHashMap<>();
        peticion.put("contexto", contexto);
        peticion.put("filtros", filtros);
        peticion.put("datos", command.datos() == null ? Map.of() : command.datos());
        String payload = json.writeValueAsString(peticion);
        try {
            return jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(PROCEDURE);
                statement.setString(1, command.accion());
                statement.setNString(2, payload);
                statement.registerOutParameter(3, Types.LONGNVARCHAR);
                statement.registerOutParameter(4, Types.BIT);
                statement.registerOutParameter(5, Types.NVARCHAR);
                statement.registerOutParameter(6, Types.VARCHAR);
                statement.registerOutParameter(7, Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                statement.execute();
                String raw = statement.getNString(3);
                boolean success = statement.getBoolean(4);
                String message = statement.getNString(5);
                String code = statement.getString(6);
                int http = statement.getInt(7);
                if (!success) {
                    return PersistenceResult.error(code, message, http == 0 ? 400 : http);
                }
                T value = (raw == null || raw.isBlank()) ? null : json.readValue(raw, resultType);
                return PersistenceResult.ok(code, message, http == 0 ? 200 : http, value);
            });
        } catch (DataAccessException ex) {
            return PersistenceResult.error("E2_BD_NO_DISPONIBLE",
                    "La operación no pudo completarse en este momento.", 503);
        }
    }
}
```

Ruta: `src/test/java/com/franco/desco/adapter/in/web/fieldtrip/E2WebValidationTest.java`
Contenido: completo
```java
package com.franco.desco.adapter.in.web.fieldtrip;

import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

class E2WebValidationTest {
    private static final Instant NOV_1 = Instant.parse("2026-11-01T08:00:00Z");
    private static final Instant OCT_31 = Instant.parse("2026-10-31T20:00:00Z");

    @Test void noPermiteFinPrevistoAnteriorAlInicio() {
        var request = new E2WebTypes.SolicitudRequest("Salida",1,NOV_1,OCT_31,null,
                List.of(new E2WebTypes.DestinoRequest(null,"Sector Norte")),List.of());
        assertThat(request.isFechasValidas()).isFalse();
    }
    @Test void permiteFinOpcionalYDestinoNoRegistrado() {
        var request = new E2WebTypes.SolicitudRequest("Salida",1,NOV_1,null,null,
                List.of(new E2WebTypes.DestinoRequest(null,"Sector Norte")),List.of());
        assertThat(request.isFechasValidas()).isTrue();
        assertThat(request.destinos().getFirst().isValido()).isTrue();
    }
    @Test void correccionTambienValidaOrdenDeFechas() {
        var correction = new E2WebTypes.CorreccionRequest("Revisada",null,1,NOV_1,OCT_31,
                List.of(new E2WebTypes.DestinoRequest(null,"Fundo")),List.of());
        assertThat(correction.isFechasValidas()).isFalse();
    }
    @Test void lasDecisionesDesfavorablesExigenMotivo() {
        assertThat(new E2WebTypes.DecisionRequest("RECHAZADA",null).isMotivoValido()).isFalse();
        assertThat(new E2WebTypes.DecisionRequest("OBSERVADA","Revisar destino").isMotivoValido()).isTrue();
        assertThat(new E2WebTypes.DecisionRequest("APROBADA",null).isMotivoValido()).isTrue();
    }
}
```

Ruta: `src/test/java/com/franco/desco/adapter/out/persistence/fieldtrip/E2SqlServerAdapterTest.java`
Contenido: completo
```java
package com.franco.desco.adapter.out.persistence.fieldtrip;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class E2SqlServerAdapterTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final E2SqlServerAdapter adapter = new E2SqlServerAdapter(jdbc,new JsonMapper());

    @Test void nuncaInvocaSqlSinSesionPublicaValida() {
        var identity = new SessionIdentity(3L,null,1,"jwt");
        var meta = new RequestMetadata(UUID.randomUUID(),UUID.randomUUID(),UUID.randomUUID(),
                "127.0.0.1","/api/v1/salidas-operativas","test","test","test","test");
        var command = new E2Commands.Execute("DECIDIR",1L,null,2L,null,null,null,null);
        var result = adapter.execute(command,identity,meta,String.class);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.httpSugerido()).isEqualTo(401);
        verifyNoInteractions(jdbc);
    }
}
```

Ruta: `src/main/java/com/franco/desco/adapter/in/web/fieldtrip/E2WebTypes.java`
Contenido: completo
```java
package com.franco.desco.adapter.in.web.fieldtrip;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.List;

public final class E2WebTypes {
    private E2WebTypes() {}
    @Schema(name="E2DestinoRequest")
    public record DestinoRequest(@Positive Long predioId, @Size(max=250) String referencia) {
        @AssertTrue(message="Indique un predio o una referencia de destino")
        @Schema(hidden=true)
        public boolean isValido() { return predioId != null || referencia != null && !referencia.isBlank(); }
    }
    @Schema(name="E2BienRequest")
    public record BienRequest(@NotNull @Positive Long bienId) {}
    @Schema(name="E2SolicitudRequest")
    public record SolicitudRequest(@NotBlank @Size(max=180) String nombre,
          @NotNull @Positive Integer motivoSalidaId, @NotNull Instant fechaInicioPrevista,
          Instant fechaFinPrevista, @Size(max=400) String descripcion,
          @NotEmpty List<@Valid DestinoRequest> destinos,
          List<@Valid BienRequest> bienes) {
        @AssertTrue(message="La fecha final debe ser posterior a la inicial") @Schema(hidden=true)
        public boolean isFechasValidas() { return fechaInicioPrevista != null &&
                   (fechaFinPrevista == null || !fechaFinPrevista.isBefore(fechaInicioPrevista)); }
    }
    @Schema(name="E2FechaFinRequest")
    public record FechaFinRequest(@NotNull Instant fechaFinPrevista) {}
    @Schema(name="E2VincularDestinoRequest")
    public record VincularDestinoRequest(@NotNull @Positive Long destinoId,@NotNull @Positive Long predioId) {}
    @Schema(name="E2CancelarRequest")
    public record CancelarRequest(@NotBlank @Size(max=1200) String motivo) {}
    @Schema(name="E2DecisionRequest")
    public record DecisionRequest(@NotBlank @Pattern(regexp="APROBADA|OBSERVADA|RECHAZADA") String decision,
              @Size(max=1200) String motivo) {
        @AssertTrue(message="Las observaciones y rechazos requieren motivo") @Schema(hidden=true)
        public boolean isMotivoValido() { return "APROBADA".equals(decision) || motivo != null && !motivo.isBlank(); }
    }
    @Schema(name="E2CorreccionRequest")
    public record CorreccionRequest(@NotBlank @Size(max=180) String nombre,
          @Size(max=400) String descripcion,
          Integer motivoSalidaId, Instant fechaInicioPrevista, Instant fechaFinPrevista,
          List<@Valid DestinoRequest> destinos, List<@Valid BienRequest> bienes) {
        @AssertTrue(message="Las fechas de la corrección no son coherentes") @Schema(hidden=true)
        public boolean isFechasValidas() { return fechaInicioPrevista == null || fechaFinPrevista == null ||
                !fechaFinPrevista.isBefore(fechaInicioPrevista); }
    }
    @Schema(name="E2VisitaRequest")
    public record VisitaRequest(@NotNull @Positive Long destinoId,@NotNull @Positive Integer tipoVisitaId,
          @Size(max=250) String objetivo) {}
    @Schema(name="E2VisitaCierreRequest")
    public record VisitaCierreRequest(@NotBlank @Size(max=600) String resumen) {}
    @Schema(name="E2EstadoBienRequest")
    public record EstadoBienRequest(@NotNull @Positive Long solicitudRecursoId,
         @NotBlank @Pattern(regexp="CONFORME|DANADO|FALTANTE") String resultado,
         @Size(max=500) String observacion) {}
    @Schema(name="E2RetornoRequest")
    public record RetornoRequest(@NotBlank @Size(max=1500) String observacionGeneral,
             @NotNull List<@Valid EstadoBienRequest> bienes) {}
    @Schema(name="E2InspeccionRequest")
    public record InspeccionRequest(@Size(max=1200) String observacion,
             @NotNull List<@Valid EstadoBienRequest> bienes) {}

    @Schema(name="E2OperacionResponse")
    public record Operacion(Long salidaId,Long visitaId,String estado) {}
    @Schema(name="E2OpcionResponse")
    public record Opcion(Long id,String nombre,String codigo) {}
    @Schema(name="E2CatalogosResponse")
    public record Catalogos(List<Opcion> motivos,List<Opcion> tiposVisita,List<Opcion> bienes) {}
    @Schema(name="E2SalidaResumenResponse")
    public record Resumen(Long salidaId,String nombre,String estado,Instant fechaSolicitud,
           Instant fechaFinPrevista,Instant fechaInicioPrevista,Long solicitanteEmpleadoId) {}
    @Schema(name="E2SalidasResponse")
    public record Lista(Long total,List<Resumen> items) {}
    @Schema(name="E2DestinoResponse")
    public record Destino(Long destinoId,Long predioId,String referencia,Integer orden) {}
    @Schema(name="E2BienResponse")
    public record Bien(Long solicitudRecursoId,Long bienId,String nombre,String estado,
      String resultadoDeclarado,String resultadoValidado,String observacion) {}
    @Schema(name="E2VisitaResponse")
    public record Visita(Long visitaId,Long predioId,Instant fechaInicio,Instant fechaFin,String estado,
                         String objetivo,String resumen,String tipoVisita) {}
    @Schema(name="E2EventoResponse")
    public record Evento(Long eventoId,String tipo,String detalle,Long usuarioId,Instant fechaHora) {}
    @Schema(name="E2SalidaDetalleResponse")
    public record Detalle(Long salidaId,String nombre,String estado,Long uotId,Long convenioId,
           Long solicitanteEmpleadoId,Instant fechaSolicitud,Integer motivoSalidaId,
           String descripcion,Instant fechaInicioPrevista,Instant fechaFinPrevista,
           Instant fechaInicioReal,Instant fechaFinReal,Instant fechaAprobacion,
           List<Destino> destinos,List<Bien> bienes,List<Visita> visitas,
           List<Evento> historial,String observacionRetorno) {}
}
```

Ruta: `src/main/java/com/franco/desco/adapter/in/web/fieldtrip/E2Controller.java`
Contenido: completo
```java
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
    @PostMapping("/{id}/fecha-fin") @IdempotentOperation
    @Operation(operationId="salidasOperativasRegularizarFin",summary="Regularizar fin previsto antes de cerrar")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_EDITAR')")
    public ResponseEntity<ApiResponse<E2WebTypes.Operacion>> regularizarFin(
       @PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
       @RequestParam(required=false) Long convenioId,@Valid @RequestBody E2WebTypes.FechaFinRequest q,
       @Parameter(hidden=true) JwtAuthenticationToken a,@Parameter(hidden=true) HttpServletRequest r) {
       return mutate("REGULARIZAR_FIN",id,uotId,convenioId,q,a,r);
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
```

Ruta: `src/main/resources/db/migration/V441__CP_campo.PA_SalidaOperativaE2_Refuerzo.sql`
Contenido: completo
```sql
-- E2. PA de coordinación, permisos efectivos, serialización, auditoría e idempotencia.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE campo.PA_SalidaOperativaE2_Ejecutar
 @cAccion VARCHAR(35),@cJson NVARCHAR(MAX),
 @cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
 @cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',@cCodigoRespuesta='E2_ERROR',@nHttpRespuesta=400;
 DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
   @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
   @bAuth BIT,@cAuth NVARCHAR(300),@uot BIGINT,@convenio BIGINT,@salida BIGINT,
   @permiso VARCHAR(40),@key UNIQUEIDENTIFIER,@hash VARBINARY(32),@hashPrev VARBINARY(32),
   @anterior NVARCHAR(MAX),@estado VARCHAR(24),@solicitante BIGINT,@socio BIT,
   @inicio DATETIME2(0),@fin DATETIME2(0),@motivo INT,@nombre NVARCHAR(180),@descripcion NVARCHAR(400),
   @obs NVARCHAR(1500),@detalle NVARCHAR(1200),@decision VARCHAR(25),@bien BIGINT,@recurso BIGINT,
   @id BIGINT,@predio BIGINT,@destino BIGINT,@tipo INT,@visita BIGINT,@cnt INT,@estadoBien VARCHAR(24),
   @fecha DATETIME2(0)=SYSUTCDATETIME(),
   @nombreAnterior NVARCHAR(180),@descripcionAnterior NVARCHAR(400);
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN('LISTAR','VER','CATALOGOS','SOLICITAR','DECIDIR','ENTREGAR','INICIAR','VISITAR','FINALIZAR_VISITA','RETORNAR','INSPECCIONAR','CERRAR','CORREGIR','CANCELAR','VINCULAR_DESTINO','REGULARIZAR_FIN') RETURN;
 SELECT @uot=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
        @salida=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.salidaId')),
        @convenio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
        @key=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia'));
 SET @permiso=CASE WHEN @cAccion IN('LISTAR','CATALOGOS') THEN 'SALIDAS_LISTAR'
       WHEN @cAccion='VER' THEN 'SALIDAS_VER'
       WHEN @cAccion='SOLICITAR' THEN 'SALIDAS_CREAR'
       WHEN @cAccion IN('DECIDIR','INSPECCIONAR','CERRAR') THEN 'SALIDAS_CONFIRMAR'
       WHEN @cAccion='ENTREGAR' THEN 'RECURSOS_CREAR'
       WHEN @cAccion='VISITAR' THEN 'VISITAS_EDITAR'
       WHEN @cAccion='CANCELAR' THEN 'SALIDAS_RETIRAR'
       WHEN @cAccion='FINALIZAR_VISITA' THEN 'VISITAS_CONFIRMAR'
       ELSE 'SALIDAS_EDITAR' END;
 BEGIN TRY
 EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@permiso,
    @nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,
    @gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bAuth OUTPUT,@cAuth OUTPUT;
 IF ISNULL(@bAuth,0)<>1 THROW 51060,N'El usuario no tiene permiso para esta operación.',1;
 IF @uot IS NULL OR @uot<1 OR seg.FN_Usuario_TienePermisoUOT(@nUsuario,@uot,@permiso)<>1
    THROW 51060,N'No tiene permiso en la unidad territorial indicada.',1;
 IF @convenio IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion C
    WHERE C.convenio_uot_organizacion_id=@convenio AND C.uot_id=@uot AND C.estado=1
    AND EXISTS(SELECT 1 FROM org.ConvenioModuloEspecial CM
          JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id
            AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
          WHERE CM.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND CM.estado=1)
    AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(DATE,@fecha))
    AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(DATE,@fecha)))
    THROW 51060,N'El convenio no está vigente en esta unidad territorial.',1;
 IF @convenio IS NOT NULL AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,@uot,'APAPPSS_PREDIOS_VER')<>1
    THROW 51060,N'No tiene acceso al convenio indicado.',1;
 IF @cAccion='CATALOGOS'
 BEGIN
    SET @cDatos=(SELECT JSON_QUERY((SELECT motivo_salida_id id,nombre FROM campo.MotivoSalida WHERE estado=1 ORDER BY nombre FOR JSON PATH)) motivos,
      JSON_QUERY((SELECT tipo_visita_id id,nombre FROM campo.TipoVisitaE2 WHERE estado=1 ORDER BY nombre FOR JSON PATH)) tiposVisita,
      JSON_QUERY((SELECT bien_inventario_id id,nombre,codigo_patrimonial codigo FROM logistica.BienInventario B
       WHERE B.uot_id=@uot AND B.estado=1 AND B.estado_bien='DISPONIBLE'
         AND NOT EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
          JOIN campo.SalidaE2 E ON E.salida_campo_id=R.salida_campo_id
          WHERE R.bien_inventario_id=B.bien_inventario_id
           AND R.estado IN('SOLICITADO','ENTREGADO')
           AND E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO'))
         AND NOT EXISTS(SELECT 1 FROM logistica.RecursoProgramado RP
          WHERE RP.bien_inventario_id=B.bien_inventario_id AND RP.estado=1
           AND RP.estado_proceso IN('PROGRAMADO','EN_EJECUCION'))
         ORDER BY B.nombre FOR JSON PATH)) bienes
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SET @bResultado=1;
 END
 ELSE IF @cAccion='LISTAR'
 BEGIN
   DECLARE @pagina INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.pagina')),1),
           @tamano INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.tamano')),20),
           @fEstado VARCHAR(24)=JSON_VALUE(@cJson,'$.filtros.estado');
   IF @pagina<1 OR @tamano<1 OR @tamano>100 THROW 51061,N'Paginación inválida.',1;
   SET @cDatos=(SELECT (SELECT COUNT_BIG(*) FROM campo.SalidaE2 E WHERE E.uot_id=@uot
      AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio)
      AND (@fEstado IS NULL OR E.estado=@fEstado)) total,
      JSON_QUERY((SELECT E.salida_campo_id salidaId,E.nombre,E.estado,CONVERT(VARCHAR(19),E.fecha_solicitud,126)+'Z' fechaSolicitud,
          CASE WHEN E.fecha_fin_prevista IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fecha_fin_prevista,126)+'Z' END fechaFinPrevista,CONVERT(VARCHAR(19),S.fecha_hora_programada,126)+'Z' fechaInicioPrevista,
          E.solicitante_empleado_id solicitanteEmpleadoId
        FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
        WHERE E.uot_id=@uot AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio)
        AND (@fEstado IS NULL OR E.estado=@fEstado)
        ORDER BY E.fecha_solicitud DESC,E.salida_campo_id DESC
        OFFSET (@pagina-1)*@tamano ROWS FETCH NEXT @tamano ROWS ONLY FOR JSON PATH)) items
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   SET @bResultado=1;
 END
 ELSE
 BEGIN
   IF @cAccion<>'SOLICITAR'
   BEGIN
      SELECT @estado=E.estado,@solicitante=E.solicitante_empleado_id
      FROM campo.SalidaE2 E WHERE E.salida_campo_id=@salida AND E.uot_id=@uot
        AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio);
      IF @estado IS NULL THROW 51062,N'Salida no disponible en su ámbito.',1;
   END;
   IF @cAccion='VER'
   BEGIN
       SET @cDatos=(SELECT E.salida_campo_id salidaId,E.nombre,E.estado,E.uot_id uotId,E.convenio_id convenioId,
         E.solicitante_empleado_id solicitanteEmpleadoId,CONVERT(VARCHAR(19),E.fecha_solicitud,126)+'Z' fechaSolicitud,
         S.motivo_salida_id motivoSalidaId,S.descripcion,CONVERT(VARCHAR(19),S.fecha_hora_programada,126)+'Z' fechaInicioPrevista,
         CASE WHEN E.fecha_fin_prevista IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fecha_fin_prevista,126)+'Z' END fechaFinPrevista,CASE WHEN S.fecha_hora_salida_real IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),S.fecha_hora_salida_real,126)+'Z' END fechaInicioReal,
         CASE WHEN S.fecha_hora_retorno_real IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),S.fecha_hora_retorno_real,126)+'Z' END fechaFinReal,CASE WHEN E.fecha_aprobacion IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),E.fecha_aprobacion,126)+'Z' END fechaAprobacion,
         JSON_QUERY((SELECT D.destino_id destinoId,D.predio_id predioId,D.referencia,D.orden
             FROM campo.SalidaDestinoE2 D WHERE D.salida_campo_id=@salida ORDER BY D.orden FOR JSON PATH)) destinos,
         JSON_QUERY((SELECT R.solicitud_recurso_id solicitudRecursoId,R.bien_inventario_id bienId,B.nombre,
             R.estado,R.resultado_declarado resultadoDeclarado,R.resultado_validado resultadoValidado,R.observacion
             FROM campo.SalidaRecursoE2 R JOIN logistica.BienInventario B ON B.bien_inventario_id=R.bien_inventario_id
             WHERE R.salida_campo_id=@salida FOR JSON PATH)) bienes,
         JSON_QUERY((SELECT V.visita_tecnica_id visitaId,V.predio_id predioId,CONVERT(VARCHAR(19),V.fecha_hora_inicio,126)+'Z' fechaInicio,
             CASE WHEN V.fecha_hora_fin IS NULL THEN NULL ELSE CONVERT(VARCHAR(19),V.fecha_hora_fin,126)+'Z' END fechaFin,V.estado_proceso estado,V.objetivo,V.resumen,T.nombre tipoVisita
             FROM campo.VisitaTecnica V JOIN campo.SalidaVisitaE2 X ON X.visita_tecnica_id=V.visita_tecnica_id
             JOIN campo.TipoVisitaE2 T ON T.tipo_visita_id=X.tipo_visita_id
             JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
             WHERE D.salida_campo_id=@salida ORDER BY V.visita_tecnica_id FOR JSON PATH)) visitas,
         JSON_QUERY((SELECT H.evento_id eventoId,H.tipo,H.detalle,H.usuario_id usuarioId,CONVERT(VARCHAR(19),H.fecha_hora,126)+'Z' fechaHora
             FROM campo.SalidaEventoE2 H WHERE H.salida_campo_id=@salida ORDER BY H.evento_id DESC FOR JSON PATH)) historial,
         (SELECT observacion_general FROM campo.SalidaRetornoE2 WHERE salida_campo_id=@salida) observacionRetorno
       FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id WHERE E.salida_campo_id=@salida
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
       SET @bResultado=1;
   END
   ELSE
   BEGIN
     IF @key IS NULL THROW 51063,N'Falta la clave de idempotencia.',1;
     SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',ISNULL(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',ISNULL(JSON_QUERY(@cJson,'$.datos'),N'')));
     BEGIN TRANSACTION;
     DECLARE @locked INT;
     DECLARE @recursoLock NVARCHAR(255)=CONCAT(N'DESCO:E2:',@nUsuario,N':',@cAccion,N':',CONVERT(NVARCHAR(36),@key));
     EXEC @locked=sys.sp_getapplock @Resource=@recursoLock,
       @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
     IF @locked<0 THROW 51064,N'La solicitud está siendo procesada.',1;
     SELECT @hashPrev=hash_peticion,@anterior=respuesta FROM campo.SalidaOperacionE2 WITH(UPDLOCK,HOLDLOCK)
      WHERE usuario_id=@nUsuario AND tipo=@cAccion AND idempotencia=@key;
     IF @hashPrev IS NOT NULL
     BEGIN
         IF @hashPrev<>@hash THROW 51065,N'La clave ya fue utilizada con otros datos.',1;
         SET @cDatos=@anterior;SET @bResultado=1;
     END
     ELSE
     BEGIN
       IF @cAccion<>'SOLICITAR'
       BEGIN
         SELECT @estado=E.estado,@solicitante=E.solicitante_empleado_id
         FROM campo.SalidaE2 E WITH(UPDLOCK,HOLDLOCK)
         WHERE E.salida_campo_id=@salida AND E.uot_id=@uot
           AND ((@convenio IS NULL AND E.convenio_id IS NULL) OR E.convenio_id=@convenio);
         IF @estado IS NULL THROW 51062,N'Salida no disponible en su ámbito.',1;
       END;
       IF @cAccion='SOLICITAR'
       BEGIN
         SELECT @nombre=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.nombre'))),N''),
           @motivo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.motivoSalidaId')),
           @inicio=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaInicioPrevista')),
           @fin=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaFinPrevista')),
           @descripcion=JSON_VALUE(@cJson,'$.datos.descripcion');
         IF @nEmp IS NULL OR @nombre IS NULL OR @motivo IS NULL OR @inicio IS NULL OR @fin<@inicio
           THROW 51066,N'Complete nombre, motivo, fecha inicial y fechas coherentes.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.MotivoSalida WHERE motivo_salida_id=@motivo AND estado=1)
           THROW 51066,N'Motivo no válido.',1;
         IF NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos'))
           THROW 51066,N'Agregue al menos un destino.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos') WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia') D
           WHERE (D.predioId IS NULL AND NULLIF(TRIM(D.referencia),N'') IS NULL) OR
            (D.predioId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=D.predioId
              AND A.uot_id=@uot AND A.estado=1 AND ((@convenio IS NULL AND A.convenio_uot_organizacion_id IS NULL) OR A.convenio_uot_organizacion_id=@convenio))))
           THROW 51066,N'Uno de los predios no pertenece al ámbito de la salida.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(bienId BIGINT '$.bienId') B
           LEFT JOIN logistica.BienInventario I ON I.bien_inventario_id=B.bienId WHERE B.bienId IS NULL OR I.uot_id<>@uot OR I.estado<>1)
           THROW 51066,N'Uno de los bienes no pertenece a esta UOT.',1;
         IF EXISTS(SELECT bienId FROM OPENJSON(@cJson,'$.datos.bienes') WITH(bienId BIGINT '$.bienId') GROUP BY bienId HAVING COUNT(*)>1)
           THROW 51066,N'No duplique bienes en la misma solicitud.',1;
         INSERT campo.SalidaCampo(motivo_salida_id,fecha_hora_programada,descripcion,estado_proceso,uot_id,estado)
          VALUES(@motivo,@inicio,@descripcion,'PROGRAMADA',@uot,1);
         SET @salida=CONVERT(BIGINT,SCOPE_IDENTITY());
         INSERT campo.SalidaE2(salida_campo_id,nombre,solicitante_empleado_id,uot_id,convenio_id,fecha_fin_prevista)
         VALUES(@salida,@nombre,@nEmp,@uot,@convenio,@fin);
         INSERT campo.SalidaParticipante(salida_campo_id,empleado_id,es_responsable,funcion,estado)
          VALUES(@salida,@nEmp,1,N'Responsable',1);
         INSERT campo.SalidaDestinoE2(salida_campo_id,predio_id,referencia,orden)
          SELECT @salida,predioId,referencia,CONVERT(INT,[key])+1 FROM OPENJSON(@cJson,'$.datos.destinos') J
          CROSS APPLY OPENJSON(J.value) WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia');
         INSERT campo.SalidaRecursoE2(salida_campo_id,bien_inventario_id)
          SELECT @salida,TRY_CONVERT(BIGINT,JSON_VALUE(value,'$.bienId')) FROM OPENJSON(@cJson,'$.datos.bienes');
         SET @estado='SOLICITADA';
       END
       ELSE IF @cAccion='CORREGIR'
       BEGIN
          IF @estado NOT IN('OBSERVADA','RECHAZADA') OR @solicitante<>@nEmp
              THROW 51066,N'Solo el solicitante puede corregir una solicitud observada o rechazada.',1;
          SELECT @nombre=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
              @detalle=JSON_VALUE(@cJson,'$.datos.descripcion'),
              @motivo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.motivoSalidaId')),
              @inicio=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaInicioPrevista')),
              @fin=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaFinPrevista'));
          IF @nombre IS NULL THROW 51066,N'Ingrese un nombre para la solicitud.',1;
          SELECT @nombreAnterior=E.nombre,@descripcionAnterior=S.descripcion
            FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
            WHERE E.salida_campo_id=@salida;
          IF @motivo IS NOT NULL AND NOT EXISTS(SELECT 1 FROM campo.MotivoSalida WHERE motivo_salida_id=@motivo AND estado=1)
              THROW 51066,N'El motivo de salida no es válido.',1;
          IF @inicio IS NOT NULL OR @fin IS NOT NULL
          BEGIN
            SELECT @inicio=COALESCE(@inicio,S.fecha_hora_programada),@fin=COALESCE(@fin,E.fecha_fin_prevista)
            FROM campo.SalidaCampo S JOIN campo.SalidaE2 E ON E.salida_campo_id=S.salida_campo_id
            WHERE S.salida_campo_id=@salida;
            IF @fin IS NOT NULL AND @fin<@inicio THROW 51066,N'La fecha final es anterior al inicio.',1;
          END;
          IF JSON_QUERY(@cJson,'$.datos.destinos') IS NOT NULL
          BEGIN
            IF NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos'))
               THROW 51066,N'Agregue al menos un destino.',1;
            IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.destinos')
              WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia') D
              WHERE (D.predioId IS NULL AND NULLIF(TRIM(D.referencia),N'') IS NULL)
                 OR (D.predioId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM prod.PredioAmbito A
                    WHERE A.predio_id=D.predioId AND A.uot_id=@uot AND A.estado=1 AND
                     ((@convenio IS NULL AND A.convenio_uot_organizacion_id IS NULL)
                      OR A.convenio_uot_organizacion_id=@convenio))))
               THROW 51060,N'Hay un predio fuera del ámbito de la salida.',1;
            DELETE FROM campo.SalidaDestinoE2 WHERE salida_campo_id=@salida;
            INSERT campo.SalidaDestinoE2(salida_campo_id,predio_id,referencia,orden)
              SELECT @salida,D.predioId,D.referencia,CONVERT(INT,J.[key])+1
              FROM OPENJSON(@cJson,'$.datos.destinos') J
              CROSS APPLY OPENJSON(J.value) WITH(predioId BIGINT '$.predioId',referencia NVARCHAR(250) '$.referencia') D;
          END;
          IF JSON_QUERY(@cJson,'$.datos.bienes') IS NOT NULL
          BEGIN
            IF EXISTS(SELECT B.bienId FROM OPENJSON(@cJson,'$.datos.bienes') WITH(bienId BIGINT '$.bienId') B
                GROUP BY B.bienId HAVING COUNT(*)>1) THROW 51066,N'No repita bienes.',1;
            IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(bienId BIGINT '$.bienId') B
              LEFT JOIN logistica.BienInventario I ON I.bien_inventario_id=B.bienId
              WHERE B.bienId IS NULL OR I.uot_id<>@uot OR I.estado<>1)
               THROW 51060,N'Hay un bien fuera de la UOT.',1;
            DELETE FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado='SOLICITADO';
            INSERT campo.SalidaRecursoE2(salida_campo_id,bien_inventario_id)
              SELECT @salida,B.bienId FROM OPENJSON(@cJson,'$.datos.bienes') WITH(bienId BIGINT '$.bienId') B;
          END;
          UPDATE campo.SalidaE2 SET nombre=@nombre,estado='SOLICITADA',fecha_solicitud=@fecha,
              fecha_fin_prevista=COALESCE(@fin,fecha_fin_prevista) WHERE salida_campo_id=@salida;
          UPDATE campo.SalidaCampo SET descripcion=@detalle,
              motivo_salida_id=COALESCE(@motivo,motivo_salida_id),
              fecha_hora_programada=COALESCE(@inicio,fecha_hora_programada)
              WHERE salida_campo_id=@salida;
          SET @estado='SOLICITADA';
       END
       ELSE IF @cAccion='CANCELAR'
       BEGIN
          SET @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivo')),N'');
          IF @estado NOT IN('SOLICITADA','OBSERVADA','RECHAZADA') OR @solicitante<>@nEmp OR @detalle IS NULL
            THROW 51066,N'No es posible cancelar esta salida o falta el motivo.',1;
          UPDATE campo.SalidaE2 SET estado='CANCELADA' WHERE salida_campo_id=@salida;
          UPDATE campo.SalidaCampo SET estado_proceso='CANCELADA' WHERE salida_campo_id=@salida;
          SET @estado='CANCELADA';
       END
       ELSE IF @cAccion='VINCULAR_DESTINO'
       BEGIN
         SET @destino=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.destinoId'));
         SET @predio=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.predioId'));
         IF @estado NOT IN('APROBADA','EN_EJECUCION') OR @solicitante<>@nEmp
            THROW 51066,N'El destino solo puede vincularse durante una salida aprobada.',1;
         IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND uot_id=@uot AND estado=1
             AND ((@convenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@convenio))
            THROW 51060,N'El predio no pertenece a su ámbito.',1;
         UPDATE campo.SalidaDestinoE2 SET predio_id=@predio WHERE destino_id=@destino
           AND salida_campo_id=@salida AND predio_id IS NULL;
         IF @@ROWCOUNT<>1 THROW 51066,N'El destino no está disponible para vincular.',1;
       END
       ELSE IF @cAccion='DECIDIR'
       BEGIN
         SET @decision=UPPER(JSON_VALUE(@cJson,'$.datos.decision'));
         SET @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivo')),N'');
         IF @estado<>'SOLICITADA' OR @decision NOT IN('APROBADA','OBSERVADA','RECHAZADA')
           THROW 51066,N'La solicitud no admite esta decisión.',1;
         IF @solicitante=@nEmp THROW 51060,N'El solicitante no puede aprobar su propia salida.',1;
         IF @decision<>'APROBADA' AND @detalle IS NULL THROW 51066,N'Debe indicar el motivo.',1;
         IF @decision='APROBADA'
         BEGIN
           DECLARE @reservaLock INT;
           EXEC @reservaLock=sys.sp_getapplock
              @Resource=CONCAT(N'DESCO:E2:UOT:',@uot),@LockMode='Exclusive',
              @LockOwner='Transaction',@LockTimeout=5000;
           IF @reservaLock<0 THROW 51064,N'Hay una aprobación concurrente. Reintente.',1;
           IF EXISTS (SELECT 1 FROM campo.SalidaRecursoE2 R
                JOIN logistica.BienInventario B WITH(UPDLOCK,HOLDLOCK)
                  ON B.bien_inventario_id=R.bien_inventario_id
                WHERE R.salida_campo_id=@salida AND (B.estado<>1 OR B.estado_bien<>'DISPONIBLE'
                 OR EXISTS(SELECT 1 FROM logistica.RecursoProgramado RP WITH(UPDLOCK,HOLDLOCK)
                   WHERE RP.bien_inventario_id=R.bien_inventario_id AND RP.estado=1
                   AND RP.estado_proceso IN('PROGRAMADO','EN_EJECUCION'))
                 OR EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 X WITH(UPDLOCK,HOLDLOCK)
                   JOIN campo.SalidaE2 T ON T.salida_campo_id=X.salida_campo_id
                   WHERE X.bien_inventario_id=R.bien_inventario_id AND X.salida_campo_id<>@salida
                     AND X.estado IN('SOLICITADO','ENTREGADO')
                     AND T.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO'))))
              THROW 51067,N'Un bien ya está reservado o prestado para otra salida.',1;
         END;
         UPDATE campo.SalidaE2 SET estado=@decision,usuario_aprobador=@nUsuario,
              fecha_aprobacion=CASE WHEN @decision='APROBADA' THEN @fecha ELSE NULL END WHERE salida_campo_id=@salida;
         SET @estado=@decision;
       END
       ELSE IF @cAccion='ENTREGAR'
       BEGIN
         IF @estado<>'APROBADA' THROW 51066,N'Apruebe la solicitud antes de entregar bienes.',1;
         DECLARE @entregaLock INT;
         EXEC @entregaLock=sys.sp_getapplock
             @Resource=CONCAT(N'DESCO:E2:UOT:',@uot),@LockMode='Exclusive',
             @LockOwner='Transaction',@LockTimeout=5000;
         IF @entregaLock<0 THROW 51064,N'Hay una entrega concurrente. Reintente.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R
           JOIN campo.SalidaRecursoE2 X ON X.bien_inventario_id=R.bien_inventario_id
             AND X.salida_campo_id<>R.salida_campo_id AND X.estado IN('SOLICITADO','ENTREGADO')
           JOIN campo.SalidaE2 T ON T.salida_campo_id=X.salida_campo_id
             AND T.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO')
           WHERE R.salida_campo_id=@salida)
           THROW 51067,N'Hay un bien reservado por otra salida.',1;
         DECLARE c_bienes CURSOR LOCAL FAST_FORWARD FOR
          SELECT R.solicitud_recurso_id,R.bien_inventario_id FROM campo.SalidaRecursoE2 R
          WHERE R.salida_campo_id=@salida AND R.estado='SOLICITADO' ORDER BY R.solicitud_recurso_id;
         OPEN c_bienes; FETCH NEXT FROM c_bienes INTO @id,@bien;
         WHILE @@FETCH_STATUS=0
         BEGIN
           IF NOT EXISTS(SELECT 1 FROM logistica.BienInventario WITH(UPDLOCK,HOLDLOCK)
             WHERE bien_inventario_id=@bien AND uot_id=@uot AND estado=1 AND estado_bien='DISPONIBLE')
              THROW 51067,N'Un bien ya no está disponible para entrega.',1;
           INSERT logistica.RecursoProgramado(salida_campo_id,bien_inventario_id,cantidad_programada,estado_proceso,estado,usuario_programacion_id)
            VALUES(@salida,@bien,1,'PROGRAMADO',1,@nUsuario);
           SET @recurso=CONVERT(BIGINT,SCOPE_IDENTITY());
           UPDATE logistica.BienInventario SET estado_bien='ASIGNADO' WHERE bien_inventario_id=@bien AND estado_bien='DISPONIBLE';
           IF @@ROWCOUNT<>1 THROW 51067,N'El bien fue asignado en otra salida.',1;
           UPDATE logistica.RecursoProgramado SET estado_proceso='EN_EJECUCION' WHERE recurso_programado_id=@recurso;
           UPDATE campo.SalidaRecursoE2 SET recurso_programado_id=@recurso,estado='ENTREGADO' WHERE solicitud_recurso_id=@id;
           INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
            VALUES(@recurso,'ASIGNACION',1,@nUsuario,N'Entrega física de salida E2');
           FETCH NEXT FROM c_bienes INTO @id,@bien;
         END;
         CLOSE c_bienes; DEALLOCATE c_bienes;
       END
       ELSE IF @cAccion='INICIAR'
       BEGIN
         IF @estado<>'APROBADA' OR @solicitante<>@nEmp THROW 51066,N'Salida no aprobada o usuario distinto del responsable.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado<>'ENTREGADO')
           THROW 51066,N'Falta confirmar la entrega física de los bienes solicitados.',1;
         UPDATE campo.SalidaE2 SET estado='EN_EJECUCION' WHERE salida_campo_id=@salida;
         UPDATE campo.SalidaCampo SET estado_proceso='EN_CURSO',fecha_hora_salida_real=@fecha WHERE salida_campo_id=@salida;
         SET @estado='EN_EJECUCION';
       END
       ELSE IF @cAccion='VISITAR'
       BEGIN
         IF @estado<>'EN_EJECUCION' THROW 51066,N'La salida no está en ejecución.',1;
         SELECT @destino=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.destinoId')),
            @tipo=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.tipoVisitaId')),
            @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.objetivo')),N'');
         SELECT @predio=D.predio_id FROM campo.SalidaDestinoE2 D WHERE D.destino_id=@destino AND D.salida_campo_id=@salida;
         IF @predio IS NULL THROW 51066,N'Registre o vincule un predio al destino antes de iniciar la visita.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.TipoVisitaE2 WHERE tipo_visita_id=@tipo AND estado=1) THROW 51066,N'Tipo de visita no válido.',1;
         IF NOT EXISTS(SELECT 1 FROM prod.PredioAmbito WHERE predio_id=@predio AND uot_id=@uot AND estado=1
             AND ((@convenio IS NULL AND convenio_uot_organizacion_id IS NULL) OR convenio_uot_organizacion_id=@convenio))
           THROW 51060,N'El predio no pertenece al contexto de salida.',1;
         DECLARE @part BIGINT=(SELECT TOP 1 salida_participante_id FROM campo.SalidaParticipante WHERE salida_campo_id=@salida AND empleado_id=@nEmp AND estado=1);
         IF @part IS NULL THROW 51060,N'El usuario no participa en esta salida.',1;
         DECLARE @pos GEOGRAPHY;
         SELECT @pos=U.posicion FROM prod.Predio P JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
           WHERE P.predio_id=@predio;
         INSERT campo.VisitaTecnica(salida_participante_id,predio_id,fecha_hora_inicio,posicion_inicio,objetivo,estado_proceso,estado)
           VALUES(@part,@predio,@fecha,@pos,@detalle,'INICIADA',1);
         SET @visita=CONVERT(BIGINT,SCOPE_IDENTITY());
         INSERT campo.SalidaVisitaE2(visita_tecnica_id,destino_id,tipo_visita_id) VALUES(@visita,@destino,@tipo);
       END
       ELSE IF @cAccion='FINALIZAR_VISITA'
       BEGIN
         SET @visita=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.visitaId'));
         SET @detalle=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.resumen')),N'');
         IF @estado<>'EN_EJECUCION' OR @detalle IS NULL THROW 51066,N'Ingrese qué se hizo durante la visita.',1;
         SELECT @predio=V.predio_id FROM campo.VisitaTecnica V WITH(UPDLOCK,HOLDLOCK)
         JOIN campo.SalidaVisitaE2 X ON X.visita_tecnica_id=V.visita_tecnica_id
         JOIN campo.SalidaDestinoE2 D ON D.destino_id=X.destino_id
         JOIN campo.SalidaParticipante P ON P.salida_participante_id=V.salida_participante_id
         WHERE V.visita_tecnica_id=@visita AND D.salida_campo_id=@salida AND V.estado_proceso='INICIADA' AND P.empleado_id=@nEmp;
         IF @predio IS NULL THROW 51066,N'Visita no disponible.',1;
         UPDATE campo.VisitaTecnica SET resumen=@detalle,fecha_hora_fin=@fecha,estado_proceso='FINALIZADA' WHERE visita_tecnica_id=@visita;
         INSERT prod.ExpedienteActuacion(predio_id,uot_id,convenio_uot_organizacion_id,tipo,observacion,fecha_hecho,
           usuario_id,salida_campo_id,visita_tecnica_id,correlacion_id)
           VALUES(@predio,@uot,@convenio,'SEGUIMIENTO',@detalle,@fecha,@nUsuario,@salida,@visita,@gCorr);
       END
       ELSE IF @cAccion='RETORNAR'
       BEGIN
         SET @obs=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacionGeneral')),N'');
         IF @estado<>'EN_EJECUCION' OR @solicitante<>@nEmp OR @obs IS NULL
            THROW 51066,N'Ingrese una observación general antes de retornar.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaDestinoE2 D JOIN campo.SalidaVisitaE2 X ON X.destino_id=D.destino_id
                 JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
                 WHERE D.salida_campo_id=@salida AND V.estado_proceso='INICIADA')
           THROW 51066,N'Finalice las visitas abiertas antes del retorno.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO'
           AND NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') J
               WHERE J.solicitudRecursoId=R.solicitud_recurso_id)) THROW 51066,N'Declare el estado de cada bien.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado') J
            LEFT JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=J.solicitudRecursoId AND R.salida_campo_id=@salida
            WHERE R.solicitud_recurso_id IS NULL OR J.resultado NOT IN('CONFORME','DANADO','FALTANTE'))
           THROW 51066,N'Estado de recurso inválido.',1;
         INSERT campo.SalidaRetornoE2(salida_campo_id,observacion_general,usuario_id) VALUES(@salida,@obs,@nUsuario);
         UPDATE R SET resultado_declarado=J.resultado,observacion=J.observacion
         FROM campo.SalidaRecursoE2 R JOIN OPENJSON(@cJson,'$.datos.bienes')
          WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado',observacion NVARCHAR(500) '$.observacion') J
          ON J.solicitudRecursoId=R.solicitud_recurso_id WHERE R.salida_campo_id=@salida;
         UPDATE campo.SalidaE2 SET estado='EN_RETORNO',fecha_retorno_declarado=@fecha WHERE salida_campo_id=@salida;
         UPDATE campo.SalidaCampo SET fecha_hora_retorno_real=@fecha WHERE salida_campo_id=@salida;
         SET @estado='EN_RETORNO';
       END
       ELSE IF @cAccion='INSPECCIONAR'
       BEGIN
         IF @estado<>'EN_RETORNO' OR @solicitante=@nEmp THROW 51066,N'El visto bueno requiere un inspector distinto del solicitante.',1;
         IF EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 R WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO'
          AND NOT EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId') J
          WHERE J.solicitudRecursoId=R.solicitud_recurso_id)) THROW 51066,N'Inspeccione todos los bienes pendientes.',1;
         IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.bienes') WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado') J
          LEFT JOIN campo.SalidaRecursoE2 R ON R.solicitud_recurso_id=J.solicitudRecursoId AND R.salida_campo_id=@salida AND R.estado='ENTREGADO'
          WHERE R.solicitud_recurso_id IS NULL OR J.resultado NOT IN('CONFORME','DANADO','FALTANTE')) THROW 51066,N'Inspección inválida.',1;
         DECLARE c_validar CURSOR LOCAL FAST_FORWARD FOR
          SELECT R.solicitud_recurso_id,R.recurso_programado_id,J.resultado
          FROM campo.SalidaRecursoE2 R JOIN OPENJSON(@cJson,'$.datos.bienes')
          WITH(solicitudRecursoId BIGINT '$.solicitudRecursoId',resultado VARCHAR(24) '$.resultado') J
           ON J.solicitudRecursoId=R.solicitud_recurso_id WHERE R.salida_campo_id=@salida AND R.estado='ENTREGADO';
         OPEN c_validar;FETCH NEXT FROM c_validar INTO @id,@recurso,@estadoBien;
         WHILE @@FETCH_STATUS=0
         BEGIN
           UPDATE campo.SalidaRecursoE2 SET estado=CASE WHEN @estadoBien='CONFORME' THEN 'VALIDADO' ELSE 'INCIDENCIA' END,
              resultado_validado=@estadoBien,fecha_validacion=@fecha,usuario_validacion=@nUsuario WHERE solicitud_recurso_id=@id;
           IF @estadoBien='CONFORME'
             INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,usuario_id,observacion)
               VALUES(@recurso,'DEVOLUCION',1,@nUsuario,N'Devolución conforme y validada E2');
           FETCH NEXT FROM c_validar INTO @id,@recurso,@estadoBien;
         END;
         CLOSE c_validar; DEALLOCATE c_validar;
       END
       ELSE IF @cAccion='REGULARIZAR_FIN'
       BEGIN
         SET @fin=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.datos.fechaFinPrevista'));
         SELECT @inicio=S.fecha_hora_programada FROM campo.SalidaCampo S WHERE S.salida_campo_id=@salida;
         IF @estado<>'EN_RETORNO' OR @fin IS NULL OR @fin<@inicio OR @solicitante<>@nEmp
           THROW 51066,N'Solo el solicitante puede regularizar la fecha prevista antes del cierre.',1;
         UPDATE campo.SalidaE2 SET fecha_fin_prevista=@fin WHERE salida_campo_id=@salida;
       END
       ELSE IF @cAccion='CERRAR'
       BEGIN
         IF @estado<>'EN_RETORNO' OR EXISTS(SELECT 1 FROM campo.SalidaRecursoE2 WHERE salida_campo_id=@salida AND estado='ENTREGADO')
           THROW 51066,N'Inspeccione todos los recursos antes de cerrar.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.SalidaRetornoE2 WHERE salida_campo_id=@salida) THROW 51066,N'Retorno pendiente.',1;
         IF NOT EXISTS(SELECT 1 FROM campo.SalidaE2 E JOIN campo.SalidaCampo S
             ON S.salida_campo_id=E.salida_campo_id WHERE E.salida_campo_id=@salida
             AND E.fecha_fin_prevista IS NOT NULL AND S.fecha_hora_retorno_real IS NOT NULL
             AND S.fecha_hora_retorno_real>=S.fecha_hora_salida_real)
             THROW 51066,N'Regularice la fecha final y registre el retorno antes de cerrar.',1;
         UPDATE campo.SalidaE2 SET estado='CERRADA',fecha_cierre=@fecha WHERE salida_campo_id=@salida;
         UPDATE campo.SalidaCampo SET estado_proceso='FINALIZADA' WHERE salida_campo_id=@salida;
         SET @estado='CERRADA';
       END;
       SET @detalle=CASE WHEN @cAccion='RETORNAR' THEN @obs WHEN @cAccion='DECIDIR' THEN JSON_VALUE(@cJson,'$.datos.motivo')
          WHEN @cAccion='INSPECCIONAR' THEN JSON_VALUE(@cJson,'$.datos.observacion')
          WHEN @cAccion='FINALIZAR_VISITA' THEN @detalle
          WHEN @cAccion='CANCELAR' THEN @detalle
          WHEN @cAccion='CORREGIR' THEN LEFT(CONCAT(N'Nombre anterior: ',@nombreAnterior,N' | Descripción anterior: ',
             COALESCE(@descripcionAnterior,N''),N' | Nombre nuevo: ',@nombre,N' | Descripción nueva: ',COALESCE(@detalle,N'')),1200)
          WHEN @cAccion='REGULARIZAR_FIN' THEN CONCAT(N'Fecha final prevista regularizada: ',CONVERT(NVARCHAR(30),@fin,126))
          WHEN @cAccion='VINCULAR_DESTINO' THEN CONCAT(N'Destino ',@destino,N' vinculado a predio ',@predio)
          WHEN @cAccion='VISITAR' THEN CONCAT(N'Inicio de visita ',@visita,N', destino ',@destino,N', tipo ',@tipo)
          ELSE NULL END;
       DECLARE @auditId BIGINT,@transitionId BIGINT,@ident NVARCHAR(200)=CONVERT(NVARCHAR(200),@salida);
       EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
         @nUsuarioId=@nUsuario,@nSesionUsuarioId=@nSesion,@nDispositivoUsuarioId=@nDisp,@nModuloId=@nModulo,
         @cAccion=@cAccion,@cEsquemaEntidad=N'campo',@cNombreEntidad=N'SalidaCampo',@cIdentificador=@ident,
         @cIp=@cIp,@gCorrelacionId=@gCorr,@gSolicitudId=@gSol,@cEndpoint=@cEnd,
         @nAuditoriaEventoId=@auditId OUTPUT,@nTransicionEstadoId=@transitionId OUTPUT;
       INSERT campo.SalidaEventoE2(salida_campo_id,tipo,detalle,usuario_id,correlacion_id)
        VALUES(@salida,@cAccion,@detalle,@nUsuario,@gCorr);
       SET @cDatos=(SELECT @salida salidaId,@visita visitaId,@estado estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
       INSERT campo.SalidaOperacionE2(usuario_id,tipo,idempotencia,hash_peticion,respuesta)
          VALUES(@nUsuario,@cAccion,@key,@hash,@cDatos);
       SET @bResultado=1;
     END;
     COMMIT TRANSACTION;
   END;
 END;
 IF @bResultado=1 SELECT @cMensaje=N'Operación realizada.',@cCodigoRespuesta='E2_OK',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
   IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
   SET @bResultado=0;SET @cDatos=NULL;
   SET @nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN(51060,51062) THEN 403 WHEN ERROR_NUMBER() IN(51064,51065,51067,2601,2627) THEN 409 ELSE 400 END;
   SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51060 AND 51067 THEN LEFT(ERROR_MESSAGE(),300)
     ELSE N'No se pudo completar la operación. Revise los datos y el estado de la salida.' END;
   SET @cCodigoRespuesta='E2_VALIDACION';
 END CATCH;
END;
GO
```

Ruta: `src/test/resources/sql/etapa2_refuerzo_invariantes.sql`
Contenido: completo
```sql
-- E2 read-only verification after T05/T06/T07 API scenarios and V441.
SET NOCOUNT ON;
IF EXISTS (
  SELECT 1 FROM campo.SalidaE2 E JOIN campo.SalidaCampo S ON S.salida_campo_id=E.salida_campo_id
  WHERE (E.estado IN('EN_EJECUCION','EN_RETORNO','CERRADA') AND E.fecha_aprobacion IS NULL)
     OR (E.estado='CERRADA' AND (E.fecha_fin_prevista IS NULL OR S.fecha_hora_retorno_real IS NULL))
) THROW 52011,N'E2: salida ejecutada sin aprobación o cerrada sin fecha.',1;
IF EXISTS (
  SELECT 1 FROM campo.SalidaRecursoE2 R JOIN logistica.BienInventario B
    ON B.bien_inventario_id=R.bien_inventario_id
  WHERE R.estado IN('ENTREGADO','INCIDENCIA') AND B.estado_bien='DISPONIBLE'
) THROW 52012,N'E2: bien prestado o en incidencia figura como disponible.',1;
IF EXISTS (
  SELECT A.bien_inventario_id
  FROM campo.SalidaRecursoE2 A JOIN campo.SalidaE2 E ON E.salida_campo_id=A.salida_campo_id
  WHERE E.estado IN('APROBADA','EN_EJECUCION','EN_RETORNO') AND A.estado IN('SOLICITADO','ENTREGADO')
  GROUP BY A.bien_inventario_id HAVING COUNT_BIG(*)>1
) THROW 52013,N'E2: hay reservas exclusivas simultáneas.',1;
IF EXISTS (
  SELECT M.recurso_programado_id,M.tipo_movimiento FROM logistica.RecursoMovimiento M
  JOIN campo.SalidaRecursoE2 R ON R.recurso_programado_id=M.recurso_programado_id
  WHERE M.tipo_movimiento IN('ASIGNACION','DEVOLUCION')
  GROUP BY M.recurso_programado_id,M.tipo_movimiento HAVING COUNT_BIG(*)>1
) THROW 52014,N'E2: movimiento físico duplicado.',1;
SELECT N'E2: invariantes de autorización, exclusividad y devolución verificadas' AS resultado;
```

