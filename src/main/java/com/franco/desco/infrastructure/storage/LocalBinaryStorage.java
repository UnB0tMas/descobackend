package com.franco.desco.infrastructure.storage;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Stream;

@Component
public class LocalBinaryStorage {
    private static final Set<String> EXACT_MIME_TYPES = Set.of(
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "text/plain",
            "text/csv"
    );

    private final Path root;
    private final Path temporary;
    private final LocalStorageProperties properties;

    public LocalBinaryStorage(LocalStorageProperties properties) throws IOException {
        this.properties = properties;
        this.root = Path.of(properties.root()).toAbsolutePath().normalize();
        this.temporary = root.resolve(".tmp").normalize();
        Files.createDirectories(root);
        Files.createDirectories(temporary);
    }

    public StoredFile store(String storageKey, MultipartFile source) throws IOException {
        if (source == null || source.isEmpty()) throw new IllegalArgumentException("Seleccione un archivo para cargar.");
        if (source.getSize() <= 0 || source.getSize() > properties.maxFileBytes()) {
            throw new IllegalArgumentException("El archivo supera el tamaño permitido.");
        }

        String contentType = normalizeMime(source.getContentType());
        if (!allowedMime(contentType)) throw new IllegalArgumentException("El tipo de archivo no está permitido.");

        String originalName = safeOriginalName(source.getOriginalFilename());
        Path target = resolve(storageKey);
        Files.createDirectories(target.getParent());

        if (Files.exists(target)) {
            return describe(storageKey, target, originalName, contentType);
        }

        Path temp = Files.createTempFile(temporary, "upload-", ".part");
        try {
            MessageDigest digest = sha256();
            long bytes = 0;
            try (InputStream input = source.getInputStream(); OutputStream output = Files.newOutputStream(temp, StandardOpenOption.TRUNCATE_EXISTING)) {
                byte[] buffer = new byte[64 * 1024];
                int read;
                while ((read = input.read(buffer)) >= 0) {
                    if (read == 0) continue;
                    bytes += read;
                    if (bytes > properties.maxFileBytes()) throw new IllegalArgumentException("El archivo supera el tamaño permitido.");
                    digest.update(buffer, 0, read);
                    output.write(buffer, 0, read);
                }
            }
            try {
                Files.move(temp, target, StandardCopyOption.ATOMIC_MOVE);
            } catch (AtomicMoveNotSupportedException ignored) {
                Files.move(temp, target);
            }
            return new StoredFile(storageKey, originalName, contentType, bytes, HexFormat.of().formatHex(digest.digest()));
        } finally {
            Files.deleteIfExists(temp);
        }
    }

    public Resource resource(String storageKey) {
        Path path = resolve(storageKey);
        if (!Files.isRegularFile(path)) throw new IllegalArgumentException("El archivo físico ya no está disponible.");
        return new FileSystemResource(path);
    }

    public void deleteQuietly(String storageKey) {
        try {
            Files.deleteIfExists(resolve(storageKey));
        } catch (IOException ignored) {
            // La cola volverá a intentar la eliminación.
        }
    }

    public boolean delete(String storageKey) throws IOException {
        return Files.deleteIfExists(resolve(storageKey));
    }

    public int cleanupTemporaryFiles() {
        Instant limit = Instant.now().minus(properties.temporaryRetention());
        int removed = 0;
        try (Stream<Path> stream = Files.list(temporary)) {
            for (Path path : stream.toList()) {
                try {
                    if (Files.isRegularFile(path) && Files.getLastModifiedTime(path).toInstant().isBefore(limit) && Files.deleteIfExists(path)) removed++;
                } catch (IOException ignored) {
                    // Se intentará en la siguiente ejecución.
                }
            }
        } catch (IOException ignored) {
            return removed;
        }
        return removed;
    }

    public String deterministicKey(
            Long uotId,
            Long userId,
            java.util.UUID idempotencyKey
    ) {
        return deterministicKey(
                uotId,
                userId,
                idempotencyKey,
                "DOCUMENTO",
                "NINGUNO",
                null,
                null
        );
    }

    public String deterministicKey(
            Long uotId,
            Long userId,
            java.util.UUID idempotencyKey,
            String category,
            String targetType,
            Long targetId,
            String originalName
    ) {
        if (uotId == null || userId == null || idempotencyKey == null) {
            throw new IllegalArgumentException(
                    "No se pudo construir la clave de almacenamiento."
            );
        }

        String normalizedCategory = safePathSegment(
                category,
                "documento"
        );
        String normalizedTarget = safePathSegment(
                targetType,
                "ninguno"
        );

        String targetFolder =
                switch (normalizedTarget) {
                    case "bien" ->
                            targetId == null
                                    ? "bien"
                                    : "bien-" + targetId;
                    case "producto" ->
                            targetId == null
                                    ? "producto"
                                    : "producto-" + targetId;
                    default ->
                            "general";
                };

        return "files/uot-"
                + uotId
                + "/"
                + targetFolder
                + "/"
                + normalizedCategory
                + "/user-"
                + userId
                + "/"
                + idempotencyKey
                + safeExtension(originalName);
    }

    private StoredFile describe(String key, Path target, String originalName, String contentType) throws IOException {
        MessageDigest digest = sha256();
        try (InputStream input = Files.newInputStream(target)) {
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = input.read(buffer)) >= 0) if (read > 0) digest.update(buffer, 0, read);
        }
        return new StoredFile(key, originalName, contentType, Files.size(target), HexFormat.of().formatHex(digest.digest()));
    }

    private Path resolve(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) throw new IllegalArgumentException("La clave del archivo no es válida.");
        Path path = root.resolve(storageKey.replace('\\', '/')).normalize();
        if (!path.startsWith(root) || path.startsWith(temporary)) throw new IllegalArgumentException("La ruta del archivo no es válida.");
        return path;
    }

    private static String safePathSegment(
            String value,
            String fallback
    ) {
        String normalized =
                value == null
                        ? ""
                        : value.trim().toLowerCase(Locale.ROOT);

        normalized = normalized.replaceAll(
                "[^a-z0-9_-]+",
                "-"
        );
        normalized = normalized.replaceAll(
                "^-+|-+$",
                ""
        );

        return normalized.isBlank()
                ? fallback
                : normalized;
    }

    private static String safeExtension(String originalName) {
        if (originalName == null || originalName.isBlank()) {
            return "";
        }

        String name = safeOriginalName(originalName);
        int separator = name.lastIndexOf('.');

        if (separator < 0 || separator == name.length() - 1) {
            return "";
        }

        String extension =
                name.substring(separator + 1)
                        .toLowerCase(Locale.ROOT);

        if (!extension.matches("[a-z0-9]{1,10}")) {
            return "";
        }

        return "." + extension;
    }

    private static String safeOriginalName(String value) {
        if (value == null || value.isBlank()) return "archivo";
        String name = Path.of(value.replace('\\', '/')).getFileName().toString().trim();
        return name.length() <= 255 ? name : name.substring(name.length() - 255);
    }

    private static String normalizeMime(String value) {
        if (value == null || value.isBlank()) return "application/octet-stream";
        int separator = value.indexOf(';');
        return (separator >= 0 ? value.substring(0, separator) : value).trim().toLowerCase(Locale.ROOT);
    }

    private static boolean allowedMime(String mime) {
        return mime.startsWith("image/") || EXACT_MIME_TYPES.contains(mime);
    }

    private static MessageDigest sha256() {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (java.security.NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 no está disponible.", exception);
        }
    }

    public record StoredFile(String storageKey, String originalName, String contentType, long size, String sha256Hex) {}
}
