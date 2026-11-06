package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.shared.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;
import tools.jackson.databind.json.JsonMapper;
import java.util.List;

@RestController
@RequestMapping("/api/v1/salidas-operativas")
@Tag(name="Custodia de recursos de campo")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
public class E2CustodiaController {
    public record Item(@NotNull @Positive Long solicitudRecursoId,
            @NotBlank @Size(max=500) String observacion) {}
    public record Entrega(@NotNull List<@Valid Item> recursos) {}
    private final JdbcTemplate jdbc;
    private final JsonMapper json;
    private final JwtSessionIdentityResolver identity;
    private final ApiResponseFactory responses;
    public E2CustodiaController(JdbcTemplate jdbc,JsonMapper json,JwtSessionIdentityResolver identity,
            ApiResponseFactory responses){
        this.jdbc=jdbc;this.json=json;this.identity=identity;this.responses=responses;
    }
    @PostMapping("/{id}/entrega-observaciones")
    @Operation(operationId="salidasCustodiaRegistrarEntrega",summary="Documentar estado inicial por recurso previo al despacho")
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR')")
    public ResponseEntity<ApiResponse<Void>> registrar(
            @PathVariable @Positive Long id,@RequestParam @Positive Long uotId,
            @Valid @RequestBody Entrega datos,
            @Parameter(hidden=true) JwtAuthenticationToken a,
            @Parameter(hidden=true) HttpServletRequest r){
        try {
            jdbc.update("EXEC campo.PA_SalidaRecurso_Upd_ObservacionesEntrega ?,?,?,?",
                identity.resolve(a).usuarioId(),uotId,id,json.writeValueAsString(datos.recursos()));
            return responses.from(AppResult.<Void>ok("E2_CUSTODIA_ENTREGA","Estado de los recursos registrado.",null),r);
        }catch(DataAccessException e){
            return responses.from(AppResult.<Void>error(AppStatus.BAD_REQUEST,"E2_CUSTODIA_ERROR",
                "Revise los recursos y sus observaciones antes de confirmar el despacho."),r);
        }
    }
}
