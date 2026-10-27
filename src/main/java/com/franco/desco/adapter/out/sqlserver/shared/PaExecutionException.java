package com.franco.desco.adapter.out.sqlserver.shared;

public final class PaExecutionException extends RuntimeException {

    private final String procedure;
    private final int databaseErrorCode;
    private final String sqlState;

    public PaExecutionException(
            String procedure,
            int databaseErrorCode,
            String sqlState,
            Throwable cause
    ) {
        super(
                "No se pudo ejecutar la operación de persistencia.",
                cause
        );
        this.procedure = procedure;
        this.databaseErrorCode = databaseErrorCode;
        this.sqlState = sqlState;
    }

    public String procedure() {
        return procedure;
    }

    public int databaseErrorCode() {
        return databaseErrorCode;
    }

    public String sqlState() {
        return sqlState;
    }

    public boolean duplicateKey() {
        return databaseErrorCode == 2601
                || databaseErrorCode == 2627;
    }

    public boolean retryable() {
        return databaseErrorCode == 1205
                || databaseErrorCode == 1222
                || databaseErrorCode == 40501
                || databaseErrorCode == 40613;
    }
}
