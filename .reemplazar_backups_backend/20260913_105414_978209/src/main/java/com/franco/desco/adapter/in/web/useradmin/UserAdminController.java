package com.franco.desco.adapter.in.web.useradmin;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.useradmin.UserAdminCommands.GetUser;
import com.franco.desco.application.useradmin.port.in.UserAdminUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/usuarios")
@Tag(name="Usuarios y accesos",description="Administración de cuentas, estados y roles.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class UserAdminController {
    private final UserAdminUseCase useCase;
    private final UserAdminWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public UserAdminController(UserAdminUseCase useCase, UserAdminWebMapper mapper, ApiResponseFactory responses, ClientRequestContextResolver metadata, JwtSessionIdentityResolver identities) {
        this.useCase=useCase; this.mapper=mapper; this.responses=responses; this.metadata=metadata; this.identities=identities;
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_LISTAR')")
    @Operation(operationId="usuariosListar",summary="Listar usuarios")
    public ResponseEntity<ApiResponse<PageResponse<UserAdminResponses.Summary>>> list(
            @RequestParam(required=false) String estadoCuenta,
            @RequestParam(required=false) Long empresaId,
            @RequestParam(defaultValue="1") @Min(1) int pagina,
            @RequestParam(defaultValue="20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden=true) JwtAuthenticationToken authentication,
            @Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.list(mapper.list(pagina,tamano,estadoCuenta,empresaId),identities.resolve(authentication),metadata.resolve(request)),request,p->PageResponse.from(p,mapper::response));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_VER')")
    @Operation(operationId="usuariosVer",summary="Ver usuario, roles y dispositivos")
    public ResponseEntity<ApiResponse<UserAdminResponses.Detail>> get(@PathVariable Long id,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.get(new GetUser(id),identities.resolve(authentication),metadata.resolve(request)),request,mapper::response);
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_CREAR')")
    @Operation(operationId="usuariosCrear",summary="Crear cuenta de usuario")
    public ResponseEntity<ApiResponse<UserAdminResponses.Created>> create(@Valid @RequestBody UserAdminRequests.Create body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.create(mapper.command(body),identities.resolve(authentication),metadata.resolve(request)),request,UserAdminResponses.Created::new);
    }

    @PutMapping("/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_EDITAR')")
    @Operation(operationId="usuariosEditar",summary="Editar cuenta")
    public ResponseEntity<ApiResponse<Void>> update(@PathVariable Long id,@Valid @RequestBody UserAdminRequests.Update body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.update(mapper.command(id,body),identities.resolve(authentication),metadata.resolve(request)),request);
    }

    @PostMapping("/{id}/deshabilitar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_RETIRAR')")
    @Operation(operationId="usuariosDeshabilitar",summary="Deshabilitar cuenta")
    public ResponseEntity<ApiResponse<Void>> disable(@PathVariable Long id,@Valid @RequestBody UserAdminRequests.Disable body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.disable(mapper.command(id,body),identities.resolve(authentication),metadata.resolve(request)),request);
    }

    @PostMapping("/{id}/reactivar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_CONFIRMAR')")
    @Operation(operationId="usuariosReactivar",summary="Reactivar cuenta")
    public ResponseEntity<ApiResponse<Void>> reactivate(@PathVariable Long id,@Valid @RequestBody UserAdminRequests.Reactivate body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.reactivate(mapper.command(id,body),identities.resolve(authentication),metadata.resolve(request)),request);
    }

    @PostMapping("/{id}/roles")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_CREAR')")
    @Operation(operationId="usuariosAsignarRol",summary="Asignar rol")
    public ResponseEntity<ApiResponse<Void>> assignRole(@PathVariable Long id,@Valid @RequestBody UserAdminRequests.AssignRole body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.assignRole(mapper.command(id,body),identities.resolve(authentication),metadata.resolve(request)),request);
    }

    @DeleteMapping("/{id}/roles")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.has(authentication,'USUARIOS_RETIRAR')")
    @Operation(operationId="usuariosRetirarRol",summary="Retirar rol")
    public ResponseEntity<ApiResponse<Void>> removeRole(@PathVariable Long id,@Valid @RequestBody UserAdminRequests.RemoveRole body,@Parameter(hidden=true) JwtAuthenticationToken authentication,@Parameter(hidden=true) HttpServletRequest request) {
        return responses.from(useCase.removeRole(mapper.command(id,body),identities.resolve(authentication),metadata.resolve(request)),request);
    }
}
