package com.franco.desco.infrastructure.config;

import com.franco.desco.application.identity.port.in.IdentityUseCase;
import com.franco.desco.application.identity.port.out.IdentityPersistencePort;
import com.franco.desco.application.identity.port.out.IdentityProviderPort;
import com.franco.desco.application.identity.service.IdentityApplicationService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class IdentityBeanConfig {

    @Bean
    IdentityUseCase identityUseCase(
            IdentityPersistencePort persistence,
            IdentityProviderPort provider
    ) {
        return new IdentityApplicationService(
                persistence,
                provider
        );
    }
}
