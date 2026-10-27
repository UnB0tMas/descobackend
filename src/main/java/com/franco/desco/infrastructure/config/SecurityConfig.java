package com.franco.desco.infrastructure.config;

import com.franco.desco.adapter.in.security.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;
import java.util.List;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() {
        return Argon2PasswordEncoder
                .defaultsForSpringSecurity_v5_8();
    }

    @Bean
    SecretKey jwtSecretKey(
            SecurityProperties properties
    ) {
        byte[] decoded =
                Base64.getDecoder()
                        .decode(
                                properties
                                        .jwtSecretBase64()
                        );

        return new SecretKeySpec(
                decoded,
                "HmacSHA512"
        );
    }

    @Bean
    JwtEncoder jwtEncoder(
            SecretKey jwtSecretKey
    ) {
        return NimbusJwtEncoder
                .withSecretKey(jwtSecretKey)
                .algorithm(
                        MacAlgorithm.HS512
                )
                .build();
    }

    @Bean
    JwtDecoder jwtDecoder(
            SecretKey jwtSecretKey,
            SecurityProperties properties
    ) {
        NimbusJwtDecoder decoder =
                NimbusJwtDecoder
                        .withSecretKey(
                                jwtSecretKey
                        )
                        .macAlgorithm(
                                MacAlgorithm.HS512
                        )
                        .build();

        OAuth2TokenValidator<Jwt> issuer =
                JwtValidators
                        .createDefaultWithIssuer(
                                properties.issuer()
                        );

        OAuth2TokenValidator<Jwt> audience =
                new JwtClaimValidator<List<String>>(
                        "aud",
                        aud ->
                                aud != null
                                        && aud.contains(
                                        properties
                                                .audience()
                                )
                );

        OAuth2TokenValidator<Jwt> type =
                new JwtClaimValidator<String>(
                        "token_type",
                        "access"::equals
                );

        decoder.setJwtValidator(
                new DelegatingOAuth2TokenValidator<>(
                        issuer,
                        audience,
                        type
                )
        );

        return decoder;
    }

    @Bean
    SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            JwtRoleAuthenticationConverter jwtConverter,
            SessionValidationFilter sessionValidationFilter,
            AuthenticationErrorWriter errorWriter
    ) throws Exception {

        http
                .csrf(csrf ->
                        csrf.disable()
                )
                .cors(Customizer.withDefaults())
                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )
                .authorizeHttpRequests(auth ->
                        auth
                                .requestMatchers(
                                        "/api/v1/auth/login",
                                        "/api/v1/auth/2fa/**",
                                        "/api/v1/auth/email-verification/**",
                                        "/api/v1/auth/password-recovery/**",
                                        "/api/v1/auth/refresh",
                                        "/v3/api-docs/**",
                                        "/swagger-ui/**",
                                        "/swagger-ui.html",
                                        "/actuator/health"
                                )
                                .permitAll()
                                .anyRequest()
                                .authenticated()
                )
                .exceptionHandling(exceptions ->
                        exceptions
                                .authenticationEntryPoint(
                                        (request, response, exception) ->
                                                errorWriter.unauthorized(
                                                        request,
                                                        response
                                                )
                                )
                                .accessDeniedHandler(
                                        (request, response, exception) ->
                                                errorWriter.forbidden(
                                                        request,
                                                        response
                                                )
                                )
                )
                .oauth2ResourceServer(oauth2 ->
                        oauth2
                                .jwt(jwt ->
                                        jwt.jwtAuthenticationConverter(
                                                jwtConverter
                                        )
                                )
                                .authenticationEntryPoint(
                                        (request, response, exception) ->
                                                errorWriter.unauthorized(
                                                        request,
                                                        response
                                                )
                                )
                                .accessDeniedHandler(
                                        (request, response, exception) ->
                                                errorWriter.forbidden(
                                                        request,
                                                        response
                                                )
                                )
                )
                .addFilterAfter(
                        sessionValidationFilter,
                        BearerTokenAuthenticationFilter.class
                );

        return http.build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(
            CorsProperties properties
    ) {
        CorsConfiguration configuration =
                new CorsConfiguration();

        configuration.setAllowedOrigins(
                properties.allowedOrigins()
        );

        configuration.setAllowedMethods(
                List.of(
                        "GET",
                        "POST",
                        "PUT",
                        "PATCH",
                        "DELETE",
                        "OPTIONS"
                )
        );

        configuration.setAllowedHeaders(
                List.of(
                        "Authorization",
                        "Content-Type",
                        "X-Correlation-Id",
                        "X-Device-Id",
                        "X-Idempotency-Key"
                )
        );

        configuration.setExposedHeaders(
                List.of(
                        "X-Correlation-Id"
                )
        );

        configuration.setAllowCredentials(
                true
        );

        configuration.setMaxAge(
                3600L
        );

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();

        source.registerCorsConfiguration(
                "/**",
                configuration
        );

        return source;
    }
}
