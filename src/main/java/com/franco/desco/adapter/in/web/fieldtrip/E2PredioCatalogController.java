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
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/salidas-operativas")
@Tag(name="Predios para salidas",description="Predios productivos disponibles para programación")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
public class E2PredioCatalogController {
    public record Predio(Long predioId,String codigo,String nombre){}
    private final JdbcTemplate jdbc;
    private final JwtSessionIdentityResolver identity;
    private final ApiResponseFactory responses;
    public E2PredioCatalogController(JdbcTemplate jdbc,JwtSessionIdentityResolver identity,ApiResponseFactory responses){
        this.jdbc=jdbc;this.identity=identity;this.responses=responses;
    }
    @GetMapping("/predios")
    @Operation(operationId="salidasPrediosDisponibles",summary="Listar predios/fundos por UOT")
    @PreAuthorize("@permissionGuard.has(authentication,'SALIDAS_VER')")
    public ResponseEntity<ApiResponse<List<Predio>>> predios(
            @RequestParam @Positive Long uotId,@RequestParam(required=false) @Size(max=150) String buscar,
            @Parameter(hidden=true) JwtAuthenticationToken a,
            @Parameter(hidden=true) HttpServletRequest r){
        try {
            var rows=jdbc.query("EXEC campo.PA_SalidaDestino_Sel_Predios ?,?,?",
                    (rs,n)->new Predio(rs.getLong("predioId"),rs.getString("codigo"),rs.getString("nombre")),
                    identity.resolve(a).usuarioId(),uotId,buscar==null||buscar.isBlank()?null:buscar.trim());
            return responses.from(AppResult.ok("E2_PREDIOS_LISTADOS","Predios consultados.",rows),r);
        }catch(DataAccessException ex){
            return responses.from(AppResult.<List<Predio>>error(AppStatus.SERVICE_UNAVAILABLE,
                    "E2_PREDIOS_NO_DISPONIBLES","No se pudo consultar el catálogo de predios."),r);
        }
    }
}
