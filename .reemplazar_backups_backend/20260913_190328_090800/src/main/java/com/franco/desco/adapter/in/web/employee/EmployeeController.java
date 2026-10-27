package com.franco.desco.adapter.in.web.employee;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.employee.EmployeeCommands.GetEmployee;
import com.franco.desco.application.employee.port.in.EmployeeUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/empleados")
@Tag(name = "Empleados", description = "Administración de empleados por UOT.")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class EmployeeController {

    private final EmployeeUseCase useCase;
    private final EmployeeWebMapper mapper;
    private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;
    private final JwtSessionIdentityResolver identities;

    public EmployeeController(
            EmployeeUseCase useCase,
            EmployeeWebMapper mapper,
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

    @GetMapping
    @PreAuthorize("@permissionGuard.hasUot(authentication,'EMPLEADOS_LISTAR')")
    @Operation(operationId = "empleadosListar", summary = "Listar empleados de la UOT")
    public ResponseEntity<ApiResponse<PageResponse<EmployeeResponses.Summary>>> list(
            @RequestParam(required = false) @Positive Long uotId,
            @RequestParam(required = false) @Positive Long empresaId,
            @RequestParam(required = false) @Positive Long areaId,
            @RequestParam(required = false) Boolean activo,
            @RequestParam(defaultValue = "1") @Min(1) int pagina,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int tamano,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.list(
                        mapper.list(pagina, tamano, empresaId, uotId, areaId, activo),
                        identities.resolve(authentication),
                        metadata.resolve(request)
                ),
                request,
                page -> PageResponse.from(page, mapper::response)
        );
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.hasUot(authentication,'EMPLEADOS_VER')")
    @Operation(operationId = "empleadosVer", summary = "Ver empleado de la UOT")
    public ResponseEntity<ApiResponse<EmployeeResponses.Detail>> get(
            @PathVariable @Positive Long id,
            @RequestParam(required = false) @Positive Long uotId,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.get(new GetEmployee(id, uotId), identities.resolve(authentication), metadata.resolve(request)),
                request,
                mapper::response
        );
    }

    @PostMapping
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'EMPLEADOS_CREAR')")
    @Operation(operationId = "empleadosCrear", summary = "Registrar empleado en una UOT")
    public ResponseEntity<ApiResponse<EmployeeResponses.Created>> create(
            @Valid @RequestBody EmployeeRequests.Create body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.create(mapper.command(body), identities.resolve(authentication), metadata.resolve(request)),
                request,
                EmployeeResponses.Created::new
        );
    }

    @PutMapping("/{id}")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'EMPLEADOS_EDITAR')")
    @Operation(operationId = "empleadosEditar", summary = "Editar empleado de una UOT")
    public ResponseEntity<ApiResponse<Void>> update(
            @PathVariable @Positive Long id,
            @Valid @RequestBody EmployeeRequests.Update body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.update(mapper.command(id, body), identities.resolve(authentication), metadata.resolve(request)),
                request
        );
    }

    @PostMapping("/{id}/retirar")
    @IdempotentOperation
    @PreAuthorize("@permissionGuard.hasUot(authentication,#body.uotId,'EMPLEADOS_RETIRAR')")
    @Operation(operationId = "empleadosRetirar", summary = "Retirar empleado de la UOT")
    public ResponseEntity<ApiResponse<Void>> retire(
            @PathVariable @Positive Long id,
            @Valid @RequestBody EmployeeRequests.Retire body,
            @Parameter(hidden = true) JwtAuthenticationToken authentication,
            @Parameter(hidden = true) HttpServletRequest request
    ) {
        return responses.from(
                useCase.retire(mapper.command(id, body), identities.resolve(authentication), metadata.resolve(request)),
                request
        );
    }
}
