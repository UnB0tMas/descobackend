package com.franco.desco.infrastructure.config;

import com.franco.desco.adapter.in.web.common.idempotency.IdempotentOperation;
import com.franco.desco.adapter.in.web.openapi.OpenApiConstants;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.parameters.Parameter;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.tags.Tag;
import org.springdoc.core.customizers.OperationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI descoOpenApi() {
        return new OpenAPI()
                .info(
                        new Info()
                                .title("DESCO API")
                                .version("v1")
                                .description(
                                        """
                                        API REST del Sistema Integral DESCO UOT Sara Sara.

                                        La API utiliza:
                                        - JWT Bearer para autenticación.
                                        - permisos modulares para autorización.
                                        - respuestas funcionales uniformes mediante ApiResponse.
                                        - procedimientos almacenados SQL Server como contrato funcional.
                                        - X-Idempotency-Key en operaciones de escritura marcadas como idempotentes.
                                        """
                                )
                                .contact(
                                        new Contact()
                                                .name(
                                                        "DESCO UOT Sara Sara"
                                                )
                                )
                )
                .tags(
                        List.of(
                                new Tag()
                                        .name(
                                                OpenApiConstants.TAG_AUTH
                                        )
                                        .description(
                                                OpenApiConstants.TAG_AUTH_DESCRIPTION
                                        )
                        )
                )
                .components(
                        new Components()
                                .addSecuritySchemes(
                                        OpenApiConstants.BEARER_AUTH,
                                        new SecurityScheme()
                                                .name(
                                                        OpenApiConstants.BEARER_AUTH
                                                )
                                                .type(
                                                        SecurityScheme.Type.HTTP
                                                )
                                                .scheme("bearer")
                                                .bearerFormat("JWT")
                                                .description(
                                                        "Access token JWT emitido por DESCO. Use el formato: Bearer {token}."
                                                )
                                )
                );
    }

    @Bean
    OperationCustomizer descoCommonHeadersCustomizer() {
        return (operation, handlerMethod) -> {

            addParameterIfMissing(
                    operation,
                    new Parameter()
                            .name(
                                    OpenApiConstants.HEADER_CORRELATION_ID
                            )
                            .in("header")
                            .required(false)
                            .description(
                                    "Identificador UUID de correlación. Si no se envía, el backend genera uno y lo devuelve en la respuesta."
                            )
                            .schema(
                                    new StringSchema()
                                            .format("uuid")
                            )
            );

            addParameterIfMissing(
                    operation,
                    new Parameter()
                            .name(
                                    OpenApiConstants.HEADER_DEVICE_ID
                            )
                            .in("header")
                            .required(false)
                            .description(
                                    "Identificador lógico estable del dispositivo generado por el frontend. Se utiliza para sesiones y seguridad de cuenta."
                            )
                            .schema(
                                    new StringSchema()
                                            .maxLength(200)
                            )
            );

            if (handlerMethod.hasMethodAnnotation(
                    IdempotentOperation.class
            )) {
                addParameterIfMissing(
                        operation,
                        new Parameter()
                                .name(
                                        OpenApiConstants.HEADER_IDEMPOTENCY_KEY
                                )
                                .in("header")
                                .required(true)
                                .description(
                                        "UUID que identifica de forma idempotente esta escritura. Reutilice la misma clave únicamente al reintentar exactamente la misma solicitud."
                                )
                                .schema(
                                        new StringSchema()
                                                .format("uuid")
                                )
                );
            }

            return operation;
        };
    }

    private void addParameterIfMissing(
            io.swagger.v3.oas.models.Operation operation,
            Parameter parameter
    ) {
        boolean exists = operation.getParameters() != null
                && operation.getParameters()
                .stream()
                .anyMatch(existing ->
                        parameter.getName()
                                .equalsIgnoreCase(
                                        existing.getName()
                                )
                                && parameter.getIn()
                                .equalsIgnoreCase(
                                        existing.getIn()
                                )
                );

        if (!exists) {
            operation.addParametersItem(parameter);
        }
    }
}
