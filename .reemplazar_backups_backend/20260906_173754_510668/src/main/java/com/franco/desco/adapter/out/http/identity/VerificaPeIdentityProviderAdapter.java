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
import java.util.Locale;
import java.util.Map;

@Component("verificaPeIdentityProviderAdapter")
public final class VerificaPeIdentityProviderAdapter
        implements IdentityProviderPort {

    private static final Logger log =
            LoggerFactory.getLogger(VerificaPeIdentityProviderAdapter.class);

    private static final DateTimeFormatter DATE_DMY =
            DateTimeFormatter.ofPattern("dd/MM/uuuu");

    private static final int MAX_BODY_LOG_LENGTH = 6000;

    private final JsonMapper jsonMapper;
    private final HttpClient httpClient;

    private final boolean enabled;
    private final boolean debugLogging;
    private final String baseUrl;
    private final String apiKey;
    private final String dniPath;
    private final String rucPath;
    private final long readTimeoutMs;

    public VerificaPeIdentityProviderAdapter(
            JsonMapper jsonMapper,
            Environment environment
    ) {
        this.jsonMapper = jsonMapper;

        this.enabled = Boolean.parseBoolean(
                environment.getProperty(
                        "app.verificape.enabled",
                        "false"
                )
        );

        this.debugLogging = Boolean.parseBoolean(
                environment.getProperty(
                        "app.verificape.debug-logging",
                        "false"
                )
        );

        this.baseUrl = normalizeBaseUrl(
                environment.getProperty(
                        "app.verificape.base-url",
                        "https://api.verificape.com"
                )
        );

        this.apiKey = normalize(
                environment.getProperty(
                        "app.verificape.api-key"
                )
        );

        this.dniPath = normalizePath(
                environment.getProperty(
                        "app.verificape.dni-path",
                        "/v1/dni/{documento}"
                )
        );

        this.rucPath = normalizePath(
                environment.getProperty(
                        "app.verificape.ruc-path",
                        "/v1/ruc/{documento}"
                )
        );

        long connectTimeoutMs = positiveLong(
                environment.getProperty(
                        "app.verificape.connect-timeout-ms"
                ),
                5000L
        );

        this.readTimeoutMs = positiveLong(
                environment.getProperty(
                        "app.verificape.read-timeout-ms"
                ),
                8000L
        );

        this.httpClient =
                HttpClient.newBuilder()
                        .connectTimeout(
                                Duration.ofMillis(connectTimeoutMs)
                        )
                        .followRedirects(
                                HttpClient.Redirect.NORMAL
                        )
                        .build();

        log.info(
                "[VERIFICAPE] Client ready enabled={} baseUrl={}",
                enabled,
                baseUrl
        );
    }

    @Override
    public ProviderResult query(
            DocumentType documentType,
            String documentNumber
    ) {
        long started = System.nanoTime();

        String document = normalize(documentNumber);
        String maskedDocument = maskDocument(document);

        if (!enabled) {
            log.warn(
                    "[VERIFICAPE] Request skipped type={} document={} reason=provider_disabled",
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
                    "[VERIFICAPE] Request rejected type={} document={} reason=invalid_request",
                    documentType,
                    maskedDocument
            );
            return ProviderResult.error(
                    "INVALID_REQUEST"
            );
        }

        if (apiKey == null || apiKey.isBlank()) {
            log.error(
                    "[VERIFICAPE] Configuration error: API key is missing."
            );
            return ProviderResult.error(
                    "AUTH_CONFIG_MISSING"
            );
        }

        String path = switch (documentType) {
            case DNI -> dniPath;
            case RUC -> rucPath;
        };

        String resolvedPath =
                path.replace("{documento}", document);

        URI uri;

        try {
            uri = URI.create(
                    baseUrl + resolvedPath
            );
        } catch (RuntimeException exception) {
            log.error(
                    "[VERIFICAPE] Request build failed type={} document={} error={}",
                    documentType,
                    maskedDocument,
                    safeMessage(exception.getMessage())
            );
            log.debug(
                    "[VERIFICAPE] Request build failure detail",
                    exception
            );
            return ProviderResult.error(
                    "INVALID_ENDPOINT"
            );
        }

        HttpRequest request =
                HttpRequest.newBuilder(uri)
                        .timeout(
                                Duration.ofMillis(readTimeoutMs)
                        )
                        .header(
                                "Authorization",
                                "Bearer " + apiKey
                        )
                        .header(
                                "Accept",
                                "application/json"
                        )
                        .GET()
                        .build();

        log.info(
                "[VERIFICAPE] Request type={} document={} method=GET path={}",
                documentType,
                maskedDocument,
                maskPath(resolvedPath, document)
        );

        if (debugLogging && log.isDebugEnabled()) {
            log.debug(
                    "[VERIFICAPE] Request detail url={} headers=Authorization: Bearer ***, Accept: application/json",
                    uri
            );
        }

        try {
            HttpResponse<String> response =
                    httpClient.send(
                            request,
                            HttpResponse.BodyHandlers.ofString(
                                    StandardCharsets.UTF_8
                            )
                    );

            long durationMs = elapsedMs(started);
            int status = response.statusCode();
            String body = response.body() == null
                    ? ""
                    : response.body();

            log.info(
                    "[VERIFICAPE] Response type={} document={} status={} durationMs={}",
                    documentType,
                    maskedDocument,
                    status,
                    durationMs
            );

            if (debugLogging && log.isDebugEnabled()) {
                log.debug(
                        "[VERIFICAPE] Response body type={} document={} body={}",
                        documentType,
                        document,
                        bodyForLog(body)
                );
            }

            return mapResponse(
                    documentType,
                    status,
                    body
            );

        } catch (HttpTimeoutException exception) {
            log.error(
                    "[VERIFICAPE] Request failed type={} document={} stage=timeout durationMs={} error={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started),
                    safeMessage(exception.getMessage())
            );
            log.debug(
                    "[VERIFICAPE] Timeout detail",
                    exception
            );
            return ProviderResult.error(
                    "TIMEOUT"
            );

        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();

            log.error(
                    "[VERIFICAPE] Request interrupted type={} document={} durationMs={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started)
            );
            log.debug(
                    "[VERIFICAPE] Interrupted request detail",
                    exception
            );
            return ProviderResult.error(
                    "INTERRUPTED"
            );

        } catch (IOException exception) {
            log.error(
                    "[VERIFICAPE] Request failed type={} document={} stage=network durationMs={} error={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started),
                    safeMessage(exception.getMessage())
            );
            log.debug(
                    "[VERIFICAPE] Network failure detail",
                    exception
            );
            return ProviderResult.error(
                    "NETWORK_ERROR"
            );

        } catch (RuntimeException exception) {
            log.error(
                    "[VERIFICAPE] Request failed type={} document={} stage=client durationMs={} error={}",
                    documentType,
                    maskedDocument,
                    elapsedMs(started),
                    safeMessage(exception.getMessage())
            );
            log.debug(
                    "[VERIFICAPE] Client failure detail",
                    exception
            );
            return ProviderResult.error(
                    "CLIENT_ERROR"
            );
        }
    }

    private ProviderResult mapResponse(
            DocumentType type,
            int status,
            String body
    ) {
        if (status == 404) {
            return ProviderResult.notFound(
                    "NOT_FOUND"
            );
        }

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

        if (status < 200 || status >= 300) {
            return ProviderResult.error(
                    "HTTP_" + status
            );
        }

        if (body == null || body.isBlank()) {
            return ProviderResult.error(
                    "EMPTY_RESPONSE"
            );
        }

        try {
            Object parsed =
                    jsonMapper.readValue(
                            body,
                            Object.class
                    );

            if (!(parsed instanceof Map<?, ?> root)) {
                return ProviderResult.error(
                        "INVALID_RESPONSE"
                );
            }

            Map<?, ?> data = asMap(
                    valueIgnoreCase(
                            root,
                            "data"
                    )
            );

            Boolean success = booleanValue(
                    valueIgnoreCase(
                            root,
                            "success",
                            "ok"
                    )
            );

            if (Boolean.FALSE.equals(success)) {
                String code = providerErrorCode(root);

                if (looksNotFound(root, code)) {
                    return ProviderResult.notFound(
                            "NOT_FOUND"
                    );
                }

                return ProviderResult.error(code);
            }

            if (data == null) {
                data = root;
            }

            ProviderData providerData =
                    type == DocumentType.DNI
                            ? dniData(data)
                            : rucData(data);

            if (providerData == null) {
                String code = providerErrorCode(root);

                if (looksNotFound(root, code)) {
                    return ProviderResult.notFound(
                            "NOT_FOUND"
                    );
                }

                return ProviderResult.error(
                        "INVALID_RESPONSE"
                );
            }

            return ProviderResult.success(
                    providerData
            );

        } catch (Exception exception) {
            log.error(
                    "[VERIFICAPE] Response parse failed status={} error={}",
                    status,
                    safeMessage(exception.getMessage())
            );
            log.debug(
                    "[VERIFICAPE] Response parse failure detail",
                    exception
            );

            return ProviderResult.error(
                    "INVALID_RESPONSE"
            );
        }
    }

    private ProviderData dniData(
            Map<?, ?> data
    ) {
        String names = textValue(
                valueIgnoreCase(
                        data,
                        "names",
                        "nombres"
                )
        );

        String paternalSurname = textValue(
                valueIgnoreCase(
                        data,
                        "paternalSurname",
                        "apellidoPaterno",
                        "apellido_paterno"
                )
        );

        String maternalSurname = textValue(
                valueIgnoreCase(
                        data,
                        "maternalSurname",
                        "apellidoMaterno",
                        "apellido_materno"
                )
        );

        LocalDate birthDate = dateValue(
                valueIgnoreCase(
                        data,
                        "birthDate",
                        "fechaNacimiento",
                        "fecha_nacimiento"
                )
        );

        if (isBlank(names)
                && isBlank(paternalSurname)
                && isBlank(maternalSurname)) {
            return null;
        }

        return new ProviderData(
                names,
                paternalSurname,
                maternalSurname,
                birthDate,
                null,
                null
        );
    }

    private ProviderData rucData(
            Map<?, ?> data
    ) {
        String businessName = textValue(
                valueIgnoreCase(
                        data,
                        "businessName",
                        "razonSocial",
                        "razon_social",
                        "companyName",
                        "socialReason",
                        "nombreORazonSocial",
                        "name",
                        "fullName"
                )
        );

        String fiscalAddress = textValue(
                valueIgnoreCase(
                        data,
                        "address",
                        "direccion",
                        "direccionFiscal",
                        "direccion_fiscal",
                        "fiscalAddress",
                        "domicilioFiscal"
                )
        );

        if (isBlank(businessName)) {
            return null;
        }

        return new ProviderData(
                null,
                null,
                null,
                null,
                businessName,
                fiscalAddress
        );
    }

    private String providerErrorCode(
            Map<?, ?> root
    ) {
        String direct = textValue(
                valueIgnoreCase(
                        root,
                        "code",
                        "errorCode",
                        "error_code"
                )
        );

        if (!isBlank(direct)) {
            return normalizeCode(direct);
        }

        Object error = valueIgnoreCase(
                root,
                "error"
        );

        if (error instanceof Map<?, ?> errorMap) {
            String nested = textValue(
                    valueIgnoreCase(
                            errorMap,
                            "code",
                            "type"
                    )
            );

            if (!isBlank(nested)) {
                return normalizeCode(nested);
            }
        }

        String message = providerMessage(root);

        return isBlank(message)
                ? "PROVIDER_ERROR"
                : normalizeCode(message);
    }

    private String providerMessage(
            Map<?, ?> root
    ) {
        String direct = textValue(
                valueIgnoreCase(
                        root,
                        "message",
                        "mensaje",
                        "detail"
                )
        );

        if (!isBlank(direct)) {
            return direct;
        }

        Object error = valueIgnoreCase(
                root,
                "error"
        );

        if (error instanceof Map<?, ?> errorMap) {
            return textValue(
                    valueIgnoreCase(
                            errorMap,
                            "message",
                            "mensaje",
                            "detail"
                    )
            );
        }

        return textValue(error);
    }

    private boolean looksNotFound(
            Map<?, ?> root,
            String code
    ) {
        String message = providerMessage(root);

        String text =
                ((code == null ? "" : code)
                        + " "
                        + (message == null ? "" : message))
                        .toLowerCase(Locale.ROOT);

        return text.contains("not_found")
                || text.contains("not found")
                || text.contains("no encontrado")
                || text.contains("no existe")
                || text.contains("sin resultados");
    }

    private Map<?, ?> asMap(Object value) {
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

        for (Map.Entry<?, ?> entry : map.entrySet()) {
            if (entry.getKey() == null) {
                continue;
            }

            String current = entry.getKey().toString();

            for (String key : keys) {
                if (current.equalsIgnoreCase(key)) {
                    return entry.getValue();
                }
            }
        }

        return null;
    }

    private Boolean booleanValue(Object value) {
        if (value instanceof Boolean bool) {
            return bool;
        }

        if (value == null) {
            return null;
        }

        String text = value.toString().trim();

        if ("true".equalsIgnoreCase(text)) {
            return true;
        }

        if ("false".equalsIgnoreCase(text)) {
            return false;
        }

        return null;
    }

    private String textValue(Object value) {
        if (value == null) {
            return null;
        }

        String text = value.toString().trim();

        return text.isEmpty()
                ? null
                : text;
    }

    private LocalDate dateValue(Object value) {
        String text = textValue(value);

        if (text == null) {
            return null;
        }

        try {
            return LocalDate.parse(
                    text,
                    DATE_DMY
            );
        } catch (DateTimeParseException ignored) {
            try {
                return LocalDate.parse(text);
            } catch (DateTimeParseException ignoredAgain) {
                return null;
            }
        }
    }

    private long positiveLong(
            String value,
            long fallback
    ) {
        if (value == null || value.isBlank()) {
            return fallback;
        }

        try {
            long parsed = Long.parseLong(
                    value.trim()
            );

            return parsed > 0
                    ? parsed
                    : fallback;
        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }

    private String normalizeBaseUrl(String value) {
        String normalized = normalize(value);

        if (normalized == null || normalized.isBlank()) {
            return "https://api.verificape.com";
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

    private String normalizePath(String value) {
        String normalized = normalize(value);

        if (normalized == null || normalized.isBlank()) {
            return "/";
        }

        return normalized.startsWith("/")
                ? normalized
                : "/" + normalized;
    }

    private String normalize(String value) {
        return value == null
                ? null
                : value.trim();
    }

    private String maskDocument(String document) {
        if (document == null || document.isBlank()) {
            return "(none)";
        }

        if (document.length() <= 4) {
            return "*".repeat(document.length());
        }

        return "*".repeat(document.length() - 4)
                + document.substring(
                        document.length() - 4
                );
    }

    private String maskPath(
            String path,
            String document
    ) {
        if (path == null || document == null || document.isBlank()) {
            return path;
        }

        return path.replace(
                document,
                maskDocument(document)
        );
    }

    private String normalizeCode(String value) {
        if (value == null || value.isBlank()) {
            return "PROVIDER_ERROR";
        }

        String code =
                value.trim()
                        .toUpperCase(Locale.ROOT)
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
                : code.substring(0, 60);
    }

    private String safeMessage(String value) {
        if (value == null || value.isBlank()) {
            return "(no detail)";
        }

        String text =
                value.replace('\r', ' ')
                        .replace('\n', ' ')
                        .trim();

        return text.length() <= 400
                ? text
                : text.substring(0, 400);
    }

    private String bodyForLog(String body) {
        if (body == null || body.isBlank()) {
            return "(empty)";
        }

        String compact =
                body.replace('\r', ' ')
                        .replace('\n', ' ')
                        .trim();

        return compact.length() <= MAX_BODY_LOG_LENGTH
                ? compact
                : compact.substring(
                        0,
                        MAX_BODY_LOG_LENGTH
                ) + "...(truncated)";
    }

    private long elapsedMs(long startedNanos) {
        return Duration.ofNanos(
                System.nanoTime() - startedNanos
        ).toMillis();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
