package com.franco.desco.adapter.out.http.identity;

import com.franco.desco.application.identity.port.out.IdentityProviderPort;
import com.franco.desco.domain.identity.IdentityModels.DocumentType;
import com.franco.desco.domain.identity.IdentityModels.ProviderData;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Component("factilizaIdentityProviderAdapter")
public final class FactilizaIdentityProviderAdapter
        implements IdentityProviderPort {

    private static final Logger log =
            LoggerFactory.getLogger(
                    FactilizaIdentityProviderAdapter.class
            );

    private static final int MAX_BODY_LOG_LENGTH = 6000;

    private static final List<DateTimeFormatter> DATE_FORMATTERS =
            List.of(
                    DateTimeFormatter.ofPattern("dd/MM/uuuu"),
                    DateTimeFormatter.ofPattern("dd-MM-uuuu"),
                    DateTimeFormatter.ISO_LOCAL_DATE
            );

    private final JsonMapper jsonMapper;
    private final HttpClient httpClient;

    private final boolean enabled;
    private final boolean debugLogging;
    private final String baseUrl;
    private final String token;
    private final String dniPath;
    private final String rucPath;
    private final long readTimeoutMs;

    public FactilizaIdentityProviderAdapter(
            JsonMapper jsonMapper,
            Environment environment
    ) {
        this.jsonMapper = jsonMapper;

        this.enabled =
                Boolean.parseBoolean(
                        environment.getProperty(
                                "app.factiliza.enabled",
                                "false"
                        )
                );

        this.debugLogging =
                Boolean.parseBoolean(
                        environment.getProperty(
                                "app.factiliza.debug-logging",
                                "false"
                        )
                );

        this.baseUrl =
                normalizeBaseUrl(
                        environment.getProperty(
                                "app.factiliza.base-url",
                                "https://api.factiliza.com"
                        )
                );

        this.token =
                normalize(
                        environment.getProperty(
                                "app.factiliza.token"
                        )
                );

        this.dniPath =
                normalizePath(
                        environment.getProperty(
                                "app.factiliza.dni-path",
                                "/v1/dni/info/{documento}"
                        )
                );

        this.rucPath =
                normalizePath(
                        environment.getProperty(
                                "app.factiliza.ruc-path",
                                "/v1/ruc/info/{documento}"
                        )
                );

        long connectTimeoutMs =
                positiveLong(
                        environment.getProperty(
                                "app.factiliza.connect-timeout-ms"
                        ),
                        5000L
                );

        this.readTimeoutMs =
                positiveLong(
                        environment.getProperty(
                                "app.factiliza.read-timeout-ms"
                        ),
                        10000L
                );

        this.httpClient =
                HttpClient.newBuilder()
                        .connectTimeout(
                                Duration.ofMillis(
                                        connectTimeoutMs
                                )
                        )
                        .followRedirects(
                                HttpClient.Redirect.NORMAL
                        )
                        .build();

        log.info(
                "[FACTILIZA] Client ready enabled={} baseUrl={}",
                enabled,
                baseUrl
        );
    }

    @Override
    public ProviderResult query(
            DocumentType documentType,
            String documentNumber
    ) {
        long started =
                System.nanoTime();

        String document =
                normalize(documentNumber);

        String maskedDocument =
                maskDocument(document);

        if (!enabled) {
            log.warn(
                    "[FACTILIZA] Request skipped type={} document={} reason=provider_disabled",
                    documentType,
                    maskedDocument
            );

            return ProviderResult.error(
                    "PROVIDER_DISABLED"
            );
        }

        if (documentType == null
                || document == null
                || document.isBlank()) {
            log.warn(
                    "[FACTILIZA] Request rejected type={} document={} reason=invalid_request",
                    documentType,
                    maskedDocument
            );

            return ProviderResult.error(
                    "INVALID_REQUEST"
            );
        }

        if (token == null || token.isBlank()) {
            log.error(
                    "[FACTILIZA] Configuration error: token is missing."
            );

            return ProviderResult.error(
                    "AUTH_CONFIG_MISSING"
            );
        }

        String path =
                switch (documentType) {
                    case DNI -> dniPath;
                    case RUC -> rucPath;
                };

        String resolvedPath =
                path.replace(
                        "{documento}",
                        document
                );

        URI uri;

        try {
            uri =
                    URI.create(
                            baseUrl + resolvedPath
                    );

        } catch (RuntimeException exception) {
            log.error(
                    "[FACTILIZA] Request build failed type={} document={} error={}",
                    documentType,
                    maskedDocument,
                    safeMessage(
                            exception.getMessage()
                    )
            );

            log.debug(
                    "[FACTILIZA] Request build failure detail",
                    exception
            );

            return ProviderResult.error(
                    "INVALID_ENDPOINT"
            );
        }

        HttpRequest request =
                HttpRequest.newBuilder(uri)
                        .timeout(
                                Duration.ofMillis(
                                        readTimeoutMs
                                )
                        )
                        .header(
                                "Authorization",
                                "Bearer " + token
                        )
                        .header(
                                "Accept",
                                "application/json"
                        )
                        .GET()
                        .build();

        log.info(
                "[FACTILIZA] Request type={} document={} method=GET path={}",
                documentType,
                maskedDocument,
                maskPath(
                        resolvedPath,
                        document
                )
        );

        if (debugLogging
                && log.isDebugEnabled()) {
            log.debug(
                    "[FACTILIZA] Request detail type={} document={} url={} headers=Authorization: Bearer ***, Accept: application/json",
                    documentType,
                    document,
                    uri
            );
        }

        try {
            HttpResponse<String> response =
                    httpClient.send(
                            request,
                            HttpResponse.BodyHandlers
                                    .ofString(
                                            StandardCharsets.UTF_8
                                    )
                    );

            int status =
                    response.statusCode();

            String body =
                    response.body() == null
                            ? ""
                            : response.body();

            long durationMs =
                    elapsedMs(started);

            log.info(
                    "[FACTILIZA] Response type={} document={} status={} durationMs={}",
                    documentType,
                    maskedDocument,
                    status,
                    durationMs
            );

            logResponseBody(
                    documentType,
                    document,
                    maskedDocument,
                    status,
                    body
            );

            ProviderResult result =
                    mapResponse(
                            documentType,
                            status,
                            body
                    );

            if (!result.exito()) {
                log.warn(
                        "[FACTILIZA] Provider result type={} document={} errorCode={}",
                        documentType,
                        maskedDocument,
                        result.codigoError()
                );
            }

            return result;

        } catch (HttpTimeoutException exception) {
            log.error(
                    "[FACTILIZA] Request failed type={} document={} stage=timeout durationMs={} error={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started),
                    safeMessage(
                            exception.getMessage()
                    )
            );

            log.debug(
                    "[FACTILIZA] Timeout detail",
                    exception
            );

            return ProviderResult.error(
                    "TIMEOUT"
            );

        } catch (InterruptedException exception) {
            Thread.currentThread()
                    .interrupt();

            log.error(
                    "[FACTILIZA] Request interrupted type={} document={} durationMs={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started)
            );

            log.debug(
                    "[FACTILIZA] Interrupted request detail",
                    exception
            );

            return ProviderResult.error(
                    "INTERRUPTED"
            );

        } catch (IOException exception) {
            log.error(
                    "[FACTILIZA] Request failed type={} document={} stage=network durationMs={} error={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started),
                    safeMessage(
                            exception.getMessage()
                    )
            );

            log.debug(
                    "[FACTILIZA] Network failure detail",
                    exception
            );

            return ProviderResult.error(
                    "NETWORK_ERROR"
            );

        } catch (RuntimeException exception) {
            log.error(
                    "[FACTILIZA] Request failed type={} document={} stage=client durationMs={} error={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started),
                    safeMessage(
                            exception.getMessage()
                    )
            );

            log.debug(
                    "[FACTILIZA] Client failure detail",
                    exception
            );

            return ProviderResult.error(
                    "CLIENT_ERROR"
            );
        }
    }

    private ProviderResult mapResponse(
            DocumentType documentType,
            int status,
            String body
    ) {
        if (status == 401 || status == 403) {
            return ProviderResult.error(
                    "AUTH_ERROR"
            );
        }

        if (status == 429) {
            return ProviderResult.error(
                    "RATE_LIMIT"
            );
        }

        if (status >= 500) {
            return ProviderResult.error(
                    "PROVIDER_UNAVAILABLE"
            );
        }

        Map<?, ?> root =
                parseJsonObjectQuietly(
                        body
                );

        if (status == 404) {
            return ProviderResult.notFound(
                    "NOT_FOUND"
            );
        }

        if (status < 200 || status >= 300) {
            if (root != null
                    && looksNotFound(root)) {
                return ProviderResult.notFound(
                        "NOT_FOUND"
                );
            }

            return ProviderResult.error(
                    "HTTP_" + status
            );
        }

        if (root == null) {
            return ProviderResult.error(
                    "INVALID_RESPONSE"
            );
        }

        Boolean success =
                booleanValue(
                        valueIgnoreCase(
                                root,
                                "success"
                        )
                );

        if (Boolean.FALSE.equals(success)) {
            if (looksNotFound(root)) {
                return ProviderResult.notFound(
                        "NOT_FOUND"
                );
            }

            return ProviderResult.error(
                    providerErrorCode(root)
            );
        }

        Map<?, ?> data =
                asMap(
                        valueIgnoreCase(
                                root,
                                "data"
                        )
                );

        if (data == null) {
            return ProviderResult.error(
                    "INVALID_RESPONSE"
            );
        }

        ProviderData providerData =
                documentType == DocumentType.DNI
                        ? mapDni(data)
                        : mapRuc(data);

        if (providerData == null) {
            return ProviderResult.error(
                    "INVALID_RESPONSE"
            );
        }

        return ProviderResult.success(
                providerData
        );
    }

    private ProviderData mapDni(
            Map<?, ?> data
    ) {
        String names =
                textValue(
                        valueIgnoreCase(
                                data,
                                "nombres"
                        )
                );

        String paternalSurname =
                textValue(
                        valueIgnoreCase(
                                data,
                                "apellido_paterno"
                        )
                );

        String maternalSurname =
                textValue(
                        valueIgnoreCase(
                                data,
                                "apellido_materno"
                        )
                );

        /*
         * Los mínimos para Persona son nombres + apellido paterno.
         * Fecha, sexo y ubicación son opcionales.
         */
        if (isBlank(names)
                || isBlank(paternalSurname)) {
            return null;
        }

        Geography geography =
                geography(data);

        return new ProviderData(
                names,
                paternalSurname,
                maternalSurname,
                dateValue(
                        valueIgnoreCase(
                                data,
                                "fecha_nacimiento"
                        )
                ),
                null,
                textValue(
                        valueIgnoreCase(
                                data,
                                "direccion"
                        )
                ),
                textValue(
                        valueIgnoreCase(
                                data,
                                "direccion_completa"
                        )
                ),
                catalogText(
                        valueIgnoreCase(
                                data,
                                "sexo"
                        )
                ),
                geography.department(),
                geography.province(),
                geography.district(),
                geography.departmentCode(),
                geography.provinceCode(),
                geography.districtCode(),
                catalogText(
                        valueIgnoreCase(
                                data,
                                "centro_poblado",
                                "centroPoblado",
                                "centro_poblado_nombre"
                        )
                ),
                textValue(
                        valueIgnoreCase(
                                data,
                                "codigo_centro_poblado",
                                "centro_poblado_codigo"
                        )
                ),
                digits(
                        valueIgnoreCase(
                                data,
                                "ubigeo_reniec"
                        ),
                        6
                ),
                geography.sunatCode(),
                null,
                null,
                null
        );
    }

    private ProviderData mapRuc(
            Map<?, ?> data
    ) {
        String businessName =
                textValue(
                        valueIgnoreCase(
                                data,
                                "nombre_o_razon_social",
                                "razon_social"
                        )
                );

        if (isBlank(businessName)) {
            return null;
        }

        Geography geography =
                geography(data);

        return new ProviderData(
                null,
                null,
                null,
                null,
                businessName,
                textValue(
                        valueIgnoreCase(
                                data,
                                "direccion"
                        )
                ),
                textValue(
                        valueIgnoreCase(
                                data,
                                "direccion_completa"
                        )
                ),
                null,
                geography.department(),
                geography.province(),
                geography.district(),
                geography.departmentCode(),
                geography.provinceCode(),
                geography.districtCode(),
                catalogText(
                        valueIgnoreCase(
                                data,
                                "centro_poblado",
                                "centroPoblado",
                                "centro_poblado_nombre"
                        )
                ),
                textValue(
                        valueIgnoreCase(
                                data,
                                "codigo_centro_poblado",
                                "centro_poblado_codigo"
                        )
                ),
                null,
                geography.sunatCode(),
                catalogText(
                        valueIgnoreCase(
                                data,
                                "tipo_contribuyente"
                        )
                ),
                catalogText(
                        valueIgnoreCase(
                                data,
                                "estado"
                        )
                ),
                catalogText(
                        valueIgnoreCase(
                                data,
                                "condicion"
                        )
                )
        );
    }

    private Geography geography(
            Map<?, ?> data
    ) {
        String department =
                catalogText(
                        valueIgnoreCase(
                                data,
                                "departamento"
                        )
                );

        String province =
                catalogText(
                        valueIgnoreCase(
                                data,
                                "provincia"
                        )
                );

        String district =
                catalogText(
                        valueIgnoreCase(
                                data,
                                "distrito"
                        )
                );

        String departmentCode = null;
        String provinceCode = null;
        String districtCode = null;

        Object ubigeo =
                valueIgnoreCase(
                        data,
                        "ubigeo"
                );

        if (ubigeo instanceof List<?> values) {
            if (values.size() > 0) {
                departmentCode =
                        digits(
                                values.get(0),
                                2
                        );
            }

            if (values.size() > 1) {
                provinceCode =
                        digits(
                                values.get(1),
                                4
                        );
            }

            if (values.size() > 2) {
                districtCode =
                        digits(
                                values.get(2),
                                6
                        );
            }
        }

        String sunatCode =
                digits(
                        valueIgnoreCase(
                                data,
                                "ubigeo_sunat"
                        ),
                        6
                );

        /*
         * La documentación de Factiliza muestra que el arreglo "ubigeo"
         * contiene códigos jerárquicos 2/4/6 compatibles con el catálogo
         * DESCO. Si el arreglo no viene completo, se deriva desde
         * ubigeo_sunat.
         */
        if (districtCode == null) {
            districtCode =
                    sunatCode;
        }

        if (districtCode != null) {
            if (provinceCode == null
                    || !districtCode.startsWith(
                            provinceCode
                    )) {
                provinceCode =
                        districtCode.substring(
                                0,
                                4
                        );
            }

            if (departmentCode == null
                    || !districtCode.startsWith(
                            departmentCode
                    )) {
                departmentCode =
                        districtCode.substring(
                                0,
                                2
                        );
            }
        } else if (provinceCode != null
                && departmentCode == null) {
            departmentCode =
                    provinceCode.substring(
                            0,
                            2
                    );
        }

        return new Geography(
                department,
                province,
                district,
                departmentCode,
                provinceCode,
                districtCode,
                sunatCode
        );
    }

    private void logResponseBody(
            DocumentType documentType,
            String document,
            String maskedDocument,
            int status,
            String body
    ) {
        if (status >= 500) {
            log.error(
                    "[FACTILIZA] Error response type={} document={} status={} body={}",
                    documentType,
                    maskedDocument,
                    status,
                    bodyForLog(body)
            );
            return;
        }

        if (status >= 400) {
            log.warn(
                    "[FACTILIZA] Rejected response type={} document={} status={} body={}",
                    documentType,
                    maskedDocument,
                    status,
                    bodyForLog(body)
            );
            return;
        }

        if (debugLogging
                && log.isDebugEnabled()) {
            log.debug(
                    "[FACTILIZA] Response body type={} document={} body={}",
                    documentType,
                    document,
                    bodyForLog(body)
            );
        }
    }

    private Map<?, ?> parseJsonObjectQuietly(
            String body
    ) {
        if (body == null || body.isBlank()) {
            return null;
        }

        try {
            Object parsed =
                    jsonMapper.readValue(
                            body,
                            Object.class
                    );

            return parsed instanceof Map<?, ?> map
                    ? map
                    : null;

        } catch (Exception exception) {
            log.debug(
                    "[FACTILIZA] Response JSON parse detail",
                    exception
            );

            return null;
        }
    }

    private boolean looksNotFound(
            Map<?, ?> root
    ) {
        String message =
                textValue(
                        valueIgnoreCase(
                                root,
                                "message",
                                "mensaje",
                                "error"
                        )
                );

        if (message == null) {
            return false;
        }

        String normalized =
                message.toLowerCase(
                        Locale.ROOT
                );

        return normalized.contains(
                "no encontrado"
        ) || normalized.contains(
                "no existe"
        ) || normalized.contains(
                "not found"
        );
    }

    private String providerErrorCode(
            Map<?, ?> root
    ) {
        Object status =
                valueIgnoreCase(
                        root,
                        "status",
                        "statusCode",
                        "code"
                );

        String value =
                textValue(status);

        if (value != null) {
            return normalizeCode(
                    "FACTILIZA_" + value
            );
        }

        return "PROVIDER_ERROR";
    }

    private Map<?, ?> asMap(
            Object value
    ) {
        return value instanceof Map<?, ?> map
                ? map
                : null;
    }

    private Object valueIgnoreCase(
            Map<?, ?> map,
            String... keys
    ) {
        if (map == null) {
            return null;
        }

        for (Map.Entry<?, ?> entry
                : map.entrySet()) {
            if (entry.getKey() == null) {
                continue;
            }

            String current =
                    entry.getKey()
                            .toString();

            for (String key : keys) {
                if (current.equalsIgnoreCase(
                        key
                )) {
                    return entry.getValue();
                }
            }
        }

        return null;
    }

    private Boolean booleanValue(
            Object value
    ) {
        if (value instanceof Boolean bool) {
            return bool;
        }

        if (value == null) {
            return null;
        }

        String text =
                value.toString()
                        .trim();

        if ("true".equalsIgnoreCase(text)) {
            return true;
        }

        if ("false".equalsIgnoreCase(text)) {
            return false;
        }

        return null;
    }

    private String textValue(
            Object value
    ) {
        if (value == null) {
            return null;
        }

        String text =
                value.toString()
                        .trim();

        return text.isEmpty()
                ? null
                : text;
    }

    private String catalogText(
            Object value
    ) {
        String text =
                textValue(value);

        return text == null
                ? null
                : text.toUpperCase(
                        Locale.ROOT
                );
    }

    private String digits(
            Object value,
            int length
    ) {
        String text =
                textValue(value);

        if (text == null
                || text.length() != length
                || !text.chars()
                        .allMatch(
                                Character::isDigit
                        )) {
            return null;
        }

        return text;
    }

    private LocalDate dateValue(
            Object value
    ) {
        String text =
                textValue(value);

        if (text == null) {
            return null;
        }

        for (DateTimeFormatter formatter
                : DATE_FORMATTERS) {
            try {
                return LocalDate.parse(
                        text,
                        formatter
                );

            } catch (DateTimeParseException ignored) {
                // Se prueba el siguiente formato.
            }
        }

        log.debug(
                "[FACTILIZA] Optional birth date could not be parsed value={}",
                text
        );

        return null;
    }

    private long positiveLong(
            String value,
            long fallback
    ) {
        if (value == null || value.isBlank()) {
            return fallback;
        }

        try {
            long parsed =
                    Long.parseLong(
                            value.trim()
                    );

            return parsed > 0
                    ? parsed
                    : fallback;

        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }

    private String normalizeBaseUrl(
            String value
    ) {
        String normalized =
                normalize(value);

        if (normalized == null
                || normalized.isBlank()) {
            return "https://api.factiliza.com";
        }

        while (normalized.endsWith("/")) {
            normalized =
                    normalized.substring(
                            0,
                            normalized.length() - 1
                    );
        }

        return normalized;
    }

    private String normalizePath(
            String value
    ) {
        String normalized =
                normalize(value);

        if (normalized == null
                || normalized.isBlank()) {
            return "/";
        }

        return normalized.startsWith("/")
                ? normalized
                : "/" + normalized;
    }

    private String normalize(
            String value
    ) {
        return value == null
                ? null
                : value.trim();
    }

    private String maskDocument(
            String document
    ) {
        if (document == null
                || document.isBlank()) {
            return "(none)";
        }

        if (document.length() <= 4) {
            return "*".repeat(
                    document.length()
            );
        }

        return "*".repeat(
                document.length() - 4
        ) + document.substring(
                document.length() - 4
        );
    }

    private String maskPath(
            String path,
            String document
    ) {
        if (path == null
                || document == null
                || document.isBlank()) {
            return path;
        }

        return path.replace(
                document,
                maskDocument(document)
        );
    }

    private String normalizeCode(
            String value
    ) {
        if (value == null || value.isBlank()) {
            return "PROVIDER_ERROR";
        }

        String code =
                value.trim()
                        .toUpperCase(
                                Locale.ROOT
                        )
                        .replaceAll(
                                "[^A-Z0-9]+",
                                "_"
                        )
                        .replaceAll(
                                "^_+|_+$",
                                ""
                        );

        if (code.isBlank()) {
            return "PROVIDER_ERROR";
        }

        return code.length() <= 60
                ? code
                : code.substring(
                        0,
                        60
                );
    }

    private String safeMessage(
            String value
    ) {
        if (value == null || value.isBlank()) {
            return "(no detail)";
        }

        String text =
                value.replace(
                                '\r',
                                ' '
                        )
                        .replace(
                                '\n',
                                ' '
                        )
                        .trim();

        return text.length() <= 400
                ? text
                : text.substring(
                        0,
                        400
                );
    }

    private String bodyForLog(
            String body
    ) {
        if (body == null || body.isBlank()) {
            return "(empty)";
        }

        String compact =
                body.replace(
                                '\r',
                                ' '
                        )
                        .replace(
                                '\n',
                                ' '
                        )
                        .trim();

        return compact.length()
                <= MAX_BODY_LOG_LENGTH
                ? compact
                : compact.substring(
                        0,
                        MAX_BODY_LOG_LENGTH
                ) + "...(truncated)";
    }

    private long elapsedMs(
            long startedNanos
    ) {
        return Duration.ofNanos(
                System.nanoTime()
                        - startedNanos
        ).toMillis();
    }

    private boolean isBlank(
            String value
    ) {
        return value == null
                || value.isBlank();
    }

    private record Geography(
            String department,
            String province,
            String district,
            String departmentCode,
            String provinceCode,
            String districtCode,
            String sunatCode
    ) {
    }
}
