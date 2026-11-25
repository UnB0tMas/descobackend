package com.franco.desco.adapter.out.sqlserver.sanitation;

import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import org.aopalliance.intercept.MethodInterceptor;
import org.junit.jupiter.api.Test;
import org.springframework.aop.framework.ProxyFactory;

import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.mock;

/** Impide reintroducir final en un repositorio sin interfaz que Spring debe proxificar. */
class SanitationStockRepositoryProxyTest {

    @Test
    void springPuedeCrearUnProxyDeRepositorioSinInterfaz() {
        SanitationStockRepository repository =
                new SanitationStockRepository(mock(SqlServerPaExecutor.class));
        ProxyFactory factory = new ProxyFactory(repository);
        factory.setProxyTargetClass(true);
        factory.addAdvice((MethodInterceptor) invocation -> invocation.proceed());

        assertInstanceOf(SanitationStockRepository.class, factory.getProxy());
    }
}
