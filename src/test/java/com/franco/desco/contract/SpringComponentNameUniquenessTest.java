package com.franco.desco.contract;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.support.SimpleBeanDefinitionRegistry;
import org.springframework.context.annotation.AnnotationBeanNameGenerator;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.type.filter.AnnotationTypeFilter;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertTrue;

/** Detecta nombres de componentes en conflicto sin iniciar conexiones a BD ni Flyway. */
class SpringComponentNameUniquenessTest {
    @Test
    void noHayComponentesSpringConElMismoNombre() {
        var scanner = new ClassPathScanningCandidateComponentProvider(false);
        scanner.addIncludeFilter(new AnnotationTypeFilter(Component.class));
        var generator = AnnotationBeanNameGenerator.INSTANCE;
        var registry = new SimpleBeanDefinitionRegistry();
        Map<String, String> firstClassByName = new HashMap<>();
        List<String> conflicts = new ArrayList<>();
        List<BeanDefinition> definitions = new ArrayList<>(scanner.findCandidateComponents("com.franco.desco"));
        definitions.sort(Comparator.comparing(d -> String.valueOf(d.getBeanClassName())));
        for (BeanDefinition definition : definitions) {
            String name = generator.generateBeanName(definition, registry);
            String className = definition.getBeanClassName();
            String previous = firstClassByName.putIfAbsent(name, className);
            if (previous != null && !previous.equals(className)) {
                conflicts.add(name + " -> " + previous + " / " + className);
            }
        }
        assertTrue(conflicts.isEmpty(), () ->
                "Componentes Spring duplicados. Conservar un solo adaptador por puerto o " +
                "registrar el bean oficial con un nombre único y @Primary: " + conflicts);
    }
}
