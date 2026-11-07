package com.franco.desco.adapter.in.web.sanitation;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.Instant;
import static org.junit.jupiter.api.Assertions.*;
class SanitationStockValidationTest {
    private boolean valid(Long program,BigDecimal total) {
        try(var factory=Validation.buildDefaultValidatorFactory()) {
            return factory.getValidator().validate(new SanitationRequests.Treatment(null,1L,
                Instant.now().minusSeconds(1),"Aplicar tratamiento",null,new BigDecimal("0.25"),
                "ml/planta",null,program,total)).isEmpty();
        }
    }
    @Test void cantidadUtilizadaEsIndependienteDeLaDosis() {
        assertTrue(valid(10L,new BigDecimal("3.500")));
        assertTrue(valid(null,null));
    }
    @Test void exigeReferenciaYCantidadJuntas() {
        assertFalse(valid(10L,null));
        assertFalse(valid(null,BigDecimal.ONE));
    }
    @Test void rechazaCantidadesNulasNegativasOConExcesoDePrecision() {
        assertFalse(valid(10L,BigDecimal.ZERO));
        assertFalse(valid(10L,new BigDecimal("-1")));
        assertFalse(valid(10L,new BigDecimal("0.0001")));
    }
}
