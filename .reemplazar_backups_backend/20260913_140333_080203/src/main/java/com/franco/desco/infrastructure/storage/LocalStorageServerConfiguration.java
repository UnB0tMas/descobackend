package com.franco.desco.infrastructure.storage;

import jakarta.servlet.MultipartConfigElement;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class LocalStorageServerConfiguration {
    @Bean
    MultipartConfigElement localStorageMultipartConfig(LocalStorageProperties properties) {
        long maxFile = properties.maxFileBytes();
        long maxRequest = Math.max(maxFile + (1024L * 1024L), maxFile);
        return new MultipartConfigElement("", maxFile, maxRequest, 0);
    }
}
