package com.franco.desco.adapter.out.http.verificape;

import com.franco.desco.application.identity.port.out.IdentityProviderPort;
import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.ProviderData;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

@Component
public class VerificaPeClient
        implements IdentityProviderPort {

    private static final Logger log =
            LoggerFactory.getLogger(VerificaPeClient.class);

    private static final List<DateTimeFormatter> DATE_FORMATS = List.of(
            DateTimeFormatter.ofPattern("dd/MM/uuuu"),
            DateTimeFormatter.ISO_LOCAL_DATE
    );

    private final VerificaPeProperties properties;
    private final JsonMapper jsonMapper;
    private final RestClient restClient;

    public VerificaPeClient(
            VerificaPeProperties properties,
            JsonMapper jsonMapper
    ) {
        this.properties = properties;
        this.jsonMapper = jsonMapper;

        SimpleClientHttpRequestFactory requestFactory =
                new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(
                properties.getConnectTimeoutMs()
        );
        requestFactory.setReadTimeout(
                properties.getReadTimeoutMs()
        );

        this.restClient = RestClient
                .builder()
                .baseUrl(safeBaseUrl(properties.getBaseUrl()))
                .requestFactory(requestFactory)
                .defaultHeader(
                        HttpHeaders.ACCEPT,
                        MediaType.APPLICATION_JSON_VALUE
                )
                .build();
    }

    @Override
    public ProviderResult query(
            DocumentType documentType,
            String documentNumber
    ) {
        if (!properties.configured()) {
            return ProviderResult.error(
                    "API_KEY_NO_CONFIGURADA"
            );
        }

        String path = documentType == DocumentType.DNI
                ? properties.getDniPath()
                : properties.getRucPath();

        try {
            String body = restClient
                    .get()
                    .uri(path, documentNumber)
                    .header(
                            HttpHeaders.AUTHORIZATION,
                            "Bearer " + properties.getApiKey().trim()
                    )
                    .retrieve()
                    .body(String.class);

            if (body == null || body.isBlank()) {
                return ProviderResult.error(
                        "RESPUESTA_VACIA"
                );
            }

            return parse(
                    documentType,
                    documentNumber,
                    body
            );

        } catch (RestClientResponseException exception) {
            int status = exception.getStatusCode().value();

            if (status == 404) {
                return ProviderResult.notFound(
                        "NO_ENCONTRADO"
                );
            }

            if (status == 429) {
                return ProviderResult.error(
                        "RATE_LIMIT"
                );
            }

            if (status == 401 || status == 403) {
                return ProviderResult.error(
                        "API_NO_AUTORIZADA"
                );
            }

            log.warn(
                    "VerificaPE respondió HTTP {} para tipoDocumento={}",
                    status,
                    documentType
            );

            return ProviderResult.error(
                    status >= 500
                            ? "PROVEEDOR_NO_DISPONIBLE"
                            : "ERROR_HTTP_" + status
            );

        } catch (RestClientException exception) {
            log.warn(
                    "No fue posible conectar con VerificaPE para tipoDocumento={}",
                    documentType
            );

            return ProviderResult.error(
                    "PROVEEDOR_NO_DISPONIBLE"
            );
        }
    }

    private ProviderResult parse(
            DocumentType documentType,
            String requestedDocument,
            String body
    ) {
        try {
            JsonNode root = jsonMapper.readTree(body);

            if (root == null) {
                return ProviderResult.error(
                        "RESPUESTA_INVALIDA"
                );
            }

            boolean success = root.path("success").asBoolean(false);
            JsonNode data = root.path("data");

            if (!success) {
                return ProviderResult.notFound(
                        "RESPUESTA_NO_EXITOSA"
                );
            }

            if (data.isMissingNode() || data.isNull()) {
                return ProviderResult.notFound(
                        "SIN_DATOS"
                );
            }

            if (documentType == DocumentType.DNI) {
                return parseDni(
                        requestedDocument,
                        data
                );
            }

            return parseRuc(
                    requestedDocument,
                    data
            );

        } catch (Exception exception) {
            log.warn(
                    "VerificaPE devolvió JSON no procesable para tipoDocumento={}",
                    documentType
            );

            return ProviderResult.error(
                    "RESPUESTA_INVALIDA"
            );
        }
    }

    private ProviderResult parseDni(
            String requestedDocument,
            JsonNode data
    ) {
        String returnedDocument = text(
                data,
                "dni",
                "documentNumber",
                "numeroDocumento"
        );

        if (hasText(returnedDocument)
                && !requestedDocument.equals(returnedDocument.trim())) {
            return ProviderResult.error(
                    "DOCUMENTO_RESPUESTA_NO_COINCIDE"
            );
        }

        String names = text(data, "names", "nombres");
        String paternal = text(
                data,
                "paternalSurname",
                "apellidoPaterno",
                "apellido_paterno"
        );
        String maternal = text(
                data,
                "maternalSurname",
                "apellidoMaterno",
                "apellido_materno"
        );
        LocalDate birthDate = date(
                text(
                        data,
                        "birthDate",
                        "fechaNacimiento",
                        "fecha_nacimiento"
                )
        );

        return ProviderResult.success(
                new ProviderData(
                        names,
                        paternal,
                        maternal,
                        birthDate,
                        null,
                        null
                )
        );
    }

    private ProviderResult parseRuc(
            String requestedDocument,
            JsonNode data
    ) {
        String returnedDocument = text(
                data,
                "ruc",
                "documentNumber",
                "numeroDocumento"
        );

        if (hasText(returnedDocument)
                && !requestedDocument.equals(returnedDocument.trim())) {
            return ProviderResult.error(
                    "DOCUMENTO_RESPUESTA_NO_COINCIDE"
            );
        }

        String businessName = text(
                data,
                "businessName",
                "business_name",
                "razonSocial",
                "razon_social",
                "legalName",
                "name",
                "fullName",
                "nombre"
        );

        String address = text(
                data,
                "address",
                "direccion",
                "fiscalAddress",
                "fiscal_address",
                "domicilioFiscal",
                "domicilio_fiscal"
        );

        return ProviderResult.success(
                new ProviderData(
                        null,
                        null,
                        null,
                        null,
                        businessName,
                        address
                )
        );
    }

    private String text(
            JsonNode node,
            String... names
    ) {
        for (String name : names) {
            JsonNode value = node.path(name);

            if (!value.isMissingNode() && !value.isNull()) {
                String text = value.asString(null);

                if (hasText(text)) {
                    return text.trim();
                }
            }
        }

        return null;
    }

    private LocalDate date(String value) {
        if (!hasText(value)) {
            return null;
        }

        for (DateTimeFormatter formatter : DATE_FORMATS) {
            try {
                return LocalDate.parse(value.trim(), formatter);
            } catch (DateTimeParseException ignored) {
                // Se intenta el siguiente formato documentado/compatible.
            }
        }

        return null;
    }

    private String safeBaseUrl(String value) {
        if (value == null || value.isBlank()) {
            return "https://api.verificape.com";
        }

        return value.trim();
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
