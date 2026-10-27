package com.franco.desco.adapter.in.web.uot;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.application.uot.UotCommands;
import com.franco.desco.application.uot.port.in.UotUseCase;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/uot")
@Tag(name = "UOT", description = "Contexto de trabajo y administración multi-UOT.")
@SecurityRequirement(name = "bearerAuth")
public class UotController {
    private final UotUseCase useCase;
    private final UotWebMapper mapper;
    private final ApiResponseFactory responses;
    private final JwtSessionIdentityResolver identities;
    private final IdempotencyKeyResolver idempotency;

    public UotController(UotUseCase useCase, UotWebMapper mapper, ApiResponseFactory responses,
                         JwtSessionIdentityResolver identities, IdempotencyKeyResolver idempotency) {
        this.useCase = useCase;
        this.mapper = mapper;
        this.responses = responses;
        this.identities = identities;
        this.idempotency = idempotency;
    }

    @GetMapping("/contexto")
    @Operation(operationId = "uotContexto", summary = "Obtener las UOT y el contexto activo de la sesión")
    public ResponseEntity<ApiResponse<UotResponses.Context>> context(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.context(identities.resolve(authentication)), request, mapper::response);
    }

    @PostMapping("/contexto")
    @IdempotentOperation
    @Operation(operationId = "uotSeleccionarContexto", summary = "Cambiar entre una UOT específica y modo general")
    public ResponseEntity<ApiResponse<UotResponses.Context>> select(
            @Valid @RequestBody UotRequests.SelectContext body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.select(mapper.command(body), identities.resolve(authentication)), request, mapper::response);
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.hasUot(authentication,'UOT_LISTAR')")
    public ResponseEntity<ApiResponse<List<UotResponses.Unit>>> list(
            @RequestParam(required = false) Long uotId,
            @RequestParam(defaultValue = "false") boolean incluirInactivas,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.list(identities.resolve(authentication), uotId, incluirInactivas), request,
                values -> values.stream().map(mapper::response).toList());
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,'UOT_CREAR')")
    public ResponseEntity<ApiResponse<UotResponses.Created>> create(
            @Valid @RequestBody UotRequests.Create body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.create(mapper.command(body, idempotency.required(request)), identities.resolve(authentication)), request, UotResponses.Created::new);
    }

    @PutMapping("/{uotId}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'UOT_EDITAR')")
    public ResponseEntity<ApiResponse<Void>> update(
            @PathVariable Long uotId, @Valid @RequestBody UotRequests.Update body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.update(mapper.command(uotId, body), identities.resolve(authentication)), request);
    }

    @PostMapping("/{uotId}/usuarios")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'UOT_ADMINISTRAR_ACCESOS')")
    public ResponseEntity<ApiResponse<Void>> assignUser(
            @PathVariable Long uotId, @Valid @RequestBody UotRequests.AssignUser body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.assignUser(new UotCommands.AssignUser(body.usuarioId(), uotId, body.predeterminada()), identities.resolve(authentication)), request);
    }

    @PostMapping("/{uotId}/roles")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#uotId,'UOT_ADMINISTRAR_ACCESOS')")
    public ResponseEntity<ApiResponse<Void>> assignRole(
            @PathVariable Long uotId, @Valid @RequestBody UotRequests.AssignRole body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(useCase.assignRole(new UotCommands.AssignRole(body.usuarioId(), uotId, body.rolId()), identities.resolve(authentication)), request);
    }
}
