package com.franco.desco.contract;

import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.localdocument.LocalDocumentController;
import com.franco.desco.adapter.in.web.localdocument.LocalDocumentResponses;
import com.franco.desco.adapter.in.web.resource.ResourceController;
import com.franco.desco.adapter.in.web.resource.ResourceRequests;
import com.franco.desco.adapter.in.web.resource.ResourceResponses;
import com.franco.desco.adapter.in.web.sale.SaleController;
import com.franco.desco.adapter.in.web.sale.SaleRequests;
import com.franco.desco.adapter.in.web.sale.SaleResponses;
import com.franco.desco.adapter.in.web.uot.UotController;
import com.franco.desco.adapter.in.web.uot.UotRequests;
import com.franco.desco.adapter.in.web.uot.UotResponses;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.*;

import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class OpenApiNewModulesContractTest {

    private static final Class<?>[] CONTROLLERS = {
            UotController.class,
            ResourceController.class,
            SaleController.class,
            LocalDocumentController.class
    };

    private static final Class<?>[] SCHEMA_CONTAINERS = {
            UotRequests.class,
            UotResponses.class,
            ResourceRequests.class,
            ResourceResponses.class,
            SaleRequests.class,
            SaleResponses.class,
            LocalDocumentResponses.class
    };

    @Test
    void everyNewEndpointHasStableUniqueOperationId() {
        Set<String> operationIds = new HashSet<>();
        int endpointCount = 0;

        for (Class<?> controller : CONTROLLERS) {
            for (Method method : controller.getDeclaredMethods()) {
                if (!isEndpoint(method)) {
                    continue;
                }

                endpointCount++;
                Operation operation = method.getAnnotation(Operation.class);
                assertNotNull(
                        operation,
                        () -> controller.getSimpleName() + "." + method.getName() + " debe declarar @Operation."
                );
                assertFalse(
                        operation.operationId().isBlank(),
                        () -> controller.getSimpleName() + "." + method.getName() + " debe declarar operationId estable."
                );
                assertTrue(
                        operationIds.add(operation.operationId()),
                        () -> "operationId duplicado: " + operation.operationId()
                );
            }
        }

        assertEquals(51, endpointCount, "Cambió la superficie de endpoints nuevos; revise el contrato OpenAPI.");
    }

    @Test
    void requestAndResponseRecordsHaveStableSchemaNames() {
        for (Class<?> container : SCHEMA_CONTAINERS) {
            for (Class<?> nested : container.getDeclaredClasses()) {
                if (!nested.isRecord()) {
                    continue;
                }

                Schema schema = nested.getAnnotation(Schema.class);
                assertNotNull(
                        schema,
                        () -> nested.getName() + " debe declarar @Schema para que OpenAPI Generator produzca un modelo estable."
                );
                assertFalse(
                        schema.name().isBlank(),
                        () -> nested.getName() + " debe declarar un nombre de schema estable."
                );
            }
        }
    }

    @Test
    void genericApiResponseMustNotForceSingleSchemaName() {
        Schema schema = ApiResponse.class.getAnnotation(Schema.class);
        assertNotNull(schema);
        assertTrue(
                schema.name().isBlank(),
                "ApiResponse<T> no debe fijar name=ApiResponse porque colapsa las especializaciones genéricas."
        );
    }

    private boolean isEndpoint(Method method) {
        return method.isAnnotationPresent(GetMapping.class)
                || method.isAnnotationPresent(PostMapping.class)
                || method.isAnnotationPresent(PutMapping.class)
                || method.isAnnotationPresent(DeleteMapping.class)
                || method.isAnnotationPresent(PatchMapping.class)
                || method.isAnnotationPresent(RequestMapping.class);
    }
}
