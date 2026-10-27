package com.franco.desco.adapter.in.web.resourceprogram;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.resourceprogram.ResourceProgramCommands;
import com.franco.desco.application.resourceprogram.port.in.ResourceProgramUseCase;
import com.franco.desco.application.resourceprogram.service.ResourceProgramContextService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/recursos-programados")
@Tag(
        name = "Recursos programados",
        description = "Programación, asignación, devolución y disponibilidad de recursos."
)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class ResourceProgramController {

    private final ResourceProgramUseCase useCase;
    private final ResourceProgramContextService contextService;
    private final ResourceProgramWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public ResourceProgramController(
            ResourceProgramUseCase useCase,
            ResourceProgramContextService contextService,
            ResourceProgramWebMapper mapper,
            ApiResponseFactory responses,
            ClientRequestContextResolver metadata,
            JwtSessionIdentityResolver identities
    ) {
        this.useCase = useCase;
        this.contextService = contextService;
        this.mapper = mapper;
        this.responses = responses;
        this.metadata = metadata;
        this.identities = identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_LISTAR')")
    @Operation(
            operationId = "recursosListar",
            summary = "Listar recursos programados"
    )
    public ResponseEntity<ApiResponse<PageResponse<ResourceProgramResponses.Summary>>> list(
            @RequestParam(required = false) String estadoProceso,
            @RequestParam(required = false) Long campaniaVentaId,
            @RequestParam(required = false) Long operativoVentaId,
            @RequestParam(required = false) Long salidaCampoId,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.list(
                        mapper.list(
                                pagina,
                                tamano,
                                estadoProceso,
                                campaniaVentaId,
                                operativoVentaId,
                                salidaCampoId
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                page -> PageResponse.from(page, mapper::response)
        );
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_VER')")
    @Operation(
            operationId = "recursosVer",
            summary = "Ver recurso programado"
    )
    public ResponseEntity<ApiResponse<ResourceProgramResponses.Detail>> get(
            @PathVariable @Positive Long id,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.get(
                        new ResourceProgramCommands.Get(id),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                mapper::response
        );
    }

    @GetMapping("/destinos")
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_VER')")
    @Operation(
            operationId = "recursosDestinosListar",
            summary = "Listar destinos disponibles para programar recursos",
            description = "Devuelve campañas, operativos y salidas con sus nombres y UOT para evitar que el usuario escriba identificadores numéricos."
    )
    public ResponseEntity<ApiResponse<List<ResourceProgramResponses.Destination>>> destinations(
            @RequestParam(required = false) @Positive Long uotId,
            @Parameter(
                    description = "Filtro opcional por tipo de destino.",
                    schema = @Schema(
                            allowableValues = {"CAMPANIA", "OPERATIVO", "SALIDA"}
                    )
            )
            @RequestParam(required = false)
            @Pattern(regexp = "CAMPANIA|OPERATIVO|SALIDA")
            String tipo,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                contextService.destinations(
                        identities.resolve(authentication),
                        uotId,
                        tipo
                ),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @GetMapping("/disponibilidad")
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'RECURSOS_VER')")
    @Operation(
            operationId = "recursosDisponibilidad",
            summary = "Consultar bienes y suministros disponibles por UOT",
            description = "La UOT es explícita para que GENERAL no mezcle recursos de unidades distintas."
    )
    public ResponseEntity<ApiResponse<ResourceProgramResponses.Availability>> availability(
            @RequestParam @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                contextService.availability(
                        identities.resolve(authentication),
                        uotId
                ),
                request,
                mapper::response
        );
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR')")
    @Operation(
            operationId = "recursosProgramar",
            summary = "Programar recurso",
            description = "Antes de registrar, DESCO valida que el destino pertenezca a una UOT donde el usuario tenga permiso RECURSOS_CREAR."
    )
    public ResponseEntity<ApiResponse<ResourceProgramResponses.Created>> program(
            @Valid @RequestBody ResourceProgramRequests.Program body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        ResourceProgramCommands.Program command =
                new ResourceProgramCommands.Program(
                        body.campaniaVentaId(),
                        body.operativoVentaId(),
                        body.salidaCampoId(),
                        body.bienInventarioId(),
                        body.suministroId(),
                        body.cantidadProgramada(),
                        body.observacion()
                );

        return responses.from(
                contextService.program(
                        command,
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                ResourceProgramResponses.Created::new
        );
    }

    @PutMapping("/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_EDITAR')")
    @Operation(
            operationId = "recursosEditar",
            summary = "Editar recurso programado"
    )
    public ResponseEntity<ApiResponse<Void>> update(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceProgramRequests.Update body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.update(
                        new ResourceProgramCommands.Update(
                                id,
                                body.cantidadProgramada(),
                                body.observacion()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @PostMapping("/{id}/asignar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR')")
    @Operation(
            operationId = "recursosAsignar",
            summary = "Asignar recurso programado"
    )
    public ResponseEntity<ApiResponse<Void>> assign(
            @PathVariable @Positive Long id,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.assign(
                        new ResourceProgramCommands.Assign(id),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @PostMapping("/{id}/devolucion")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR')")
    @Operation(
            operationId = "recursosRegistrarDevolucion",
            summary = "Registrar devolución de recurso"
    )
    public ResponseEntity<ApiResponse<Void>> returnResource(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceProgramRequests.ReturnResource body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.returnResource(
                        new ResourceProgramCommands.ReturnResource(
                                id,
                                body.cantidadDevuelta(),
                                body.observacion()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @PostMapping("/{id}/consumo")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_CREAR')")
    @Operation(
            operationId = "recursosRegistrarConsumo",
            summary = "Registrar consumo pendiente de un suministro asignado"
    )
    public ResponseEntity<ApiResponse<Void>> consume(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceProgramRequests.Consume body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.consume(
                        new ResourceProgramCommands.Consume(
                                id,
                                body.cantidadConsumida(),
                                body.observacion()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }

    @PostMapping("/{id}/cancelar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'RECURSOS_RETIRAR')")
    @Operation(
            operationId = "recursosCancelar",
            summary = "Cancelar recurso programado"
    )
    public ResponseEntity<ApiResponse<Void>> cancel(
            @PathVariable @Positive Long id,
            @Valid @RequestBody ResourceProgramRequests.Cancel body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.cancel(
                        new ResourceProgramCommands.Cancel(
                                id,
                                body.motivo()
                        ),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request
        );
    }
}
