package com.franco.desco.adapter.out.persistence.fieldtrip;

import com.franco.desco.application.fieldtrip.port.out.E2PersistencePort;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.type.filter.AssignableTypeFilter;

import static org.assertj.core.api.Assertions.assertThat;

/** Impide que un segundo adaptador E2 vuelva a romper el arranque de Spring. */
class E2AdapterUniquenessTest {

    @Test
    void soloExisteElAdaptadorTipadoE2() {
        var scanner = new ClassPathScanningCandidateComponentProvider(false);
        scanner.addIncludeFilter(new AssignableTypeFilter(E2PersistencePort.class));

        var implementaciones = scanner.findCandidateComponents("com.franco.desco.adapter.out")
                .stream()
                .map(bean -> bean.getBeanClassName())
                .sorted()
                .toList();

        assertThat(implementaciones)
                .as("Un único E2PersistencePort: no mantener adaptadores duplicados ni .class obsoletos")
                .containsExactly("com.franco.desco.adapter.out.persistence.fieldtrip.E2SqlServerAdapter");
    }
}
