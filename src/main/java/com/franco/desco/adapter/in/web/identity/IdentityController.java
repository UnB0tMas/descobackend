package com.franco.desco.adapter.in.web.identity;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.identity.port.in.IdentityUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/identidades")
@Tag(
        name = "Validación de identidad",
        description = "Resolución local y consulta controlada de DNI/RUC mediante Factiliza con persistencia inmediata en DESCO."
)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
public class IdentityController {

    private final IdentityUseCase useCase;
    private final IdentityWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public IdentityController(
            IdentityUseCase useCase,
            IdentityWebMapper mapper,
            ApiResponseFactory responses,
            ClientRequestContextResolver metadata,
            JwtSessionIdentityResolver identities
    ) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    @PostMapping("/resolver")
    @PreAuthorize(
            "@permissionGuard.has(authentication,'VALIDACIONIDENTIDAD_CONSULTAR')"
    )
    @Operation(
            operationId = "identidadResolverDocumento",
            summary = "Resolver DNI/RUC",
            description = """
                    Busca primero en Persona/Empresa.
                    Si la identidad no existe y SQL autoriza el consumo,
                    consulta Factiliza desde el backend y persiste inmediatamente
                    los datos válidos disponibles en DESCO.
                    La carga manual solo se habilita cuando la validación automática
                    termina sin datos utilizables o con un fallo del proveedor.
                    """
    )
    public ResponseEntity<ApiResponse<IdentityResponses.Resolve>> resolve(
            @Valid @RequestBody IdentityRequests.Resolve request,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest servletRequest
    ) {
        return responses.from(
                useCase.resolve(
                        mapper.command(request),
                        identities.resolve(authentication),
                        metadata.resolve(servletRequest)
                ),
                servletRequest,
                mapper::response
        );
    }
}
