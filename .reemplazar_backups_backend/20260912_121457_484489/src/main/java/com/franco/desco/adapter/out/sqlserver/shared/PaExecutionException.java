package com.franco.desco.adapter.out.sqlserver.shared;

public class PaExecutionException extends RuntimeException {

    public PaExecutionException(
            String message,
            Throwable cause
    ) {
        super(message, cause);
    }
}
