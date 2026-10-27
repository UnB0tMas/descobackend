package com.franco.desco.application.shared;

public record PersistenceResult<T>(
        boolean exitoso,
        String codigo,
        String mensaje,
        Integer httpSugerido,
        T datos
) {
    public PersistenceResult {
        codigo = normalize(codigo);
        mensaje = publicMessage(
                mensaje,
                exitoso
                        ? "Acción realizada."
                        : "No se pudo completar la acción."
        );
        if (httpSugerido == null) {
            httpSugerido = exitoso ? 200 : 400;
        }
    }

    public static <T> PersistenceResult<T> ok(String mensaje, T datos) {
        return new PersistenceResult<>(true, null, mensaje, 200, datos);
    }

    public static <T> PersistenceResult<T> ok(
            String codigo,
            String mensaje,
            Integer httpSugerido,
            T datos
    ) {
        return new PersistenceResult<>(
                true,
                normalize(codigo),
                publicMessage(mensaje, "Acción realizada."),
                httpSugerido == null ? 200 : httpSugerido,
                datos
        );
    }

    public static <T> PersistenceResult<T> error(String mensaje) {
        return error(null, mensaje, 400);
    }

    public static <T> PersistenceResult<T> error(
            String codigo,
            String mensaje,
            Integer httpSugerido
    ) {
        return new PersistenceResult<>(
                false,
                normalize(codigo),
                publicMessage(mensaje, "No se pudo completar la acción."),
                httpSugerido == null ? 400 : httpSugerido,
                null
        );
    }

    private static String normalize(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private static String publicMessage(
            String value,
            String fallback
    ) {
        if (value == null || value.isBlank()) {
            return fallback;
        }

        String message = value.trim();

        /*
         * Última barrera defensiva. La BD V3 ya devuelve mensajes públicos,
         * pero nunca se debe propagar un detalle técnico si un PA antiguo,
         * un driver o una integración devuelve accidentalmente ese texto.
         */
        String lower = message.toLowerCase(java.util.Locale.ROOT);
        if (lower.contains("exception")
                || lower.contains("sqlstate")
                || lower.contains("jdbc")
                || lower.contains("stack trace")
                || lower.contains("stored procedure")
                || lower.contains("constraint ")
                || lower.contains("duplicate key")
                || lower.contains("foreign key")
                || lower.contains("line ")
                || lower.contains("nvarchar")
                || lower.contains("varchar")) {
            return fallback;
        }

        return message.length() <= 300
                ? message
                : fallback;
    }
}
