package com.franco.desco.adapter.out.http.email;

import com.franco.desco.application.shared.port.out.EmailValidationPort;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

class AbstractEmailValidationAdapterTest {
    private static final String VALID_RESPONSE = """
            {
              "deliverability": "DELIVERABLE",
              "is_valid_format": {"value": true},
              "is_mx_found": {"value": true},
              "is_smtp_valid": {"value": true}
            }
            """;

    private final AtomicInteger status = new AtomicInteger(200);
    private final AtomicInteger requests = new AtomicInteger();
    private final AtomicReference<String> payload = new AtomicReference<>(VALID_RESPONSE);
    private HttpServer server;

    @BeforeEach
    void startServer() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/", exchange -> {
            requests.incrementAndGet();
            byte[] body = payload.get().getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(status.get(), body.length);
            try (var output = exchange.getResponseBody()) {
                output.write(body);
            }
        });
        server.start();
    }

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void deliverableWithSmtpValidCanBeCached() {
        AbstractEmailValidationAdapter adapter = adapter("example-key");

        assertThat(adapter.validate("TEST@EXAMPLE.COM")).isEqualTo(EmailValidationPort.Result.VALID);
        assertThat(adapter.validate("test@example.com")).isEqualTo(EmailValidationPort.Result.VALID);
        assertThat(requests.get()).isEqualTo(1);
    }

    @Test
    void undeliverableDoesNotPass() {
        payload.set("""
                {"deliverability":"UNDELIVERABLE","is_valid_format":{"value":true},
                 "is_mx_found":{"value":true},"is_smtp_valid":{"value":false}}
                """);

        assertThat(adapter("example-key").validate("bad@example.com"))
                .isEqualTo(EmailValidationPort.Result.INVALID);
    }

    @Test
    void unknownDoesNotPass() {
        payload.set("""
                {"deliverability":"UNKNOWN","is_valid_format":{"value":true},
                 "is_mx_found":{"value":true},"is_smtp_valid":{"value":null}}
                """);

        assertThat(adapter("example-key").validate("maybe@example.com"))
                .isEqualTo(EmailValidationPort.Result.UNKNOWN);
    }

    @Test
    void unexpectedResponseDoesNotPass() {
        payload.set("{\"deliverability\":123}");

        assertThat(adapter("example-key").validate("maybe@example.com"))
                .isEqualTo(EmailValidationPort.Result.UNKNOWN);
    }

    @Test
    void httpErrorsDoNotPassOrCache() {
        status.set(429);
        AbstractEmailValidationAdapter adapter = adapter("example-key");

        assertThat(adapter.validate("test@example.com")).isEqualTo(EmailValidationPort.Result.UNKNOWN);
        status.set(500);
        assertThat(adapter.validate("test@example.com")).isEqualTo(EmailValidationPort.Result.UNKNOWN);
        assertThat(requests.get()).isEqualTo(2);
    }

    @Test
    void missingApiKeyDoesNotConsumeRequests() {
        assertThat(adapter("").validate("test@example.com")).isEqualTo(EmailValidationPort.Result.UNKNOWN);
        assertThat(requests.get()).isZero();
    }

    private AbstractEmailValidationAdapter adapter(String apiKey) {
        MockEnvironment environment = new MockEnvironment()
                .withProperty("app.email-validation.api-key", apiKey)
                .withProperty("app.email-validation.url",
                        "http://127.0.0.1:" + server.getAddress().getPort() + "/v1/");
        return new AbstractEmailValidationAdapter(new JsonMapper(), environment);
    }
}
