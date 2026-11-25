package com.franco.desco.adapter.in.web.report;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.infrastructure.storage.LocalBinaryStorage;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/reportes")
public class ApappssReportController {
    private static final org.slf4j.Logger LOG = org.slf4j.LoggerFactory.getLogger(ApappssReportController.class);
    private final JdbcTemplate jdbc;
    private final JsonMapper json;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    private final LocalBinaryStorage storage;

    public ApappssReportController(JdbcTemplate jdbc, JsonMapper json, JwtSessionIdentityResolver identities,
                                   ClientRequestContextResolver metadata, LocalBinaryStorage storage) {
        this.jdbc = jdbc; this.json = json; this.identities = identities;
        this.metadata = metadata; this.storage = storage;
    }

    public record Solicitud(@NotBlank String tipo, @NotBlank String formato, LocalDate desde, LocalDate hasta,
                            Long convenioId, Long socioId, Long predioId, Long campaniaId, @NotNull UUID clave) {}
    private record Resultado(boolean ok, int http, String mensaje, Object datos) {}

    @GetMapping("/apappss/filtros")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'DASHBOARD_APAPPSS_VER')")
    public ResponseEntity<?> filtrosBi(JwtAuthenticationToken a, HttpServletRequest r) {
        return respond(call("{call reporte.PA_Apappss_Analytics(?,?,?,?,?,?)}", "FILTROS", r.getParameter("convenioId") == null ? Map.of() : Map.of("convenioId", r.getParameter("convenioId")), a, r));
    }

    @GetMapping("/apappss/resumen")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'DASHBOARD_APAPPSS_VER')")
    public ResponseEntity<?> resumen(@RequestParam String tab, @RequestParam(required = false) LocalDate desde,
                                      @RequestParam(required = false) LocalDate hasta,
                                      @RequestParam(required = false) Long convenioId,
                                      @RequestParam(required = false) Long socioId,
                                      @RequestParam(required = false) Long predioId,
                                      @RequestParam(required = false) Long campaniaId,
                                      JwtAuthenticationToken a, HttpServletRequest r) {
        Map<String,Object> filtros=new LinkedHashMap<>();
        filtros.put("tab",tab);filtros.put("desde",desde);filtros.put("hasta",hasta);
        filtros.put("convenioId",convenioId);filtros.put("socioId",socioId);
        filtros.put("predioId",predioId);filtros.put("campaniaId",campaniaId);
        return respond(call("{call reporte.PA_Apappss_Analytics(?,?,?,?,?,?)}", "RESUMEN", filtros, a, r));
    }

    @GetMapping("/especiales/catalogo")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    public ResponseEntity<?> catalogo(JwtAuthenticationToken a,HttpServletRequest r) {
        return respond(call("{call reporte.PA_InformesEspeciales_Operacion(?,?,?,?,?,?)}", "CATALOGO", Map.of(), a, r));
    }

    @GetMapping("/especiales/filtros")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    public ResponseEntity<?> filtros(JwtAuthenticationToken a,HttpServletRequest r) {
        return respond(call("{call reporte.PA_InformesEspeciales_Operacion(?,?,?,?,?,?)}", "FILTROS", Map.of(), a, r));
    }

    @PostMapping("/especiales/trabajos")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_EXPORTAR')")
    public ResponseEntity<?> crear(@Valid @RequestBody Solicitud req, JwtAuthenticationToken a,HttpServletRequest r) {
        Map<String,Object> d=new LinkedHashMap<>();
        d.put("tipo",req.tipo());d.put("formato",req.formato());d.put("desde",req.desde());d.put("hasta",req.hasta());
        d.put("convenioId",req.convenioId());d.put("socioId",req.socioId());d.put("predioId",req.predioId());
        d.put("campaniaId",req.campaniaId());d.put("clave",req.clave());
        return respond(call("{call reporte.PA_InformesEspeciales_Operacion(?,?,?,?,?,?)}", "CREAR", d, a, r));
    }

    @GetMapping("/especiales/trabajos")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    public ResponseEntity<?> trabajos(JwtAuthenticationToken a,HttpServletRequest r) {
        return respond(call("{call reporte.PA_InformesEspeciales_Operacion(?,?,?,?,?,?)}", "LISTAR", Map.of(), a, r));
    }

    @PostMapping("/especiales/trabajos/{id}/visto")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    public ResponseEntity<?> visto(@PathVariable long id,JwtAuthenticationToken a,HttpServletRequest r) {
        return respond(call("{call reporte.PA_InformesEspeciales_Operacion(?,?,?,?,?,?)}", "VISTO", Map.of("id",id), a, r));
    }

    @GetMapping("/especiales/trabajos/{id}/archivo")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_EXPORTAR')")
    public ResponseEntity<?> archivo(@PathVariable long id,JwtAuthenticationToken a,HttpServletRequest r) {
        Resultado result=call("{call reporte.PA_InformesEspeciales_Operacion(?,?,?,?,?,?)}", "DESCARGAR", Map.of("id",id), a, r);
        if (!result.ok() || !(result.datos() instanceof Map<?,?> file)) return respond(result);
        String format=String.valueOf(file.get("formato")).toLowerCase();
        String key=String.valueOf(file.get("clave"));
        if (!format.matches("xlsx|pdf|docx") || !key.equals("reports-special/"+id+"."+format))
            return ResponseEntity.status(404).body(Map.of("exitoso",false,"mensaje","Archivo no disponible."));
        try {
            Resource resource=storage.resource(key);
            String mime=switch(format) {
                case "pdf" -> "application/pdf";
                case "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
                default -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            };
            return ResponseEntity.ok().contentType(MediaType.parseMediaType(mime))
                .header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=\"Informe-"+id+"."+format+"\"")
                .header(HttpHeaders.CACHE_CONTROL,"no-store")
                .body(resource);
        } catch(IllegalArgumentException ignored) {
            return ResponseEntity.status(404).body(Map.of("exitoso",false,"mensaje","Archivo no disponible."));
        }
    }

    private ResponseEntity<?> respond(Resultado r) {
        Map<String,Object> body=new LinkedHashMap<>();
        body.put("exitoso",r.ok());body.put("mensaje",r.mensaje());body.put("datos",r.datos());
        return ResponseEntity.status(r.http()).body(body);
    }

    private Resultado call(String procedure,String action,Map<String,?> data,JwtAuthenticationToken auth,HttpServletRequest request) {
        try {
            SessionIdentity identity=identities.resolve(auth);
            RequestMetadata m=metadata.resolve(request);
            Map<String,Object> contexto=new LinkedHashMap<>();
            contexto.put("sesionPublicaId",identity.sesionPublicaId());contexto.put("correlacionId",m.correlacionId());
            contexto.put("solicitudId",m.solicitudId());contexto.put("claveIdempotencia",m.claveIdempotencia());
            contexto.put("ip",m.ip());contexto.put("endpoint",m.endpoint());
            contexto.put("userAgent",m.userAgent());contexto.put("deviceId",m.deviceId());
            String jsonPayload=json.writeValueAsString(Map.of("contexto",contexto,
                procedure.contains("Analytics")?"filtros":"datos",data));
            return PaTrace.call(procedure, action, () -> jdbc.execute(connection -> {
                CallableStatement st=connection.prepareCall(procedure);
                st.setString(1,action);st.setNString(2,jsonPayload);
                st.registerOutParameter(3,Types.LONGNVARCHAR);st.registerOutParameter(4,Types.BIT);
                st.registerOutParameter(5,Types.NVARCHAR);st.registerOutParameter(6,Types.SMALLINT);
                return st;
            },(CallableStatement st) -> {
                st.execute();String raw=st.getNString(3);
                Object value=(raw==null||raw.isBlank())?null:json.readValue(raw,Object.class);
                int http=st.getInt(6);
                boolean ok=st.getBoolean(4);
                if (http >= 500) {
                    LOG.error("PA de reportes devolvió error: accion={}, procedimiento={}, correlacionId={}, http={}",
                            action, procedure, m.correlacionId(), http);
                    if (procedure.contains("PA_Apappss_Analytics") && m.correlacionId() != null) {
                        try (var consulta = st.getConnection().prepareStatement(
                                "SELECT TOP(1) numero_error, procedimiento, linea FROM auditoria.ErrorBaseDatos " +
                                "WHERE correlacion_id=CONVERT(UNIQUEIDENTIFIER,?) ORDER BY fecha_utc DESC")) {
                            consulta.setString(1, m.correlacionId().toString());
                            try (var detalle = consulta.executeQuery()) {
                                if (detalle.next()) {
                                    LOG.error("Error SQL APAPPSS: correlacionId={}, numero={}, procedimiento={}, linea={}",
                                            m.correlacionId(), detalle.getInt(1), detalle.getString(2), detalle.getInt(3));
                                }
                            }
                        } catch (java.sql.SQLException diagnosticoError) {
                            LOG.warn("No fue posible consultar la auditoría APAPPSS: correlacionId={}", m.correlacionId());
                        }
                    }
                }
                if (ok && "RESUMEN".equals(action) && procedure.contains("PA_Apappss_Analytics")) {
                    if (!(value instanceof Map<?,?> payload)
                            || !(payload.get("indicadores") instanceof java.util.List<?> indicators)
                            || indicators.size()!=4 || !(payload.get("puntos") instanceof java.util.List<?>)) {
                        LOG.error("Respuesta incompleta del dashboard APAPPSS: tab={}, convenioId={}, correlacionId={}, datosTipo={}",
                                data.get("tab"), data.get("convenioId"), m.correlacionId(),
                                value==null ? "null" : value.getClass().getSimpleName());
                        return new Resultado(false,502,"No se pudo cargar la información.",null);
                    }
                }
                return new Resultado(ok,http>=200&&http<600?http:400,st.getNString(5),value);
            }), result -> result != null && result.ok(), result -> result == null ? "Respuesta vacía" : result.mensaje());
        } catch(RuntimeException e) {
            LOG.error("Error consultando reportes: accion={}, procedimiento={}, endpoint={}",
                    action, procedure, request.getRequestURI(), e);
            return new Resultado(false,503,"No se pudo completar la consulta.",null);
        }
    }
}
