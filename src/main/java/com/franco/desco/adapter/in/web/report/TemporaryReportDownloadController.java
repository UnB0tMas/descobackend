package com.franco.desco.adapter.in.web.report;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import com.franco.desco.application.report.service.TemporaryReportService;
import com.franco.desco.application.shared.PersistenceResult;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/reportes")
@SecurityRequirement(name = OpenApiConstants.BEARER_AUTH)
@Validated
public class TemporaryReportDownloadController {
    private final TemporaryReportService reports;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;

    public TemporaryReportDownloadController(TemporaryReportService reports, JwtSessionIdentityResolver identities,
                                             ClientRequestContextResolver metadata) {
        this.reports = reports;
        this.identities = identities;
        this.metadata = metadata;
    }

    @PostMapping("/excel/trabajos/{id}/confirmar-descarga")
    @Operation(operationId = "excelReportesConfirmarDescarga", summary = "Confirmar entrega de Excel temporal")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR') and @permissionGuard.has(authentication,'REPORTES_EXPORTAR')")
    public ResponseEntity<?> confirmExcel(@PathVariable @Positive long id,
                                           JwtAuthenticationToken auth, HttpServletRequest request) {
        return response(reports.confirm("EXCEL", id, identities.resolve(auth), metadata.resolve(request)));
    }

    @PostMapping("/especiales/trabajos/{id}/confirmar-descarga")
    @Operation(operationId = "informesEspecialesConfirmarDescarga", summary = "Confirmar entrega de informe temporal")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR') and @permissionGuard.has(authentication,'REPORTES_EXPORTAR')")
    public ResponseEntity<?> confirmSpecial(@PathVariable @Positive long id,
                                             JwtAuthenticationToken auth, HttpServletRequest request) {
        return response(reports.confirm("ESPECIAL", id, identities.resolve(auth), metadata.resolve(request)));
    }

    private ResponseEntity<?> response(PersistenceResult<Void> result) {
        return ResponseEntity.status(result.httpSugerido()).body(Map.of(
                "exitoso", result.exitoso(),
                "mensaje", result.mensaje()));
    }
}
