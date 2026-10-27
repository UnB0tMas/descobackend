package com.franco.desco.adapter.out.crypto;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

class Sha256RequestHashAdapterTest {

    @Test
    void debeSerDeterministaYThreadSafe() throws Exception {
        Sha256RequestHashAdapter adapter =
                new Sha256RequestHashAdapter();

        Callable<String> task =
                () -> adapter.sha256Hex(
                        "{\"accion\":\"REGISTRAR\",\"id\":10}"
                );

        try (var executor =
                     Executors.newFixedThreadPool(12)) {

            var futures =
                    executor.invokeAll(
                            java.util.Collections.nCopies(
                                    100,
                                    task
                            )
                    );

            Set<String> hashes =
                    new HashSet<>();

            for (var future : futures) {
                hashes.add(
                        future.get(
                                3,
                                TimeUnit.SECONDS
                        )
                );
            }

            assertThat(hashes).hasSize(1);
            assertThat(hashes.iterator().next())
                    .hasSize(64);
        }
    }

    @Test
    void payloadDistintoDebeProducirHashDistinto() {
        Sha256RequestHashAdapter adapter =
                new Sha256RequestHashAdapter();

        assertThat(
                adapter.sha256Hex("A")
        ).isNotEqualTo(
                adapter.sha256Hex("B")
        );
    }
}
