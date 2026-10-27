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
import java.util.Set;
import java.util.TreeSet;

@Component
public final class FactilizaIdentityProviderAdapter
        implements IdentityProviderPort {

    private static final Logger log =
            LoggerFactory.getLogger(
                    FactilizaIdentityProviderAdapter.class
            );

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
        String document =
                normalize(documentNumber);

        String maskedDocument =
                maskDocument(document);

        if (!enabled) {
            log.warn(
                    "[FACTILIZA] Request skipped type={} document={} reason=disabled",
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
                    "[FACTILIZA] Configuration error reason=missing_token"
            );
            return ProviderResult.error(
                    "AUTH_CONFIG_MISSING"
            );
        }

        String configuredPath =
                switch (documentType) {
                    case DNI -> dniPath;
                    case RUC -> rucPath;
                };

        String resolvedPath =
                configuredPath.replace(
                        "{documento}",
                        document
                );

        URI uri;

        try {
            uri =
                    URI.create(
                            baseUrl + resolvedPath
                    );
        } catch (IllegalArgumentException exception) {
            log.error(
                    "[FACTILIZA] Request build failed type={} document={} reason=invalid_endpoint",
                    documentType,
                    maskedDocument
            );
            log.debug(
                    "[FACTILIZA] Invalid endpoint detail",
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

        long started =
                System.nanoTime();

        try {
            HttpResponse<String> response =
                    httpClient.send(
                            request,
                            HttpResponse.BodyHandlers.ofString(
                                    StandardCharsets.UTF_8
                            )
                    );

            long durationMs =
                    elapsedMs(started);

            int status =
                    response.statusCode();

            String body =
                    response.body();

            log.info(
                    "[FACTILIZA] Response type={} document={} status={} durationMs={}",
                    documentType,
                    maskedDocument,
                    status,
                    durationMs
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
            log.warn(
                    "[FACTILIZA] Timeout type={} document={} durationMs={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started)
            );
            return ProviderResult.error(
                    "TIMEOUT"
            );

        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();

            log.warn(
                    "[FACTILIZA] Request interrupted type={} document={}",
                    documentType,
                    maskedDocument
            );

            return ProviderResult.error(
                    "INTERRUPTED"
            );

        } catch (IOException exception) {
            log.warn(
                    "[FACTILIZA] Network error type={} document={} durationMs={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started)
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
                    "[FACTILIZA] Unexpected client error type={} document={}",
                    documentType,
                    maskedDocument
            );

            log.debug(
                    "[FACTILIZA] Unexpected client failure detail",
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

        Map<?, ?> payload =
                parseObject(body);

        String providerMessage =
                payload == null
                        ? null
                        : text(
                                value(
                                        payload,
                                        "message"
                                )
                        );

        if (status < 200 || status >= 300) {
            logRejectedResponse(
                    documentType,
                    status,
                    providerMessage
            );

            if (status == 404
                    || looksNotFound(
                            providerMessage
                    )) {
                return ProviderResult.notFound(
                        "NOT_FOUND"
                );
            }

            return ProviderResult.error(
                    "HTTP_" + status
            );
        }

        if (payload == null) {
            return ProviderResult.error(
                    "INVALID_RESPONSE"
            );
        }

        Boolean success =
                booleanValue(
                        value(
                                payload,
                                "success"
                        )
                );

        if (Boolean.FALSE.equals(success)) {
            if (looksNotFound(providerMessage)) {
                return ProviderResult.notFound(
                        "NOT_FOUND"
                );
            }

            return ProviderResult.error(
                    normalizeProviderCode(
                            providerMessage
                    )
            );
        }

        Map<?, ?> data =
                asMap(
                        value(
                                payload,
                                "data"
                        )
                );

        if (data == null) {
            return ProviderResult.error(
                    "INVALID_RESPONSE"
            );
        }

        if (debugLogging
                && log.isDebugEnabled()) {
            log.debug(
                    "[FACTILIZA] Response metadata type={} success={} message={} dataKeys={}",
                    documentType,
                    success,
                    safeMessage(
                            providerMessage
                    ),
                    sortedKeys(data)
            );
        }

        ProviderData providerData =
                switch (documentType) {
                    case DNI -> mapDni(data);
                    case RUC -> mapRuc(data);
                };

        if (providerData == null) {
            return ProviderResult.error(
                    "INCOMPLETE_PROVIDER_DATA"
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
                text(
                        value(
                                data,
                                "nombres"
                        )
                );

        String paternalSurname =
                text(
                        value(
                                data,
                                "apellido_paterno"
                        )
                );

        String maternalSurname =
                text(
                        value(
                                data,
                                "apellido_materno"
                        )
                );

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
                date(
                        value(
                                data,
                                "fecha_nacimiento"
                        )
                ),
                null,
                text(
                        value(
                                data,
                                "direccion"
                        )
                ),
                text(
                        value(
                                data,
                                "direccion_completa"
                        )
                ),
                upper(
                        value(
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
                upper(
                        firstValue(
                                data,
                                "centro_poblado",
                                "centroPoblado"
                        )
                ),
                text(
                        firstValue(
                                data,
                                "codigo_centro_poblado",
                                "centro_poblado_codigo"
                        )
                ),
                null,
                null,
                null
        );
    }

    private ProviderData mapRuc(
            Map<?, ?> data
    ) {
        String businessName =
                text(
                        firstValue(
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
                text(
                        value(
                                data,
                                "direccion"
                        )
                ),
                text(
                        value(
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
                upper(
                        firstValue(
                                data,
                                "centro_poblado",
                                "centroPoblado"
                        )
                ),
                text(
                        firstValue(
                                data,
                                "codigo_centro_poblado",
                                "centro_poblado_codigo"
                        )
                ),
                upper(
                        value(
                                data,
                                "tipo_contribuyente"
                        )
                ),
                upper(
                        value(
                                data,
                                "estado"
                        )
                ),
                upper(
                        value(
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
                upper(
                        value(
                                data,
                                "departamento"
                        )
                );

        String province =
                upper(
                        value(
                                data,
                                "provincia"
                        )
                );

        String district =
                upper(
                        value(
                                data,
                                "distrito"
                        )
                );

        String departmentCode = null;
        String provinceCode = null;
        String districtCode = null;

        Object ubigeo =
                value(
                        data,
                        "ubigeo"
                );

        if (ubigeo instanceof List<?> values) {
            if (!values.isEmpty()) {
                departmentCode =
                        digits(
                                values.get(0),
                                2
                        );
            }

            if (values.size() >= 2) {
                provinceCode =
                        digits(
                                values.get(1),
                                4
                        );
            }

            if (values.size() >= 3) {
                districtCode =
                        digits(
                                values.get(2),
                                6
                        );
            }
        }

        String sunatCode =
                digits(
                        value(
                                data,
                                "ubigeo_sunat"
                        ),
                        6
                );

        if (districtCode == null) {
            districtCode =
                    sunatCode;
        }

        if (provinceCode == null
                && districtCode != null) {
            provinceCode =
                    districtCode.substring(
                            0,
                            4
                    );
        }

        if (departmentCode == null
                && districtCode != null) {
            departmentCode =
                    districtCode.substring(
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
                districtCode
        );
    }

    private Map<?, ?> parseObject(
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

            return asMap(parsed);

        } catch (RuntimeException exception) {
            log.debug(
                    "[FACTILIZA] Invalid JSON response",
                    exception
            );
            return null;
        }
    }

    private Map<?, ?> asMap(
            Object value
    ) {
        return value instanceof Map<?, ?> map
                ? map
                : null;
    }

    private Object firstValue(
            Map<?, ?> map,
            String... keys
    ) {
        for (String key : keys) {
            Object result =
                    value(
                            map,
                            key
                    );

            if (result != null) {
                return result;
            }
        }

        return null;
    }

    private Object value(
            Map<?, ?> map,
            String key
    ) {
        if (map == null || key == null) {
            return null;
        }

        for (Map.Entry<?, ?> entry
                : map.entrySet()) {

            if (entry.getKey() != null
                    && key.equalsIgnoreCase(
                            entry.getKey().toString()
                    )) {
                return entry.getValue();
            }
        }

        return null;
    }

    private Boolean booleanValue(
            Object value
    ) {
        if (value instanceof Boolean booleanValue) {
            return booleanValue;
        }

        if (value instanceof Number number) {
            return number.intValue() != 0;
        }

        String text =
                text(value);

        if (text == null) {
            return null;
        }

        if ("true".equalsIgnoreCase(text)
                || "1".equals(text)) {
            return true;
        }

        if ("false".equalsIgnoreCase(text)
                || "0".equals(text)) {
            return false;
        }

        return null;
    }

    private String text(
            Object value
    ) {
        if (value == null) {
            return null;
        }

        String text =
                value.toString().trim();

        return text.isEmpty()
                ? null
                : text;
    }

    private String upper(
            Object value
    ) {
        String text =
                text(value);

        return text == null
                ? null
                : text.toUpperCase(
                        Locale.ROOT
                );
    }

    private String digits(
            Object value,
            int expectedLength
    ) {
        String text =
                text(value);

        if (text == null) {
            return null;
        }

        String digits =
                text.replaceAll(
                        "\\D",
                        ""
                );

        return digits.length() == expectedLength
                ? digits
                : null;
    }

    private LocalDate date(
            Object value
    ) {
        String text =
                text(value);

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
                // Probar el siguiente formato documentado/común.
            }
        }

        return null;
    }

    private boolean looksNotFound(
            String message
    ) {
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
                "not found"
        ) || normalized.contains(
                "no existe"
        ) || normalized.contains(
                "sin resultados"
        );
    }

    private void logRejectedResponse(
            DocumentType documentType,
            int status,
            String providerMessage
    ) {
        log.warn(
                "[FACTILIZA] Rejected response type={} status={} message={}",
                documentType,
                status,
                safeMessage(
                        providerMessage
                )
        );
    }

    private Set<String> sortedKeys(
            Map<?, ?> data
    ) {
        Set<String> keys =
                new TreeSet<>(
                        String.CASE_INSENSITIVE_ORDER
                );

        for (Object key : data.keySet()) {
            if (key != null) {
                keys.add(
                        key.toString()
                );
            }
        }

        return keys;
    }

    private long positiveLong(
            String value,
            long defaultValue
    ) {
        if (value == null || value.isBlank()) {
            return defaultValue;
        }

        try {
            long parsed =
                    Long.parseLong(
                            value.trim()
                    );

            return parsed > 0
                    ? parsed
                    : defaultValue;

        } catch (NumberFormatException exception) {
            return defaultValue;
        }
    }

    private String normalizeBaseUrl(
            String value
    ) {
        String normalized =
                normalize(value);

        if (normalized == null) {
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

        if (normalized == null) {
            return "/";
        }

        return normalized.startsWith("/")
                ? normalized
                : "/" + normalized;
    }

    private String normalize(
            String value
    ) {
        if (value == null) {
            return null;
        }

        String normalized =
                value.trim();

        return normalized.isEmpty()
                ? null
                : normalized;
    }

    private String maskDocument(
            String document
    ) {
        if (document == null || document.isBlank()) {
            return "(empty)";
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
                maskDocument(
                        document
                )
        );
    }

    private String normalizeProviderCode(
            String message
    ) {
        String normalized =
                normalize(message);

        if (normalized == null) {
            return "PROVIDER_ERROR";
        }

        normalized =
                normalized.toUpperCase(
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

        if (normalized.isBlank()) {
            return "PROVIDER_ERROR";
        }

        return normalized.length() <= 60
                ? normalized
                : normalized.substring(
                        0,
                        60
                );
    }

    private String safeMessage(
            String message
    ) {
        String normalized =
                normalize(message);

        if (normalized == null) {
            return "(none)";
        }

        normalized =
                normalized.replace(
                                '\r',
                                ' '
                        )
                        .replace(
                                '\n',
                                ' '
                        );

        return normalized.length() <= 200
                ? normalized
                : normalized.substring(
                        0,
                        200
                );
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
            String districtCode
    ) {
    }
}
