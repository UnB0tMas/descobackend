package com.franco.desco.adapter.in.web.convenio;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
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
@RequestMapping("/api/v1/convenios")
@Tag(name = "Convenios", description = "Modulos especiales opcionales habilitados por convenio y UOT.")
@SecurityRequirement(name = "bearerAuth")
public class ConvenioController {
    private final ConvenioService service;
    private final JwtSessionIdentityResolver identities;
    private final ApiResponseFactory responses;

    public ConvenioController(ConvenioService service, JwtSessionIdentityResolver identities,
                              ApiResponseFactory responses) {
        this.service=service;
        this.identities=identities;
        this.responses=responses;
    }

    @GetMapping("/modulos-activos")
    @Operation(operationId = "conveniosModulosActivos", summary = "Modulos especiales activos en la UOT de la sesion")
    public ResponseEntity<ApiResponse<List<ConvenioModuloResponse>>> active(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.activeModules(identities.resolve(authentication)), request);
    }

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_LISTAR')")
    @Operation(operationId = "conveniosListar", summary = "Convenios y modulos disponibles para la UOT")
    public ResponseEntity<ApiResponse<List<ConvenioDetalleResponse>>> list(
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.list(identities.resolve(authentication)), request);
    }

    @PutMapping("/{id}/modulos/{codigo}")
    @PreAuthorize("@permissionGuard.has(authentication,'ORGANIZACIONES_EDITAR')")
    @Operation(operationId = "conveniosConfigurarModulo", summary = "Habilitar o deshabilitar modulo especial del convenio")
    public ResponseEntity<ApiResponse<Void>> configure(
            @PathVariable("id") Long id, @PathVariable("codigo") String codigo,
            @Valid @RequestBody ConvenioModuloRequest body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request) {
        return responses.from(service.configure(identities.resolve(authentication), id, codigo, body.habilitado()), request);
    }
}
