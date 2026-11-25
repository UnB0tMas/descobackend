package com.franco.desco.adapter.out.sqlserver.shared;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/** Evita que futuras ejecuciones SQL directas de PA queden fuera de la consola. */
class PaInvocationCoverageTest {
    private static final Pattern RAW_PA = Pattern.compile(
            "(?i)\\bEXEC\\s+(?:\\[[a-z0-9_]+\\]|[a-z_][a-z0-9_]*)"
                    + "\\.(?:\\[)?PA_[a-z0-9_]+"
    );

    @Test
    void lasInvocacionesDirectasAProcedimientosTienenTrazabilidad() throws IOException {
        Path sources = Path.of("src", "main", "java");
        assertThat(sources).exists();

        List<String> missing = new ArrayList<>();
        try (Stream<Path> files = Files.walk(sources)) {
            for (Path file : files.filter(p -> p.toString().endsWith(".java")).toList()) {
                String java = Files.readString(file);
                boolean executesDirectly = RAW_PA.matcher(java).find()
                        || java.contains(".prepareCall(")
                        || java.contains(".withProcedureName(");
                boolean traced = java.contains("PaTrace.call(")
                        || java.contains("PaTrace.run(")
                        || java.contains("LoggedSimpleJdbcCall")
                        || java.contains("SqlServerPaExecutor")
                        || java.contains("SqlServerPaFactory")
                        || java.contains("SqlProcedureExecutor");

                if (executesDirectly && !traced && !file.getFileName().toString().equals("PaTrace.java")) {
                    missing.add(file.toString());
                }
            }
        }
        assertThat(missing)
                .as("Cada ejecutor directo de PA debe usar la traza central o delegar en el ejecutor común")
                .isEmpty();
    }
}
