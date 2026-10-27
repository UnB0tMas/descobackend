package com.franco.desco.adapter.in.web.common.idempotency;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class IdempotencyKeyResolverTest {

    private final IdempotencyKeyResolver resolver =
            new IdempotencyKeyResolver();

    @Test
    void requiredDebeAceptarUuidValidoYReutilizarElValorParseado() {
        UUID key = UUID.randomUUID();
        MockHttpServletRequest request =
                new MockHttpServletRequest();

        request.addHeader(
                IdempotencyKeyResolver.HEADER,
                key.toString()
        );

        UUID first = resolver.required(request);
        UUID second = resolver.required(request);

        assertThat(first).isEqualTo(key);
        assertThat(second).isSameAs(first);
    }

    @Test
    void requiredDebeRechazarHeaderAusente() {
        MockHttpServletRequest request =
                new MockHttpServletRequest();

        assertThatThrownBy(
                () -> resolver.required(request)
        )
                .isInstanceOf(IdempotencyKeyException.class)
                .hasMessageContaining("clave de idempotencia");
    }

    @Test
    void requiredDebeRechazarUuidInvalido() {
        MockHttpServletRequest request =
                new MockHttpServletRequest();

        request.addHeader(
                IdempotencyKeyResolver.HEADER,
                "no-es-un-uuid"
        );

        assertThatThrownBy(
                () -> resolver.required(request)
        )
                .isInstanceOf(IdempotencyKeyException.class)
                .hasMessageContaining("no es válida");
    }
}
