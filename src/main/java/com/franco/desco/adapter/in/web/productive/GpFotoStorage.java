package com.franco.desco.adapter.in.web.productive;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class GpFotoStorage {
    private static final int MAX = 5 * 1024 * 1024;
    private final Path carpeta;
    public GpFotoStorage(@Value("${desco.gp.fotos.directorio:./data/gestion-productiva}") String ruta) {
        this.carpeta = Path.of(ruta).toAbsolutePath().normalize();
    }
    public Guardada guardar(MultipartFile archivo) throws IOException {
        if (archivo.isEmpty() || archivo.getSize() > MAX) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La imagen no puede superar 5 MB.");
        }
        byte[] bytes = archivo.getBytes();
        if (bytes.length == 0 || bytes.length > MAX) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Imagen inválida.");
        String mime = detectarMime(bytes);
        if (mime == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Solo JPG, PNG o WebP.");
        Files.createDirectories(carpeta);
        String nombre = UUID.randomUUID() + (mime.equals("image/jpeg") ? ".jpg" : mime.equals("image/png") ? ".png" : ".webp");
        Path temp = Files.createTempFile(carpeta, "gp-", ".tmp");
        try {
            Files.write(temp, bytes);
            Files.move(temp, carpeta.resolve(nombre), StandardCopyOption.ATOMIC_MOVE);
        } finally {
            Files.deleteIfExists(temp);
        }
        return new Guardada(nombre, mime, bytes.length);
    }
    private static String detectarMime(byte[] b) {
        if (b.length > 3 && (b[0]&255)==255 && (b[1]&255)==216 && (b[2]&255)==255) return "image/jpeg";
        if (b.length > 8 && (b[0]&255)==137 && b[1]==80 && b[2]==78 && b[3]==71 && b[4]==13 && b[5]==10 && b[6]==26 && b[7]==10) return "image/png";
        if (b.length > 12 && b[0]==82 && b[1]==73 && b[2]==70 && b[3]==70 && b[8]==87 && b[9]==69 && b[10]==66 && b[11]==80) return "image/webp";
        return null;
    }
    public Path leer(String nombre) {
        if (nombre == null || !nombre.matches("[0-9a-fA-F-]{36}[.](jpg|png|webp)"))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Fotografía no disponible.");
        Path destino = carpeta.resolve(nombre).normalize();
        if (!destino.startsWith(carpeta) || !Files.isRegularFile(destino))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Fotografía no disponible.");
        return destino;
    }
    public void eliminar(String nombre) throws IOException { Files.deleteIfExists(carpeta.resolve(nombre)); }
    public record Guardada(String nombre, String mime, long bytes) {}
}
