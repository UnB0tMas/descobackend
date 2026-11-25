package com.franco.desco.application.shared.service;

import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.port.out.EmailValidationPort;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class EmailValidationServiceTest {
    private final EmailValidationPort provider = mock(EmailValidationPort.class);

    @Test
    void disabledNeverCallsApiEvenWithoutEmail() {
        EmailValidationService service = new EmailValidationService(provider, false);
        assertThat(service.required(null)).isNull();
        assertThat(service.ifProvided("test@example.com")).isNull();
        verifyNoInteractions(provider);
    }

    @Test
    void invalidEmailStopsPersistenceWithPublicMessage() {
        EmailValidationService service = new EmailValidationService(provider, true);
        when(provider.validate("bad@example.com")).thenReturn(EmailValidationPort.Result.INVALID);
        var result = service.<Long>required("BAD@example.com");
        assertThat(result.exitoso()).isFalse();
        assertThat(result.estado()).isEqualTo(AppStatus.BAD_REQUEST);
        assertThat(result.mensaje()).contains("Ingrese otro correo");
    }

    @Test
    void deliveryUnknownDoesNotAllowSave() {
        EmailValidationService service = new EmailValidationService(provider, true);
        when(provider.validate("test@example.com")).thenReturn(EmailValidationPort.Result.UNKNOWN);
        var result = service.<Long>required("test@example.com");
        assertThat(result.estado()).isEqualTo(AppStatus.SERVICE_UNAVAILABLE);
    }

    @Test
    void confirmedDeliverabilityProceeds() {
        EmailValidationService service = new EmailValidationService(provider, true);
        when(provider.validate("test@example.com")).thenReturn(EmailValidationPort.Result.VALID);
        assertThat(service.required("TEST@EXAMPLE.COM")).isNull();
        verify(provider).validate("test@example.com");
    }

    @Test
    void malformedEmailAvoidsExternalCall() {
        EmailValidationService service = new EmailValidationService(provider, true);
        assertThat(service.required("bad-email")).isNotNull();
        verifyNoInteractions(provider);
    }
}
