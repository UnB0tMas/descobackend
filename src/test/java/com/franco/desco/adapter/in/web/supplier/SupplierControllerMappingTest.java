package com.franco.desco.adapter.in.web.supplier;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponseFactory;
import com.franco.desco.application.supplier.port.in.SupplierUseCase;
import org.junit.jupiter.api.Test;
import org.aopalliance.intercept.MethodInterceptor;
import org.springframework.aop.framework.ProxyFactory;
import org.springframework.web.method.HandlerMethod;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

class SupplierControllerMappingTest {

    @Test
    void permiteProxyCglibEnControladorDeProveedores() {
        var controller = new SupplierController(
            mock(SupplierUseCase.class),
            mock(ApiResponseFactory.class),
            mock(JwtSessionIdentityResolver.class)
        );
        var factory = new ProxyFactory(controller);
        factory.setProxyTargetClass(true);
        factory.addAdvice((MethodInterceptor) invocation -> invocation.proceed());

        assertThat(factory.getProxy()).isInstanceOf(SupplierController.class);
    }

    @Test
    void registraConsultaProveedoresConYSinBarraFinal() throws Exception {
        var controller = new SupplierController(
            mock(SupplierUseCase.class),
            mock(ApiResponseFactory.class),
            mock(JwtSessionIdentityResolver.class)
        );
        var mvc = MockMvcBuilders.standaloneSetup(controller).build();

        for (String path : new String[]{"/api/v1/proveedores", "/api/v1/proveedores/"}) {
            var response = mvc.perform(get(path).param("uotId", "1")).andReturn();
            assertThat(response.getHandler()).as("Ruta: %s", path).isInstanceOf(HandlerMethod.class);
            var handler = (HandlerMethod) response.getHandler();
            assertThat(handler.getBeanType()).isEqualTo(SupplierController.class);
            assertThat(handler.getMethod().getName()).isEqualTo("list");
        }
    }
}
