package com.franco.desco.adapter.out.http.email;

import com.franco.desco.application.shared.port.out.EmailValidationPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Locale;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/** Adaptador HTTP. El API key y los correos nunca se imprimen en logs. */
@Component
public final class AbstractEmailValidationAdapter implements EmailValidationPort {
    private static final Logger log = LoggerFactory.getLogger(AbstractEmailValidationAdapter.class);
    private static final String PROVIDER = "AbstractEmailValidation";
    private static final long CACHE_NANOS = TimeUnit.MINUTES.toNanos(10);
    private static final int MAX_CACHE = 500;

    private final JsonMapper mapper;
    private final HttpClient client;
    private final String endpoint;
    private final String apiKey;
    private final Duration readTimeout;
    private final ConcurrentHashMap<String, Long> validCache = new ConcurrentHashMap<>();

    public AbstractEmailValidationAdapter(JsonMapper mapper, Environment env) {
        this.mapper = mapper;
        this.apiKey = env.getProperty("app.email-validation.api-key", "").trim();
        this.endpoint = env.getProperty("app.email-validation.url", "https://emailvalidation.abstractapi.com/v1/").trim();
        this.readTimeout = Duration.ofMillis(timeout(env, "app.email-validation.read-timeout-ms", 5000));
        this.client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofMillis(timeout(env, "app.email-validation.connect-timeout-ms", 3000)))
                .build();
    }

    @Override
    public Result validate(String email) {
        String normalized = email.trim().toLowerCase(Locale.ROOT);
        long start = System.nanoTime();
        Long expiry = validCache.get(normalized);
        if (expiry != null && System.nanoTime() - expiry < 0) {
            log.info(">> API CACHE proveedor={} resultado=VALID duracionMs=0", PROVIDER);
            return Result.VALID;
        }
        if (apiKey.isBlank()) {
            log.error(">> API ERROR TECNICO proveedor={} http=0 motivo=API_KEY_NO_CONFIGURADA duracionMs={}",
                    PROVIDER, elapsed(start));
            return Result.UNKNOWN;
        }
        try {
            URI uri = URI.create(endpoint + (endpoint.contains("?") ? "&" : "?")
                    + "api_key=" + URLEncoder.encode(apiKey, StandardCharsets.UTF_8)
                    + "&email=" + URLEncoder.encode(normalized, StandardCharsets.UTF_8));
            HttpRequest request = HttpRequest.newBuilder(uri)
                    .timeout(readTimeout)
                    .header("Accept", "application/json")
                    .GET()
                    .build();

            log.info(">> API INICIO proveedor={} metodo=GET duracionMs=0", PROVIDER);
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            int http = response.statusCode();
            if (http != 200) {
                log.warn(">> API ERROR HTTP proveedor={} http={} duracionMs={}", PROVIDER, http, elapsed(start));
                return Result.UNKNOWN;
            }

            JsonNode body = mapper.readTree(response.body());
            String deliverability = body.path("deliverability").stringValue("");
            Boolean format = flag(body.path("is_valid_format"));
            Boolean mx = flag(body.path("is_mx_found"));
            Boolean smtp = flag(body.path("is_smtp_valid"));
            if (Boolean.FALSE.equals(format) || Boolean.FALSE.equals(mx)
                    || Boolean.FALSE.equals(smtp) || "UNDELIVERABLE".equalsIgnoreCase(deliverability)) {
                log.info(">> API ERROR FUNCIONAL proveedor={} http={} resultado=INVALID duracionMs={}",
                        PROVIDER, http, elapsed(start));
                return Result.INVALID;
            }
            if ("DELIVERABLE".equalsIgnoreCase(deliverability)
                    && !Boolean.FALSE.equals(format)
                    && !Boolean.FALSE.equals(mx)
                    && Boolean.TRUE.equals(smtp)) {
                if (validCache.size() >= MAX_CACHE) {
                    validCache.clear();
                }
                validCache.put(normalized, System.nanoTime() + CACHE_NANOS);
                log.info(">> API EXITOSO proveedor={} http={} resultado=VALID duracionMs={}",
                        PROVIDER, http, elapsed(start));
                return Result.VALID;
            }
            log.warn(">> API ERROR FUNCIONAL proveedor={} http={} resultado=UNKNOWN duracionMs={}",
                    PROVIDER, http, elapsed(start));
            return Result.UNKNOWN;
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            log.error(">> API ERROR TECNICO proveedor={} http=0 causa={} duracionMs={}",
                    PROVIDER, ex.getClass().getSimpleName(), elapsed(start));
            return Result.UNKNOWN;
        } catch (Exception ex) {
            // No registrar el mensaje de error: puede incluir la URL con la API key.
            log.error(">> API ERROR TECNICO proveedor={} http=0 causa={} duracionMs={}",
                    PROVIDER, ex.getClass().getSimpleName(), elapsed(start));
            return Result.UNKNOWN;
        }
    }

    private static Boolean flag(JsonNode node) {
        JsonNode value = node.isObject() ? node.path("value") : node;
        return value.isBoolean() ? value.asBoolean() : null;
    }

    private static long timeout(Environment env, String property, long fallback) {
        try {
            long value = Long.parseLong(env.getProperty(property, Long.toString(fallback)));
            return value > 0 && value <= 30000 ? value : fallback;
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private static long elapsed(long started) {
        return TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - started);
    }
}
