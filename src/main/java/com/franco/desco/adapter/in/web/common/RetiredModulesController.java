package com.franco.desco.adapter.in.web.common;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.Instant;

/** Old bookmarks and clients receive an explicit retirement response without running stock operations. */
@io.swagger.v3.oas.annotations.Hidden
@RestController
public class RetiredModulesController {
    @RequestMapping({"/api/v1/recursos-programados","/api/v1/recursos-programados/**",
        "/api/v1/produccion","/api/v1/produccion/**","/api/v1/recursos-operativos/programados/**"})
    public ResponseEntity<ApiResponse<Void>> retired(HttpServletRequest request) {
        return ResponseEntity.status(410).body(new ApiResponse<>(false,"MODULO_RETIRADO",
            "Esta funcionalidad fue retirada del sistema.",null,CorrelationIdFilter.correlationId(request),Instant.now()));
    }
}
