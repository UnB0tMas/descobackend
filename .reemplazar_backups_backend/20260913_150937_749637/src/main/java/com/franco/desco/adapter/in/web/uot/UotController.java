package com.franco.desco.adapter.in.web.uot;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.uot.UotCommands;
import com.franco.desco.application.uot.port.in.UotUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/uot")
@Tag(name = OpenApiConstants.TAG_UOT, description = OpenApiConstants.TAG_UOT_DESCRIPTION)
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class UotController {
    private final UotUseCase useCase;
    private final UotWebMapper mapper;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public UotController(
            UotUseCase useCase,
            UotWebMapper mapper,
            ApiResponseFactory responses,
            JwtSessionIdentityResolver identities,
            IdempotencyKeyResolver idempotency
    ) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.identities = identities;
        this.idempotency = idempotency;
    }

    @GetMapping("/contexto")
    @Operation(operationId = "uotContexto", summary = "Obtener contexto UOT de la sesión")
    public ResponseEntity<ApiResponse<UotResponses.Context>> context(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.context(identities.resolve(authentication)),
                request,
                mapper::response
        );
    }

    @PostMapping("/contexto")
    @IdempotentOperation
    @Operation(operationId = "uotSeleccionarContexto", summary = "Seleccionar UOT específica o modo general")
    public ResponseEntity<ApiResponse<UotResponses.Context>> select(
            @Valid @RequestBody UotRequests.SelectContext body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.select(mapper.command(body), identities.resolve(authentication)),
                request,
                mapper::response
        );
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.hasUot(authentication,'UOT_LISTAR')")
    @Operation(operationId = "uotListar", summary = "Listar UOT visibles en el contexto autorizado")
    public ResponseEntity<ApiResponse<List<UotResponses.Unit>>> list(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(defaultValue = "false") boolean incluirInactivas,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.list(identities.resolve(authentication), uotId, incluirInactivas),
                request,
                values -> values.stream().map(mapper::response).toList()
        );
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'UOT_CREAR')")
    @Operation(operationId = "uotCrear", summary = "Registrar una UOT")
    public ResponseEntity<ApiResponse<UotResponses.Created>> create(
            @Valid @RequestBody UotRequests.Create body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.create(
                        mapper.command(body, idempotency.required(request)),
                        identities.resolve(authentication)
                ),
                request,
                UotResponses.Created::new
        );
    }

    @PutMapping("/{uotId}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'UOT_EDITAR')")
    @Operation(operationId = "uotEditar", summary = "Editar una UOT")
    public ResponseEntity<ApiResponse<Void>> update(
            @PathVariable @Positive Long uotId,
            @Valid @RequestBody UotRequests.Update body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.update(mapper.command(uotId, body), identities.resolve(authentication)),
                request
        );
    }

    @PostMapping("/{uotId}/usuarios")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'UOT_ADMINISTRAR_ACCESOS')")
    @Operation(operationId = "uotAsignarUsuario", summary = "Asignar un usuario a una UOT")
    public ResponseEntity<ApiResponse<Void>> assignUser(
            @PathVariable @Positive Long uotId,
            @Valid @RequestBody UotRequests.AssignUser body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.assignUser(
                        new UotCommands.AssignUser(body.usuarioId(), uotId, body.predeterminada()),
                        identities.resolve(authentication)
                ),
                request
        );
    }

    @PostMapping("/{uotId}/roles")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'UOT_ADMINISTRAR_ACCESOS')")
    @Operation(operationId = "uotAsignarRol", summary = "Asignar un rol de usuario dentro de una UOT")
    public ResponseEntity<ApiResponse<Void>> assignRole(
            @PathVariable @Positive Long uotId,
            @Valid @RequestBody UotRequests.AssignRole body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.assignRole(
                        new UotCommands.AssignRole(body.usuarioId(), uotId, body.rolId()),
                        identities.resolve(authentication)
                ),
                request
        );
    }
}
