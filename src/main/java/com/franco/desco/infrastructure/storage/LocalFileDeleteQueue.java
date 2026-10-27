package com.franco.desco.infrastructure.storage;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.Instant;
import java.util.Base64;
import java.util.Comparator;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Stream;

@Component
public class LocalFileDeleteQueue {
    private static final Logger log = LoggerFactory.getLogger(LocalFileDeleteQueue.class);
    private static final long MAX_BACKOFF_SECONDS = 3600L;

    private final LocalBinaryStorage storage;
    private final Path queueDirectory;
    private final AtomicBoolean running = new AtomicBoolean(false);

    public LocalFileDeleteQueue(LocalBinaryStorage storage, LocalStorageProperties properties) throws IOException {
        this.storage = storage;
        Path root = Path.of(properties.root()).toAbsolutePath().normalize();
        this.queueDirectory = root.resolve(".delete-queue").normalize();
        Files.createDirectories(queueDirectory);
    }

    public void enqueue(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) return;
        try {
            Path job = jobPath(storageKey);
            if (!Files.exists(job)) write(job, new Job(storageKey, 0, Instant.now()));
        } catch (IOException exception) {
            log.warn("[STORAGE] No se pudo persistir la eliminación pendiente key={}", storageKey);
        }
    }

    @Scheduled(fixedDelayString = "${app.storage.delete-queue-delay-ms:5000}")
    public void process() {
        if (!running.compareAndSet(false, true)) return;
        try (Stream<Path> stream = Files.list(queueDirectory)) {
            for (Path path : stream
                    .filter(Files::isRegularFile)
                    .filter(value -> value.getFileName().toString().endsWith(".job"))
                    .sorted(Comparator.comparing(Path::toString))
                    .limit(100)
                    .toList()) {
                process(path);
            }
        } catch (IOException exception) {
            log.warn("[STORAGE] No se pudo leer la cola persistente de eliminación.");
        } finally {
            running.set(false);
        }
    }

    @Scheduled(fixedDelayString = "${app.storage.temp-cleanup-delay-ms:3600000}")
    public void cleanupTemporaryFiles() {
        int removed = storage.cleanupTemporaryFiles();
        if (removed > 0) log.info("[STORAGE] Temporales retirados={}", removed);
    }

    private void process(Path path) {
        Job job;
        try {
            job = read(path);
        } catch (Exception exception) {
            log.warn("[STORAGE] Trabajo de eliminación inválido file={}", path.getFileName());
            moveCorrupt(path);
            return;
        }

        if (job.nextAttempt().isAfter(Instant.now())) return;

        try {
            storage.delete(job.storageKey());
            Files.deleteIfExists(path);
        } catch (Exception exception) {
            int attempts = job.attempts() + 1;
            long seconds = Math.min(MAX_BACKOFF_SECONDS, 1L << Math.min(attempts, 12));
            try {
                write(path, new Job(job.storageKey(), attempts, Instant.now().plusSeconds(seconds)));
            } catch (IOException persistFailure) {
                log.warn("[STORAGE] No se pudo actualizar el reintento de eliminación key={}", job.storageKey());
            }
            log.warn("[STORAGE] Eliminación local pendiente intento={} key={}", attempts, job.storageKey());
        }
    }

    private Path jobPath(String storageKey) {
        UUID id = UUID.nameUUIDFromBytes(storageKey.getBytes(StandardCharsets.UTF_8));
        return queueDirectory.resolve(id + ".job");
    }

    private void write(Path target, Job job) throws IOException {
        String key = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(job.storageKey().getBytes(StandardCharsets.UTF_8));
        String content = key + "\n" + job.attempts() + "\n" + job.nextAttempt().toEpochMilli() + "\n";
        Path temporary = Files.createTempFile(queueDirectory, ".delete-", ".tmp");
        try {
            Files.writeString(temporary, content, StandardCharsets.UTF_8, StandardOpenOption.TRUNCATE_EXISTING);
            try {
                Files.move(temporary, target, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
            } catch (AtomicMoveNotSupportedException ignored) {
                Files.move(temporary, target, StandardCopyOption.REPLACE_EXISTING);
            }
        } finally {
            Files.deleteIfExists(temporary);
        }
    }

    private Job read(Path path) throws IOException {
        var lines = Files.readAllLines(path, StandardCharsets.UTF_8);
        if (lines.size() < 3) throw new IOException("Trabajo incompleto.");
        String key = new String(Base64.getUrlDecoder().decode(lines.get(0)), StandardCharsets.UTF_8);
        int attempts = Integer.parseInt(lines.get(1));
        Instant next = Instant.ofEpochMilli(Long.parseLong(lines.get(2)));
        return new Job(key, attempts, next);
    }

    private void moveCorrupt(Path path) {
        try {
            Files.move(path, path.resolveSibling(path.getFileName() + ".invalid"), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException ignored) {
            // Se deja el archivo para inspección manual.
        }
    }

    private record Job(String storageKey, int attempts, Instant nextAttempt) {}
}
