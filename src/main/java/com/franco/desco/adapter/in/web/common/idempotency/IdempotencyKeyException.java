package com.franco.desco.adapter.in.web.common.idempotency;

public class IdempotencyKeyException
        extends RuntimeException {

    public IdempotencyKeyException(String message) {
        super(message);
    }
}
