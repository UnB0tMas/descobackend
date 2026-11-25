package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.adapter.in.web.sanitation.SanitationStockController;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Modifier;

import static org.junit.jupiter.api.Assertions.assertFalse;

class SalidaDocumentalControllerProxyTest {
    @Test
    void losControladoresConPermisosPuedenSerProxificadosPorSpring() {
        assertFalse(Modifier.isFinal(SalidaDocumentalController.class.getModifiers()));
        assertFalse(Modifier.isFinal(SanitationStockController.class.getModifiers()));
    }
}
