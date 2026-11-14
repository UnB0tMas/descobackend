package com.franco.desco.adapter.in.web.planta;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.adapter.out.persistence.planta.FundoAccionesSqlServerAdapter;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.AppStatus;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
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
@RequestMapping("/api/v1/apappss/fundos/{predioId}")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class FundoAccionesController {
    @Schema(name = "FundoAptitudResponse")
    public record Estado(Long predioId, Boolean habilitado, Long plantasActivas, Long version) {}
    @Schema(name = "FundoAptitudActualizarRequest")
    public record Cambiar(@NotNull Boolean habilitado, @NotNull @PositiveOrZero Long version) {}
    @Schema(name = "FundoRetirarRequest")
    public record Retirar(@NotBlank @Size(min = 5, max = 500) String motivo) {}
    @Schema(name = "FundoRetirarResponse")
    public record Retiro(Long predioId, Boolean retirado) {}

    private final FundoAccionesSqlServerAdapter adapter;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    private final ApiResponseFactory responses;
    private final JsonMapper mapper;

    public FundoAccionesController(FundoAccionesSqlServerAdapter adapter,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata,
            ApiResponseFactory responses, JsonMapper mapper) {
        this.adapter = adapter;
        this.identities = identities;
        this.metadata = metadata;
        this.responses = responses;
        this.mapper = mapper;
    }

    @GetMapping("/habilitacion")
    @Operation(operationId = "apappssFundoAptitudVer", summary = "Consultar aptitud de producción del fundo")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<Estado>> consultar(@PathVariable @Positive Long predioId,
            @RequestParam @Positive Long uotId, @RequestParam @Positive Long convenioId,
            JwtAuthenticationToken auth, HttpServletRequest request) {
        return responses.from(ApplicationResults.ok(adapter.execute(
                FundoAccionesSqlServerAdapter.Accion.CONSULTAR, uotId, convenioId, predioId, null,
                identities.resolve(auth), metadata.resolve(request), Map.class),
                "FUNDO_APTITUD_CONSULTADA", "FUNDO_APTITUD_ERROR", AppStatus.BAD_REQUEST), request,
                value -> mapper.convertValue(value, Estado.class));
    }

    @PutMapping("/habilitacion") @IdempotentOperation
    @Operation(operationId = "apappssFundoAptitudActualizar", summary = "Habilitar o deshabilitar fundo para producción")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<Estado>> cambiar(@PathVariable @Positive Long predioId,
            @RequestParam @Positive Long uotId, @RequestParam @Positive Long convenioId,
            @Valid @RequestBody Cambiar body, JwtAuthenticationToken auth, HttpServletRequest request) {
        return responses.from(ApplicationResults.ok(adapter.execute(
                FundoAccionesSqlServerAdapter.Accion.CAMBIAR, uotId, convenioId, predioId, body,
                identities.resolve(auth), metadata.resolve(request), Map.class),
                "FUNDO_APTITUD_ACTUALIZADA", "FUNDO_APTITUD_ERROR", AppStatus.BAD_REQUEST), request,
                value -> mapper.convertValue(value, Estado.class));
    }

    @PostMapping("/retirar") @IdempotentOperation
    @Operation(operationId = "apappssFundoRetirar", summary = "Retirar lógicamente fundo y registros operativos")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_RETIRAR')")
    public ResponseEntity<ApiResponse<Retiro>> retirar(@PathVariable @Positive Long predioId,
            @RequestParam @Positive Long uotId, @RequestParam @Positive Long convenioId,
            @Valid @RequestBody Retirar body, JwtAuthenticationToken auth, HttpServletRequest request) {
        return responses.from(ApplicationResults.ok(adapter.execute(
                FundoAccionesSqlServerAdapter.Accion.RETIRAR, uotId, convenioId, predioId, body,
                identities.resolve(auth), metadata.resolve(request), Map.class),
                "FUNDO_RETIRADO", "FUNDO_RETIRO_ERROR", AppStatus.BAD_REQUEST), request,
                value -> mapper.convertValue(value, Retiro.class));
    }
}
