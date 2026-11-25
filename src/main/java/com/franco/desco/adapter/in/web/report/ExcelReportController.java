package com.franco.desco.adapter.in.web.report;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ClientRequestContextResolver;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.infrastructure.storage.LocalBinaryStorage;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.core.io.Resource;
import org.springframework.dao.DataAccessException;
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
@RequestMapping("/api/v1/reportes/excel")
@Tag(name = "Reportes Excel", description = "Informes descargables autorizados")
@SecurityRequirement(name = "bearerAuth")
public class ExcelReportController {
    private static final String PROC = "{call reporte.PA_Excel_Operacion(?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;
    private final JwtSessionIdentityResolver identities;
    private final ClientRequestContextResolver metadata;
    private final LocalBinaryStorage storage;

    public ExcelReportController(JdbcTemplate jdbc, JsonMapper json, JwtSessionIdentityResolver identities,
                                 ClientRequestContextResolver metadata, LocalBinaryStorage storage) {
        this.jdbc = jdbc; this.json = json; this.identities = identities;
        this.metadata = metadata; this.storage = storage;
    }

    public record Request(@NotBlank String codigo, LocalDate desde, LocalDate hasta,
                          Long almacenId, Long predioId, @NotNull UUID clave) {}
    private record Reply(boolean ok, int status, String message, Object data) {}

    @GetMapping("/catalogo")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    @Operation(operationId="excelReportesCatalogo",summary="Reportes disponibles")
    public ResponseEntity<?> catalogo(JwtAuthenticationToken a,HttpServletRequest r) {
        return response(call("CATALOGO",Map.of(),a,r));
    }

    @GetMapping("/segmentadores")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    @Operation(operationId="excelReportesSegmentadores",summary="Filtros autorizados")
    public ResponseEntity<?> segmentadores(JwtAuthenticationToken a,HttpServletRequest r) {
        return response(call("SEGMENTADORES",Map.of(),a,r));
    }

    @PostMapping("/trabajos")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_EXPORTAR') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    @Operation(operationId="excelReportesSolicitar",summary="Solicitar Excel")
    public ResponseEntity<?> generar(@Valid @RequestBody Request request, JwtAuthenticationToken a,HttpServletRequest r) {
        Map<String,Object> datos = new LinkedHashMap<>();
        datos.put("codigo",request.codigo());
        datos.put("desde",request.desde()==null?null:request.desde().toString());
        datos.put("hasta",request.hasta()==null?null:request.hasta().toString());
        datos.put("almacenId",request.almacenId());datos.put("predioId",request.predioId());
        datos.put("clave",request.clave());
        return response(call("CREAR",datos,a,r));
    }

    @GetMapping("/trabajos")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    @Operation(operationId="excelReportesTrabajos",summary="Historial de Excel")
    public ResponseEntity<?> trabajos(JwtAuthenticationToken a,HttpServletRequest r) {
        return response(call("LISTAR",Map.of(),a,r));
    }

    @PostMapping("/trabajos/{id}/visto")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    @Operation(operationId="excelReportesVisto",summary="Marcar reporte leído")
    public ResponseEntity<?> visto(@PathVariable long id,JwtAuthenticationToken a,HttpServletRequest r) {
        return response(call("VISTO",Map.of("id",id),a,r));
    }

    @GetMapping("/trabajos/{id}/archivo")
    @PreAuthorize("@permissionGuard.has(authentication,'REPORTES_CONTROL_VER') and @permissionGuard.has(authentication,'REPORTES_EXPORTAR') and @permissionGuard.has(authentication,'REPORTES_LISTAR')")
    @Operation(operationId="excelReportesDescargar",summary="Descargar Excel")
    public ResponseEntity<?> archivo(@PathVariable long id,JwtAuthenticationToken a,HttpServletRequest r) {
        Reply result=call("DESCARGAR",Map.of("id",id),a,r);
        if (!result.ok() || !(result.data() instanceof Map<?,?> data)) return response(result);
        String key = String.valueOf(data.get("clave"));
        if (!key.equals("exports/"+id+".xlsx"))
            return ResponseEntity.status(404).body(Map.of("exitoso",false,"mensaje","Archivo no disponible."));
        try {
            Resource file = storage.resource(key);
            String name = "Reporte-"+String.valueOf(data.get("codigo"))+"-"+id+".xlsx";
            return ResponseEntity.ok().contentType(MediaType.parseMediaType(
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=\""+name+"\"")
                .header(HttpHeaders.CACHE_CONTROL,"no-store")
                .body(file);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(Map.of("exitoso",false,"mensaje","Archivo no disponible."));
        }
    }

    private ResponseEntity<?> response(Reply r) {
        Map<String,Object> body=new LinkedHashMap<>();
        body.put("exitoso",r.ok());body.put("mensaje",r.message());body.put("datos",r.data());
        return ResponseEntity.status(r.status()).body(body);
    }

    private Reply call(String action,Map<String,?> data,JwtAuthenticationToken a,HttpServletRequest r) {
        try {
            SessionIdentity identity = identities.resolve(a);
            RequestMetadata m=metadata.resolve(r);
            Map<String,Object> context=new LinkedHashMap<>();
            context.put("sesionPublicaId",identity.sesionPublicaId());
            context.put("correlacionId",m.correlacionId());context.put("solicitudId",m.solicitudId());
            context.put("claveIdempotencia",m.claveIdempotencia());context.put("ip",m.ip());
            context.put("endpoint",m.endpoint());context.put("userAgent",m.userAgent());context.put("deviceId",m.deviceId());
            String payload=json.writeValueAsString(Map.of("contexto",context,"datos",data));
            return PaTrace.call(PROC, action, () -> jdbc.execute(con->{
                CallableStatement st=con.prepareCall(PROC);
                st.setString(1,action);st.setNString(2,payload);
                st.registerOutParameter(3,Types.LONGNVARCHAR);
                st.registerOutParameter(4,Types.BIT);st.registerOutParameter(5,Types.NVARCHAR);
                st.registerOutParameter(6,Types.SMALLINT);
                return st;
            },(CallableStatement st)->{
                st.execute();String raw=st.getNString(3);
                Object value=(raw==null||raw.isBlank())?null:json.readValue(raw,Object.class);
                int code=st.getInt(6);
                return new Reply(st.getBoolean(4),code>=200&&code<600?code:400,
                    st.getNString(5),value);
            }), result -> result != null && result.ok(), result -> result == null ? "Respuesta vacía" : result.message());
        } catch (DataAccessException e) {
            return new Reply(false,503,"No se pudo consultar el reporte.",null);
        } catch (RuntimeException e) {
            return new Reply(false,400,"No se pudo completar la solicitud.",null);
        }
    }
}
