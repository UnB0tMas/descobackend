package com.franco.desco.adapter.in.web.caja;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.caja.CajaPosService;
import com.franco.desco.application.caja.HorarioComercialService;
import com.franco.desco.application.caja.AtencionSemanalService;
import com.franco.desco.application.caja.PlantillaHorarioService;
import com.franco.desco.application.caja.PlantillaHorarioRepository;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.function.Supplier;

@RestController
@RequestMapping("/api/v1/comercial/horarios")
@Tag(name="Horarios comerciales",description="Personal y cobertura de atención por UOT")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class HorarioComercialController {
    private final HorarioComercialService service;
    private final PlantillaHorarioService plantillas;
    private final AtencionSemanalService atencionSemanal;
    private final JwtSessionIdentityResolver identity;
    private final ApiResponseFactory responses;
    public HorarioComercialController(HorarioComercialService service,PlantillaHorarioService plantillas,
                                      AtencionSemanalService atencionSemanal,
                                      JwtSessionIdentityResolver identity,ApiResponseFactory responses) {
        this.service=service;this.plantillas=plantillas;this.atencionSemanal=atencionSemanal;this.identity=identity;this.responses=responses;
    }
    public record Configuracion(@NotNull @Positive Long uotId,
        @NotBlank @Pattern(regexp="([01][0-9]|2[0-3]):[0-5][0-9]") String horaInicio,
        @NotBlank @Pattern(regexp="([01][0-9]|2[0-3]):[0-5][0-9]") String horaFin) {}
    public record Asignacion(@NotNull @Positive Long uotId,
        @NotNull List<@Valid HorarioBloque> bloques,
        boolean autorizarCoincidencia,@Size(max=300) String motivoCoincidencia) {}
    public record HorarioBloque(@NotNull @Min(1) @Max(7) Integer diaSemana,
        @NotBlank @Pattern(regexp="([01][0-9]|2[0-3]):[0-5][0-9]") String horaInicio,
        @NotBlank @Pattern(regexp="([01][0-9]|2[0-3]):[0-5][0-9]") String horaFin) {}
    public record CambioAcceso(@NotNull @Positive Long uotId,boolean habilitar,
      @NotBlank @Size(min=5,max=270) String motivo) {}
    private long user(JwtAuthenticationToken auth) {return identity.resolve(auth).usuarioId();}
    private <T> ResponseEntity<ApiResponse<T>> response(Supplier<T> supplier,HttpServletRequest req) {
        try { return responses.from(AppResult.ok("COMERCIAL_OK","Operación correcta.",supplier.get()),req); }
        catch(AtencionSemanalService.Rechazo ex) {
            return responses.from(AppResult.<T>error(AppStatus.fromHttp(ex.http(),AppStatus.CONFLICT),
                    "COMERCIAL_ATENCION",ex.getMessage()),req);
        } catch(PlantillaHorarioService.Rechazo ex) {
            return responses.from(AppResult.<T>error(AppStatus.fromHttp(ex.http(),AppStatus.CONFLICT),
                    "COMERCIAL_TURNO",ex.getMessage()),req);
        } catch(CajaPosService.Regla ex) {
            return responses.from(AppResult.<T>error(AppStatus.CONFLICT,"COMERCIAL_REGLA",ex.getMessage()),req);
        } catch(DataAccessException ex) {
            return responses.from(AppResult.<T>error(AppStatus.CONFLICT,"COMERCIAL_BD",
                    "No se completó la operación de horarios."),req);
        }
    }
    @GetMapping("/mio")
    @Operation(operationId="comercialHorariosMio",summary="Consultar únicamente mi horario")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'PERSONAL_COMERCIAL_PROPIO')")
    public ResponseEntity<ApiResponse<HorarioComercialService.MiHorario>> mio(@RequestParam @Positive Long uotId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->service.mio(user(authentication),uotId),request);
    }
    @GetMapping
    @Operation(operationId="comercialHorariosPlanilla")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'PERSONAL_COMERCIAL_LISTAR')")
    public ResponseEntity<ApiResponse<HorarioComercialService.Planilla>> planilla(@RequestParam @Positive Long uotId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->service.planilla(user(authentication),uotId),request);
    }
    @PutMapping("/empleados/{id}/acceso")
    @IdempotentOperation
    @Operation(operationId="comercialHorariosCambiarAcceso")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'PERSONAL_COMERCIAL_HABILITAR')")
    public ResponseEntity<ApiResponse<HorarioComercialService.AccesoResultado>> acceso(@PathVariable @Positive Long id,
            @Valid @RequestBody CambioAcceso body,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->service.cambiarAcceso(user(authentication),body.uotId(),id,
                body.habilitar(),body.motivo()),request);
    }
    @PutMapping("/configuracion")
    @IdempotentOperation
    @Operation(operationId="comercialHorariosConfigurar")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'HORARIO_COMERCIAL_CONFIGURAR')")
    public ResponseEntity<ApiResponse<HorarioComercialService.Resultado>> configurar(@Valid @RequestBody Configuracion body,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->{atencionSemanal.ejecutar("APLICAR",user(authentication),body.uotId(),
            "GENERAL",null,body.horaInicio(),body.horaFin(),false,null);
            return new HorarioComercialService.Resultado(body.uotId(),"Horario actualizado.");},request);
    }
    public record ConfigurarAtencion(@NotNull @Positive Long uotId,
        @NotBlank @Pattern(regexp="GENERAL|PERSONALIZAR|HEREDAR") String modo,
        @Min(1) @Max(7) Integer diaSemana,
        String horaInicio, String horaFin, boolean ajustarEmpleados, @Size(max=100000) String vistaConfirmada) {}

    @PostMapping("/atencion-semanal/preview")
    @Operation(operationId="comercialHorariosPrevisualizarAtencion")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'HORARIO_COMERCIAL_CONFIGURAR')")
    public ResponseEntity<ApiResponse<AtencionSemanalService.Resultado>> previsualizarAtencion(
            @Valid @RequestBody ConfigurarAtencion body, JwtAuthenticationToken authentication,
            HttpServletRequest request) {
        return response(()->atencionSemanal.ejecutar("PREVISUALIZAR",user(authentication),body.uotId(),
            body.modo(),body.diaSemana(),body.horaInicio(),body.horaFin(),false,null),request);
    }

    @PutMapping("/atencion-semanal")
    @IdempotentOperation
    @Operation(operationId="comercialHorariosGuardarAtencionSemanal")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'HORARIO_COMERCIAL_CONFIGURAR')")
    public ResponseEntity<ApiResponse<AtencionSemanalService.Resultado>> guardarAtencionSemanal(
            @Valid @RequestBody ConfigurarAtencion body, JwtAuthenticationToken authentication,
            HttpServletRequest request) {
        return response(()->atencionSemanal.ejecutar("APLICAR",user(authentication),body.uotId(),
            body.modo(),body.diaSemana(),body.horaInicio(),body.horaFin(),body.ajustarEmpleados(),body.vistaConfirmada()),request);
    }

    public record ConfigurarAtencionLote(@NotNull @Positive Long uotId,
        @NotEmpty @Size(max=7) List<@NotNull @Min(1) @Max(7) Integer> diasSemana,
        @NotBlank String horaInicio, @NotBlank String horaFin,
        boolean ajustarEmpleados, @Size(max=100000) String vistaConfirmada) {}

    @PostMapping("/atencion-semanal/lote/preview")
    @Operation(operationId="comercialHorariosPrevisualizarAtencionLote")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'HORARIO_COMERCIAL_CONFIGURAR')")
    public ResponseEntity<ApiResponse<AtencionSemanalService.Resultado>> previsualizarAtencionLote(
            @Valid @RequestBody ConfigurarAtencionLote body, JwtAuthenticationToken authentication,
            HttpServletRequest request) {
        return response(()->atencionSemanal.ejecutarLote("PREVISUALIZAR", user(authentication), body.uotId(),
                body.diasSemana(), body.horaInicio(), body.horaFin(), false, null), request);
    }

    @PutMapping("/atencion-semanal/lote")
    @IdempotentOperation
    @Operation(operationId="comercialHorariosGuardarAtencionLote")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'HORARIO_COMERCIAL_CONFIGURAR')")
    public ResponseEntity<ApiResponse<AtencionSemanalService.Resultado>> guardarAtencionLote(
            @Valid @RequestBody ConfigurarAtencionLote body, JwtAuthenticationToken authentication,
            HttpServletRequest request) {
        return response(()->atencionSemanal.ejecutarLote("APLICAR", user(authentication), body.uotId(),
                body.diasSemana(), body.horaInicio(), body.horaFin(), body.ajustarEmpleados(),
                body.vistaConfirmada()), request);
    }

    @PutMapping("/empleados/{id}")
    @IdempotentOperation
    @Operation(operationId="comercialHorariosAsignar")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'PERSONAL_COMERCIAL_EDITAR')")
    public ResponseEntity<ApiResponse<HorarioComercialService.Resultado>> asignar(@PathVariable @Positive Long id,
            @Valid @RequestBody Asignacion body,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->service.guardar(user(authentication),body.uotId(),id,
             body.bloques().stream().map(b->new HorarioComercialService.Bloque(b.diaSemana(),b.horaInicio(),b.horaFin())).toList(),
             body.autorizarCoincidencia(),body.motivoCoincidencia()),request);
    }
    public record GuardarPlantilla(@NotNull @Positive Long uotId,
        @Positive Long plantillaId,
        @NotBlank @Size(min=2,max=80) String nombre,
        @NotBlank @Pattern(regexp="([01][0-9]|2[0-3]):[0-5][0-9]") String horaInicio,
        @NotBlank @Pattern(regexp="([01][0-9]|2[0-3]):[0-5][0-9]") String horaFin) {}

    @GetMapping("/plantillas")
    @Operation(operationId="comercialHorariosPlantillas",summary="Consultar turnos reutilizables")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'PERSONAL_COMERCIAL_LISTAR')")
    public ResponseEntity<ApiResponse<List<PlantillaHorarioRepository.Plantilla>>> listarPlantillas(
            @RequestParam @Positive Long uotId,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->plantillas.listar(user(authentication),uotId),request);
    }

    @PutMapping("/plantillas")
    @IdempotentOperation
    @Operation(operationId="comercialHorariosGuardarPlantilla",summary="Crear o editar un turno reutilizable")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'HORARIO_COMERCIAL_CONFIGURAR')")
    public ResponseEntity<ApiResponse<HorarioComercialService.Resultado>> guardarPlantilla(
            @Valid @RequestBody GuardarPlantilla body,JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->plantillas.guardar(user(authentication),body.uotId(),body.plantillaId(),
                body.nombre(),body.horaInicio(),body.horaFin()),request);
    }

    @PostMapping("/plantillas/{id}/desactivar")
    @IdempotentOperation
    @Operation(operationId="comercialHorariosDesactivarPlantilla",summary="Retirar un turno reutilizable")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'HORARIO_COMERCIAL_CONFIGURAR')")
    public ResponseEntity<ApiResponse<HorarioComercialService.Resultado>> desactivarPlantilla(
            @PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        return response(()->plantillas.desactivar(user(authentication),uotId,id),request);
    }

}
