# DESCO Backend — limpieza definitiva de VerificaPE y proveedor único Factiliza

## Objetivo

Dejar el módulo de identidad con una sola implementación activa de `IdentityProviderPort`: Factiliza.

El parche elimina las clases legacy conocidas, retira `VERIFICAPE` del dominio, elimina el constructor de compatibilidad que ya no necesitamos y deja la capa de aplicación desacoplada del nombre concreto del proveedor.

La configuración activa `application.properties` ya usa Factiliza, por lo que este parche **no modifica** sus credenciales ni el resto de propiedades.

## Archivos a eliminar

Estas son instrucciones ejecutables para `reemplazar_backend_v2.py`.

Eliminar: `src/main/java/com/franco/desco/adapter/out/http/identity/VerificaPeIdentityProviderAdapter.java`

Eliminar: `src/main/java/com/franco/desco/adapter/out/http/verificape/VerificaPeClient.java`

Eliminar: `../../../../../actividad.md`

### Motivo de cada eliminación

- `VerificaPeIdentityProviderAdapter.java`: implementación anterior de `IdentityProviderPort`; ya no forma parte del flujo activo.
- `VerificaPeClient.java`: cliente legacy que anteriormente registraba una segunda implementación del mismo puerto.
- `../../../../../actividad.md`: archivo de parche antiguo. No es un recurso de ejecución y no debe terminar empaquetado dentro del JAR. A partir de esta versión, `actividad.md` se coloca en la raíz `D:\FrancoSystem\desco\actividad.md`.

Si cualquiera de las dos clases Java ya fue eliminada manualmente, el script mostrará `NO EXISTE` y continuará.

---

## 1. FactilizaIdentityProviderAdapter.java

Ruta: `src/main/java/com/franco/desco/adapter/out/http/identity/FactilizaIdentityProviderAdapter.java`

```java
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
                digits(
                        value(
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
                null,
                geography.sunatCode(),
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
                districtCode,
                sunatCode
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
            String districtCode,
            String sunatCode
    ) {
    }
}
```

---

## 2. IdentityModels.java

Ruta: `src/main/java/com/franco/desco/domain/identity/IdentityModels.java`

```java
package com.franco.desco.domain.identity;

import java.time.Instant;
import java.time.LocalDate;

public final class IdentityModels {

    private IdentityModels() {
    }

    public enum Target {
        PERSONA,
        EMPRESA
    }

    public enum DocumentType {
        DNI,
        RUC
    }

    public enum Origin {
        LOCAL,
        MANUAL
    }

    public record LocalResolution(
            boolean encontradoLocal,
            Target entidadObjetivo,
            Long entidadId,
            String tipoPersona,
            DocumentType tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String razonSocial,
            Boolean estadoEntidad,
            boolean esEmpleado,
            boolean esSocio,
            boolean esAsociacion,
            boolean requiereConsultaExterna,
            DocumentType tipoDocumentoConsultaExterna,
            String numeroDocumentoConsultaExterna,
            String claveConsulta,
            String estadoConsultaPrevia,
            Instant reintentoDesdeUtc,
            Instant bloqueoHastaUtc
    ) {
    }

    public record Reservation(
            boolean puedeConsultar,
            DocumentType tipoDocumentoConsultaExterna,
            String numeroDocumentoConsultaExterna,
            String claveConsulta,
            Instant reintentoDesdeUtc
    ) {
    }

    public record ProviderData(
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            LocalDate fechaNacimiento,
            String razonSocial,
            String direccionFiscal,
            String direccionCompleta,
            String sexo,
            String departamento,
            String provincia,
            String distrito,
            String departamentoCodigo,
            String provinciaCodigo,
            String distritoCodigo,
            String centroPoblado,
            String centroPobladoCodigo,
            String ubigeoReniec,
            String ubigeoSunat,
            String tipoContribuyente,
            String estadoContribuyente,
            String condicionContribuyente
    ) {
    }

    public record ProviderResult(
            boolean exito,
            boolean encontrado,
            String codigoError,
            ProviderData datos
    ) {
        public static ProviderResult success(
                ProviderData data
        ) {
            return new ProviderResult(
                    true,
                    true,
                    null,
                    data
            );
        }

        public static ProviderResult notFound(
                String code
        ) {
            return new ProviderResult(
                    true,
                    false,
                    code,
                    null
            );
        }

        public static ProviderResult error(
                String code
        ) {
            return new ProviderResult(
                    false,
                    false,
                    code,
                    null
            );
        }
    }

    public record PersistOutcome(
            boolean insertado,
            boolean permiteCargaManual,
            Long entidadId,
            String estadoConsulta
    ) {
    }

    public record ResolutionResult(
            Origin origen,
            boolean encontrado,
            boolean insertadoAutomaticamente,
            boolean permiteCargaManual,
            Target entidadObjetivo,
            Long entidadId,
            String tipoPersona,
            DocumentType tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String razonSocial,
            Boolean estadoEntidad,
            boolean esEmpleado,
            boolean esSocio,
            boolean esAsociacion,
            String estadoConsulta,
            String direccionFiscalSugerida,
            Instant reintentoDesdeUtc
    ) {
    }
}
```

---

## 3. IdentityApplicationService.java

Ruta: `src/main/java/com/franco/desco/application/identity/service/IdentityApplicationService.java`

```java
package com.franco.desco.application.identity.service;

import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.application.identity.port.in.IdentityUseCase;
import com.franco.desco.application.identity.port.out.IdentityPersistencePort;
import com.franco.desco.application.identity.port.out.IdentityProviderPort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.identity.IdentityModels.LocalResolution;
import com.franco.desco.domain.identity.IdentityModels.Origin;
import com.franco.desco.domain.identity.IdentityModels.PersistOutcome;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import com.franco.desco.domain.identity.IdentityModels.Reservation;
import com.franco.desco.domain.identity.IdentityModels.ResolutionResult;
import com.franco.desco.domain.identity.PeruvianDocumentRules;

public final class IdentityApplicationService
        implements IdentityUseCase {

    private static final String MANUAL_MESSAGE =
            "No fue posible completar todos los datos automáticamente. "
                    + "Puede continuar y completar la información manualmente.";

    private static final String TEMPORARY_MESSAGE =
            "No fue posible completar la validación en este momento. "
                    + "Intente nuevamente o continúe con el registro manual.";

    private final IdentityPersistencePort persistence;
    private final IdentityProviderPort provider;

    public IdentityApplicationService(
            IdentityPersistencePort persistence,
            IdentityProviderPort provider
    ) {
        this.persistence = persistence;
        this.provider = provider;
    }

    @Override
    public AppResult<ResolutionResult> resolve(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        String document = PeruvianDocumentRules.normalize(
                command.numeroDocumento()
        );

        ResolveDocument normalized = new ResolveDocument(
                command.entidadObjetivo(),
                command.tipoDocumento(),
                document
        );

        if (!PeruvianDocumentRules.validFor(
                normalized.entidadObjetivo(),
                normalized.tipoDocumento(),
                normalized.numeroDocumento()
        )) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "DOCUMENTO_INVALIDO",
                    "El documento ingresado no es válido."
            );
        }

        PersistenceResult<LocalResolution> localResult =
                persistence.resolveLocal(
                        normalized,
                        identity,
                        metadata
                );

        if (!localResult.exitoso()
                || localResult.datos() == null) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "IDENTIDAD_NO_DISPONIBLE",
                    TEMPORARY_MESSAGE
            );
        }

        LocalResolution local = localResult.datos();

        /*
         * Regla principal:
         * si ya existe en DESCO, jamás consumir la API.
         * Los datos faltantes se completan posteriormente mediante los
         * formularios normales de la entidad.
         */
        if (local.encontradoLocal()) {
            return AppResult.ok(
                    "IDENTIDAD_LOCAL",
                    "La información ya se encuentra registrada.",
                    fromLocal(
                            local,
                            false,
                            null
                    )
            );
        }

        if (!local.requiereConsultaExterna()) {
            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    manual(
                            local,
                            local.estadoConsultaPrevia()
                    )
            );
        }

        PersistenceResult<Reservation> reservationResult =
                persistence.reserveExternalQuery(
                        normalized,
                        identity,
                        metadata
                );

        if (!reservationResult.exitoso()
                || reservationResult.datos() == null) {
            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    manual(
                            local,
                            local.estadoConsultaPrevia()
                    )
            );
        }

        Reservation reservation =
                reservationResult.datos();

        if (!reservation.puedeConsultar()) {
            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    manual(
                            local,
                            local.estadoConsultaPrevia(),
                            reservation.reintentoDesdeUtc()
                    )
            );
        }

        ProviderResult providerResult =
                provider.query(
                        reservation.tipoDocumentoConsultaExterna(),
                        reservation.numeroDocumentoConsultaExterna()
                );

        /*
         * El resultado externo siempre pasa por SQL Server.
         * La BD decide si:
         * - inserta Persona/Empresa;
         * - crea catálogo geográfico faltante;
         * - crea Ubicacion;
         * - habilita carga manual;
         * - reutiliza una entidad que otra solicitud insertó en paralelo.
         */
        PersistenceResult<PersistOutcome> persistenceResult =
                persistence.registerExternalResult(
                        normalized,
                        providerResult,
                        identity,
                        metadata
                );

        if (!persistenceResult.exitoso()
                || persistenceResult.datos() == null) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "VALIDACION_NO_COMPLETADA",
                    TEMPORARY_MESSAGE
            );
        }

        PersistOutcome outcome =
                persistenceResult.datos();

        if (outcome.entidadId() == null) {
            String suggestedAddress =
                    providerResult.datos() == null
                            ? null
                            : providerResult.datos().direccionFiscal();

            return AppResult.ok(
                    "IDENTIDAD_CARGA_MANUAL",
                    MANUAL_MESSAGE,
                    new ResolutionResult(
                            Origin.MANUAL,
                            false,
                            false,
                            outcome.permiteCargaManual(),
                            normalized.entidadObjetivo(),
                            null,
                            local.tipoPersona(),
                            normalized.tipoDocumento(),
                            normalized.numeroDocumento(),
                            null,
                            null,
                            null,
                            null,
                            null,
                            false,
                            false,
                            false,
                            outcome.estadoConsulta(),
                            suggestedAddress,
                            reservation.reintentoDesdeUtc()
                    )
            );
        }

        /*
         * Después de persistir la respuesta del proveedor externo, se vuelve a leer
         * desde DESCO. Así el HTTP response se construye siempre desde la
         * fuente local y el proveedor queda encapsulado.
         */
        PersistenceResult<LocalResolution> refreshedResult =
                persistence.resolveLocal(
                        normalized,
                        identity,
                        metadata
                );

        if (!refreshedResult.exitoso()
                || refreshedResult.datos() == null
                || !refreshedResult.datos().encontradoLocal()) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "VALIDACION_NO_COMPLETADA",
                    TEMPORARY_MESSAGE
            );
        }

        String suggestedAddress =
                providerResult.datos() == null
                        ? null
                        : providerResult.datos().direccionFiscal();

        return AppResult.ok(
                outcome.insertado()
                        ? "IDENTIDAD_IMPORTADA"
                        : "IDENTIDAD_REUTILIZADA",
                outcome.insertado()
                        ? "Los datos disponibles fueron validados y guardados correctamente."
                        : "La información ya se encuentra registrada.",
                fromLocal(
                        refreshedResult.datos(),
                        outcome.insertado(),
                        suggestedAddress
                )
        );
    }

    /*
     * Se responde como LOCAL incluso después de una importación.
     *
     * Esto es intencional:
     * - la respuesta se arma después de persistir;
     * - evita filtrar el nombre del proveedor al frontend;
     * - mantiene compatible el Angular actual;
     * - insertadoAutomaticamente permite saber si el registro se creó
     *   durante esta resolución.
     */
    private ResolutionResult fromLocal(
            LocalResolution value,
            boolean inserted,
            String suggestedAddress
    ) {
        return new ResolutionResult(
                Origin.LOCAL,
                true,
                inserted,
                false,
                value.entidadObjetivo(),
                value.entidadId(),
                value.tipoPersona(),
                value.tipoDocumento(),
                value.numeroDocumento(),
                value.nombres(),
                value.apellidoPaterno(),
                value.apellidoMaterno(),
                value.razonSocial(),
                value.estadoEntidad(),
                value.esEmpleado(),
                value.esSocio(),
                value.esAsociacion(),
                value.estadoConsultaPrevia(),
                suggestedAddress,
                value.reintentoDesdeUtc()
        );
    }

    private ResolutionResult manual(
            LocalResolution local,
            String status
    ) {
        return manual(
                local,
                status,
                local.reintentoDesdeUtc()
        );
    }

    private ResolutionResult manual(
            LocalResolution local,
            String status,
            java.time.Instant retryFrom
    ) {
        return new ResolutionResult(
                Origin.MANUAL,
                false,
                false,
                true,
                local.entidadObjetivo(),
                null,
                local.tipoPersona(),
                local.tipoDocumento(),
                local.numeroDocumento(),
                null,
                null,
                null,
                null,
                null,
                false,
                false,
                false,
                status,
                null,
                retryFrom
        );
    }
}
```

---

## 4. IdentityBeanConfig.java

Ruta: `src/main/java/com/franco/desco/infrastructure/config/IdentityBeanConfig.java`

```java
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
```

---

# Estado esperado después del parche

El código fuente activo debe cumplir:

```text
IdentityProviderPort
        |
        +-- FactilizaIdentityProviderAdapter
```

No debe existir:

```text
VerificaPeIdentityProviderAdapter
VerificaPeClient
Origin.VERIFICAPE
app.verificape.*
```

`IdentityModels.Origin` queda únicamente con:

```text
LOCAL
MANUAL
```

El proveedor se mantiene encapsulado. La capa de aplicación trabaja con `IdentityProviderPort` y no necesita conocer el proveedor concreto.

# Verificación

Después de aplicar el Markdown:

```powershell
cd D:\FrancoSystem\desco

Get-ChildItem .\src -Recurse -File |
    Select-String -Pattern 'VerificaPE|VerificaPe|verificape'

mvn clean test
```

El primer comando debe quedar sin resultados relacionados con VerificaPE.

`mvn clean` es importante porque elimina de `target` cualquier `.class` compilado de las clases antiguas.

Luego puede levantarse el backend normalmente.
