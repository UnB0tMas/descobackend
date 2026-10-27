package com.franco.desco.infrastructure.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.dao.annotation.PersistenceExceptionTranslationPostProcessor;

@Configuration(proxyBeanMethods = false)
public class PersistenceExceptionTranslationConfig {

    @Bean
    public static PersistenceExceptionTranslationPostProcessor
    persistenceExceptionTranslationPostProcessor() {

        PersistenceExceptionTranslationPostProcessor postProcessor =
                new PersistenceExceptionTranslationPostProcessor();

        /*
         * Los adapters SQL implementan puertos (interfaces).
         * Se fuerza proxy JDK para evitar que Spring intente crear
         * subclases CGLIB de adapters final heredados/legacy.
         */
        postProcessor.setProxyTargetClass(false);

        return postProcessor;
    }
}
