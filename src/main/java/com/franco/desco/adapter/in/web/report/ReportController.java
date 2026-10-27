package com.franco.desco.adapter.in.web.report;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.*;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.report.port.in.ReportUseCase;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/reportes")
@Tag(name="Reportes e indicadores",description="Catálogo y consulta de reportes autorizados. Los datos se construyen en SQL Server.")
@SecurityRequirement(name=OpenApiConstants.BEARER_AUTH)
@Validated
public class ReportController {
    private final ReportUseCase useCase;private final ReportWebMapper mapper;private final ApiResponseFactory responses;
    private final ClientRequestContextResolver metadata;private final JwtSessionIdentityResolver identities;
    public ReportController(ReportUseCase u,ReportWebMapper m,ApiResponseFactory r,ClientRequestContextResolver x,JwtSessionIdentityResolver i){useCase=u;mapper=m;responses=r;metadata=x;identities=i;}

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_LISTAR')")
    @Operation(operationId="reportesListarCatalogo",summary="Listar reportes autorizados")
    public ResponseEntity<ApiResponse<List<ReportResponses.CatalogItem>>>catalog(@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.catalog(identities.resolve(a),metadata.resolve(r)),r,l->l.stream().map(mapper::response).toList());
    }

    @GetMapping("/datos")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_VER')")
    @Operation(operationId="reportesVerDatos",summary="Consultar datos de un reporte")
    public ResponseEntity<ApiResponse<ReportResponses.Data>>data(@RequestParam@NotBlank String reporte,@RequestParam(required=false)LocalDate fechaDesde,@RequestParam(required=false)LocalDate fechaHasta,@RequestParam(required=false)Long campaniaVentaId,@RequestParam(required=false)Long operativoVentaId,@RequestParam(required=false)Long zonaProductivaId,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.data(mapper.data(reporte,fechaDesde,fechaHasta,campaniaVentaId,operativoVentaId,zonaProductivaId),identities.resolve(a),metadata.resolve(r)),r,mapper::response);
    }

    @GetMapping("/exportacion")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_EXPORTAR')")
    @Operation(operationId="reportesExportarDatos",summary="Preparar datos autorizados para exportación",description="Devuelve los datos autorizados por el PA. El formato Excel/PDF puede construirse posteriormente en el cliente o en un adaptador específico sin mover la lógica del reporte a Java.")
    public ResponseEntity<ApiResponse<ReportResponses.Data>>export(@RequestParam@NotBlank String reporte,@RequestParam(required=false)LocalDate fechaDesde,@RequestParam(required=false)LocalDate fechaHasta,@RequestParam(required=false)Long campaniaVentaId,@RequestParam(required=false)Long operativoVentaId,@RequestParam(required=false)Long zonaProductivaId,@Parameter(hidden=true)JwtAuthenticationToken a,@Parameter(hidden=true)HttpServletRequest r){
        return responses.from(useCase.export(mapper.export(reporte,fechaDesde,fechaHasta,campaniaVentaId,operativoVentaId,zonaProductivaId),identities.resolve(a),metadata.resolve(r)),r,mapper::response);
    }
}
