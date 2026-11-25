package com.franco.desco.infrastructure.bootstrap;

import org.aopalliance.intercept.MethodInterceptor;
import org.junit.jupiter.api.Test;
import org.springframework.aop.framework.ProxyFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;

class CorrespondenceAdminUotBootstrapTest {

    @Test
    void springPuedeCrearProxyDeClaseTransaccional() throws NoSuchMethodException {
        assertThat(CorrespondenceAdminUotBootstrap.class
                .getMethod("run", ApplicationArguments.class)
                .isAnnotationPresent(Transactional.class)).isTrue();

        CorrespondenceAdminUotBootstrap bootstrap =
                new CorrespondenceAdminUotBootstrap(new JdbcTemplate());
        ProxyFactory factory = new ProxyFactory(bootstrap);
        factory.setProxyTargetClass(true);
        factory.addAdvice((MethodInterceptor) invocation -> invocation.proceed());

        assertThat(factory.getProxy()).isInstanceOf(CorrespondenceAdminUotBootstrap.class);
    }
}
