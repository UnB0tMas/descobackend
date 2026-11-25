package com.franco.desco.adapter.in.web.report;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.application.report.service.ReportJobEventService;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/v1/reportes/trabajos")
public class ReportJobEventController {
    private final ReportJobEventService events;
    private final JwtSessionIdentityResolver identities;

    public ReportJobEventController(ReportJobEventService events, JwtSessionIdentityResolver identities) {
        this.events = events;
        this.identities = identities;
    }

    @GetMapping(value = "/eventos", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    public ResponseEntity<SseEmitter> subscribe(JwtAuthenticationToken auth) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .header("X-Accel-Buffering", "no")
                .body(events.subscribe(identities.resolve(auth)));
    }
}
