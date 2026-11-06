package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.time.Instant;

@RestController
@RequestMapping("/api/v1/gestion-productiva-general/fotos")
@SecurityRequirement(name="bearerAuth")
public class GpFotoController {
    private final GpFotoRepository repo;
    private final GpFotoStorage storage;
    private final JwtSessionIdentityResolver identities;
    public GpFotoController(GpFotoRepository repo, GpFotoStorage storage, JwtSessionIdentityResolver identities) {
        this.repo=repo;this.storage=storage;this.identities=identities;
    }
    @PostMapping(path="/eventos/{eventoId}",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(operationId="gpFotoSubir",summary="Adjuntar una fotografía a una actuación general")
    @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_CREAR') or @permissionGuard.has(authentication,'EVALUACIONES_CREAR') or @permissionGuard.has(authentication,'PREDIOS_EDITAR')")
    public ResponseEntity<ApiResponse<GpWebTypes.Id>> subir(@RequestParam long uotId,@PathVariable long eventoId,
      @RequestPart("archivo") MultipartFile archivo,@Parameter(hidden=true) JwtAuthenticationToken auth,
      @Parameter(hidden=true) HttpServletRequest request) throws IOException {
        var guardada=storage.guardar(archivo);
        try {
            long id=repo.registrar(identities.resolve(auth),uotId,eventoId,guardada.nombre(),guardada.mime(),guardada.bytes());
            return ResponseEntity.status(201).body(new ApiResponse<>(true,"GP_FOTO_CREADA","Fotografía guardada.",
               new GpWebTypes.Id(id),CorrelationIdFilter.correlationId(request),Instant.now()));
        } catch (RuntimeException ex) {
            storage.eliminar(guardada.nombre());
            throw ex;
        }
    }
    @GetMapping("/{fotoId}")
    @Operation(operationId="gpFotoVer",summary="Consultar fotografía autorizada de una actuación general")
    @PreAuthorize("@permissionGuard.has(authentication,'PREDIOS_VER')")
    public ResponseEntity<FileSystemResource> ver(@RequestParam long uotId,@PathVariable long fotoId,
      @Parameter(hidden=true) JwtAuthenticationToken auth) {
        var foto=repo.obtener(identities.resolve(auth),uotId,fotoId);
        if (foto==null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
           .header("X-Content-Type-Options", "nosniff")
           .contentType(MediaType.parseMediaType(foto.mime())).body(new FileSystemResource(storage.leer(foto.nombre())));
    }
}
