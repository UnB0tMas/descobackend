package com.franco.desco.adapter.in.web.planta;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.adapter.out.persistence.planta.FundoProduccionSqlServerAdapter;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.AppStatus;
import io.swagger.v3.oas.annotations.*;
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
@RequestMapping("/api/v1/apappss/fundos/{predioId}/produccion")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class FundoProduccionController {
    private final FundoProduccionSqlServerAdapter adapter;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    private final ApiResponseFactory responses;
    private final JsonMapper mapper;

    public FundoProduccionController(FundoProduccionSqlServerAdapter adapter,
            JwtSessionIdentityResolver identities, ClientRequestContextResolver metadata,
            ApiResponseFactory responses, JsonMapper mapper) {
        this.adapter=adapter;
        this.identities=identities;
        this.metadata=metadata;
        this.responses=responses;
        this.mapper=mapper;
    }

    @GetMapping
    @Operation(operationId="apappssFundoProduccionVer",summary="Estimación anual y disponibilidad del fundo")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_VER')")
    public ResponseEntity<ApiResponse<FundoProduccionWebTypes.Detalle>> ver(
            @PathVariable @Positive Long predioId,
            @RequestParam @Positive Long uotId,
            @RequestParam @Positive Long convenioId,
            @RequestParam @Min(2000) @Max(2200) Integer anio,
            JwtAuthenticationToken auth, HttpServletRequest request) {
        return responses.from(ApplicationResults.ok(
                adapter.execute("VER",uotId,convenioId,predioId,anio,null,
                        identities.resolve(auth),metadata.resolve(request),Map.class),
                "FUNDO_PRODUCCION_CONSULTADA","FUNDO_PRODUCCION_ERROR",AppStatus.BAD_REQUEST),request,
                value->mapper.convertValue(value,FundoProduccionWebTypes.Detalle.class));
    }

    @PutMapping @IdempotentOperation
    @Operation(operationId="apappssFundoProduccionGuardar",summary="Aprobar o modificar la disponibilidad anual del fundo")
    @PreAuthorize("@permissionGuard.has(authentication,'APAPPSS_PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<FundoProduccionWebTypes.Detalle>> guardar(
            @PathVariable @Positive Long predioId,
            @RequestParam @Positive Long uotId,
            @RequestParam @Positive Long convenioId,
            @Valid @RequestBody FundoProduccionWebTypes.Guardar body,
            JwtAuthenticationToken auth, HttpServletRequest request) {
        return responses.from(ApplicationResults.ok(
                adapter.execute("GUARDAR",uotId,convenioId,predioId,body.anio(),body,
                        identities.resolve(auth),metadata.resolve(request),Map.class),
                "FUNDO_PRODUCCION_GUARDADA","FUNDO_PRODUCCION_ERROR",AppStatus.BAD_REQUEST),request,
                value->mapper.convertValue(value,FundoProduccionWebTypes.Detalle.class));
    }
}
