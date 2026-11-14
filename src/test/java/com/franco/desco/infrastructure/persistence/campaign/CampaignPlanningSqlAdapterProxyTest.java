package com.franco.desco.infrastructure.persistence.campaign;

import org.aopalliance.intercept.MethodInterceptor;
import org.junit.jupiter.api.Test;
import org.springframework.aop.framework.ProxyFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;

import static org.junit.jupiter.api.Assertions.assertInstanceOf;

/** Evita reintroducir una clase final incompatible con el proxy de @Repository. */
class CampaignPlanningSqlAdapterProxyTest {

    @Test
    void springPuedeCrearProxyDeClaseParaTraduccionDeExcepciones() {
        CampaignPlanningSqlAdapter target = new CampaignPlanningSqlAdapter(new JdbcTemplate(), new JsonMapper());
        ProxyFactory factory = new ProxyFactory(target);
        factory.setProxyTargetClass(true);
        factory.addAdvice((MethodInterceptor) invocation -> invocation.proceed());

        assertInstanceOf(CampaignPlanningSqlAdapter.class, factory.getProxy());
    }
}
