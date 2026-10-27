package com.franco.desco.adapter.in.web.audit;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.common.pagination.PageResponse;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.audit.port.in.AuditUseCase;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/auditoria")
@Tag(name="Auditoría",description="Consulta y exportación de trazabilidad, cambios de estado, sesión y dispositivo.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class AuditController {
    private final AuditUseCase useCase;private final AuditWebMapper mapper;private final ApiResponseFactory responses;private final ClientRequestContextResolver metadata;private final JwtSessionIdentityResolver identities;
    public AuditController(AuditUseCase u,AuditWebMapper m,ApiResponseFactory r,ClientRequestContextResolver x,JwtSessionIdentityResolver i){useCase=u;mapper=m;responses=r;metadata=x;identities=i;}

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'AUDITORIA_LISTAR')")
    @Operation(operationId="auditoriaListar",summary="Listar eventos de auditoría")
    public ResponseEntity<ApiResponse<PageResponse<AuditResponses.Summary>>>list(
            @RequestParam(required=false)LocalDate fechaDesde,@RequestParam(required=false)LocalDate fechaHasta,@RequestParam(required=false)Long usuarioId,
            @RequestParam(required=false)Integer moduloId,@RequestParam(required=false)String accion,@RequestParam(required=false)String esquemaEntidad,
            @RequestParam(required=false)String nombreEntidad,@RequestParam(required=false)String resultado,
            @RequestParam(defaultValue="1")@Min(1)int pagina,@RequestParam(defaultValue="20")@Min(1)@Max(100)int tamano,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        var f=mapper.filter(fechaDesde,fechaHasta,usuarioId,moduloId,accion,esquemaEntidad,nombreEntidad,resultado);
        return responses.from(useCase.list(mapper.list(pagina,tamano,f),identities.resolve(a),metadata.resolve(r)),r,p->new PageResponse<>(p.items().stream().map(mapper::response).toList(),p.pagina(),p.tamanio(),p.totalRegistros(),p.totalPaginas()));
    }

    @GetMapping("/{id}")
    @PreAuthorize("@permissionGuard.has(authentication,'AUDITORIA_VER')")
    @Operation(operationId="auditoriaVer",summary="Ver evento de auditoría")
    public ResponseEntity<ApiResponse<AuditResponses.Detail>>get(@PathVariable Long id,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.get(mapper.get(id),identities.resolve(a),metadata.resolve(r)),r,mapper::response);
    }

    @GetMapping("/exportacion")
    @PreAuthorize("@permissionGuard.has(authentication,'AUDITORIA_EXPORTAR')")
    @Operation(operationId="auditoriaExportar",summary="Preparar datos de auditoría para exportación")
    public ResponseEntity<ApiResponse<List<AuditResponses.ExportRow>>>export(
            @RequestParam(required=false)LocalDate fechaDesde,@RequestParam(required=false)LocalDate fechaHasta,@RequestParam(required=false)Long usuarioId,
            @RequestParam(required=false)Integer moduloId,@RequestParam(required=false)String accion,@RequestParam(required=false)String esquemaEntidad,
            @RequestParam(required=false)String nombreEntidad,@RequestParam(required=false)String resultado,
            @Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        var f=mapper.filter(fechaDesde,fechaHasta,usuarioId,moduloId,accion,esquemaEntidad,nombreEntidad,resultado);
        return responses.from(useCase.export(mapper.export(f),identities.resolve(a),metadata.resolve(r)),r,l->l.stream().map(mapper::response).toList());
    }
}
