package com.franco.desco.contract;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertTrue;

/** Detecta versiones Flyway duplicadas antes de desplegar migraciones SQL Server. */
class FlywayMigrationVersionTest {
    private static final Pattern VERSION = Pattern.compile("^V([0-9]+(?:_[0-9]+)*)__.+\\.sql$");

    @Test
    void cadaMigracionVersionadaTieneUnNumeroUnico() throws IOException {
        Path directory = Path.of("src/main/resources/db/migration");
        Map<String, String> filesByVersion = new HashMap<>();
        StringBuilder collisions = new StringBuilder();
        try (var paths = Files.list(directory)) {
            paths.filter(Files::isRegularFile).forEach(file -> {
                var matcher = VERSION.matcher(file.getFileName().toString());
                if (matcher.matches()) {
                    String version = matcher.group(1).replace('_', '.');
                    String previous = filesByVersion.putIfAbsent(version, file.getFileName().toString());
                    if (previous != null) {
                        collisions.append(version).append(": ").append(previous)
                                .append(" y ").append(file.getFileName()).append(';');
                    }
                }
            });
        }
        assertTrue(collisions.isEmpty(), () -> "Versiones Flyway duplicadas: " + collisions);
    }
}
