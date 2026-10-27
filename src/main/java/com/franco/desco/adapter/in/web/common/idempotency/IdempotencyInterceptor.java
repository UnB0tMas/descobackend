package com.franco.desco.adapter.in.web.common.idempotency;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class IdempotencyInterceptor
        implements HandlerInterceptor {

    private final IdempotencyKeyResolver resolver;

    public IdempotencyInterceptor(
            IdempotencyKeyResolver resolver
    ) {
        this.resolver = resolver;
    }

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler
    ) {
        if (!(handler instanceof HandlerMethod handlerMethod)) {
            return true;
        }

        IdempotentOperation annotation =
                handlerMethod.getMethodAnnotation(
                        IdempotentOperation.class
                );

        if (annotation == null) {
            return true;
        }

        resolver.required(request);
        return true;
    }
}
