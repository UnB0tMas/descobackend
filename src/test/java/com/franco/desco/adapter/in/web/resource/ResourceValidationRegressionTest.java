package com.franco.desco.adapter.in.web.resource;

import com.franco.desco.adapter.in.web.common.GlobalExceptionHandler;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.mock.http.MockHttpInputMessage;
import org.springframework.mock.web.MockHttpServletRequest;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class ResourceValidationRegressionTest {
    private ResourceRequests.MovementLine line(String quantity) {
        return new ResourceRequests.MovementLine(1L,new BigDecimal(quantity),null,null,null,null);
    }

    @Test void movementRejectsRoundingButAcceptsExactPrecision() {
        try(var factory=Validation.buildDefaultValidatorFactory()) {
            var validator=factory.getValidator();
            assertFalse(validator.validate(line("1.2345")).isEmpty());
            assertTrue(validator.validate(line("1.234")).isEmpty());
        }
    }

    @Test void genericMovementCannotBeATransfer() {
        try(var factory=Validation.buildDefaultValidatorFactory()) {
            var movement=new ResourceRequests.RegisterMovement(1L,1L,"TRANSFERENCIA","S",
                    List.of(line("1")),null,null,null,null);
            assertFalse(factory.getValidator().validate(movement).isEmpty());
        }
    }

    @Test void missingProductFlagsAreValidationErrors() {
        try(var factory=Validation.buildDefaultValidatorFactory()) {
            var product=new ResourceRequests.CreateProduct(1L,null,"Producto",null,"UND",null,
                    null,null,null,null,null);
            var errors=factory.getValidator().validate(product);
            assertEquals(3, errors.size());
        }
    }

    @Test void malformedRequestReturnsBadRequest() {
        var exception=new HttpMessageNotReadableException("malformed",new MockHttpInputMessage(new byte[0]));
        var request=new MockHttpServletRequest("POST","/api/v1/recursos/movimientos");
        var result=new GlobalExceptionHandler().unreadable(exception,request);
        assertEquals(400,result.getStatusCode().value());
        assertNotNull(result.getBody());
    }
}
