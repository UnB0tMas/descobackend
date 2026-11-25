package com.franco.desco.adapter.in.web.sale;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.sale.service.PosCatalogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/ventas/catalogo-pos")
@Tag(name = OpenApiConstants.TAG_SALES)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class PosCatalogController {
    private final PosCatalogService service;
    private final JwtSessionIdentityResolver identities;
    private final ApiResponseFactory responses;

    public PosCatalogController(PosCatalogService service, JwtSessionIdentityResolver identities,
                                ApiResponseFactory responses) {
        this.service = service;
        this.identities = identities;
        this.responses = responses;
    }

    @GetMapping
    @PreAuthorize("(@permissionGuard.hasUot(authentication,#uotId,'POS_OPERAR') && !#usoInterno) || "
            + "(@permissionGuard.hasUot(authentication,#uotId,'VENTAS_ENTREGA_TECNICA') && #usoInterno)")
    @Operation(operationId = "ventasCatalogoPosConsultar", summary = "Consultar almacenes y productos disponibles para POS")
    public ResponseEntity<ApiResponse<PosCatalogResponses.Catalog>> list(
            @RequestParam @Positive Long uotId,
            @RequestParam(required = false) @Positive Long almacenId,
            @RequestParam(defaultValue = "false") boolean usoInterno,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.list(identities.resolve(authentication), uotId, almacenId, usoInterno),
                request, PosCatalogResponses.Catalog::from);
    }
}
