package com.franco.desco.adapter.out.sqlserver.shared;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

public final class SqlValues {

    private SqlValues() {
    }

    public static Object input(
            Map<String, ?> values,
            String parameterName
    ) {
        if (values == null || values.isEmpty()) {
            return null;
        }

        String name = stripAt(parameterName);

        if (values.containsKey(name)) {
            return values.get(name);
        }

        String decapitalized = decapitalizeTypedPrefix(name);
        if (values.containsKey(decapitalized)) {
            return values.get(decapitalized);
        }

        String normalized = normalize(name);
        for (Map.Entry<String, ?> entry : values.entrySet()) {
            if (normalize(entry.getKey()).equals(normalized)
                    || normalize(entry.getKey()).equals(
                    normalize(decapitalized)
            )) {
                return entry.getValue();
            }
        }

        return null;
    }

    public static boolean containsInput(
            Map<String, ?> values,
            String parameterName
    ) {
        if (values == null || values.isEmpty()) {
            return false;
        }

        String name = stripAt(parameterName);
        String decapitalized = decapitalizeTypedPrefix(name);
        String normalized = normalize(name);
        String normalizedDecapitalized = normalize(decapitalized);

        for (String key : values.keySet()) {
            String normalizedKey = normalize(key);
            if (normalizedKey.equals(normalized)
                    || normalizedKey.equals(normalizedDecapitalized)) {
                return true;
            }
        }

        return false;
    }

    public static String outputKey(String parameterName) {
        return decapitalizeTypedPrefix(
                stripAt(parameterName)
        );
    }

    public static Object normalizeJdbcValue(Object value) {
        if (value instanceof Timestamp timestamp) {
            return timestamp.toInstant();
        }
        if (value instanceof Date date) {
            return date.toLocalDate();
        }
        if (value instanceof LocalDateTime dateTime) {
            return dateTime;
        }
        if (value instanceof OffsetDateTime offsetDateTime) {
            return offsetDateTime.toInstant();
        }
        return value;
    }

    public static <T> T convert(
            Object value,
            Class<T> targetType
    ) {
        if (value == null) {
            return null;
        }

        Object normalized = normalizeJdbcValue(value);

        if (targetType.isInstance(normalized)) {
            return targetType.cast(normalized);
        }

        if (targetType == String.class) {
            return targetType.cast(normalized.toString());
        }

        if (targetType == Long.class || targetType == long.class) {
            return castNumber(normalized, targetType, Number::longValue);
        }

        if (targetType == Integer.class || targetType == int.class) {
            return castNumber(normalized, targetType, Number::intValue);
        }

        if (targetType == Short.class || targetType == short.class) {
            return castNumber(normalized, targetType, Number::shortValue);
        }

        if (targetType == Double.class || targetType == double.class) {
            return castNumber(normalized, targetType, Number::doubleValue);
        }

        if (targetType == BigDecimal.class) {
            if (normalized instanceof BigDecimal decimal) {
                return targetType.cast(decimal);
            }
            if (normalized instanceof Number number) {
                return targetType.cast(
                        new BigDecimal(number.toString())
                );
            }
            return targetType.cast(
                    new BigDecimal(normalized.toString())
            );
        }

        if (targetType == Boolean.class || targetType == boolean.class) {
            Boolean result;
            if (normalized instanceof Boolean bool) {
                result = bool;
            } else if (normalized instanceof Number number) {
                result = number.intValue() != 0;
            } else {
                String text = normalized.toString().trim();
                result = "1".equals(text)
                        || "true".equalsIgnoreCase(text)
                        || "si".equalsIgnoreCase(text)
                        || "sí".equalsIgnoreCase(text);
            }
            @SuppressWarnings("unchecked")
            T cast = (T) result;
            return cast;
        }

        if (targetType == UUID.class) {
            return targetType.cast(
                    UUID.fromString(normalized.toString())
            );
        }

        if (targetType == Instant.class) {
            if (normalized instanceof Instant instant) {
                return targetType.cast(instant);
            }
            if (normalized instanceof LocalDateTime localDateTime) {
                return targetType.cast(
                        localDateTime.toInstant(
                                java.time.ZoneOffset.UTC
                        )
                );
            }
            return targetType.cast(
                    Instant.parse(normalized.toString())
            );
        }

        if (targetType == LocalDate.class) {
            if (normalized instanceof LocalDate localDate) {
                return targetType.cast(localDate);
            }
            if (normalized instanceof LocalDateTime localDateTime) {
                return targetType.cast(localDateTime.toLocalDate());
            }
            return targetType.cast(
                    LocalDate.parse(normalized.toString())
            );
        }

        if (targetType.isEnum()) {
            @SuppressWarnings({
                    "rawtypes",
                    "unchecked"
            })
            T enumValue = (T) Enum.valueOf(
                    (Class<? extends Enum>) targetType,
                    normalized.toString()
                            .trim()
                            .toUpperCase(Locale.ROOT)
            );
            return enumValue;
        }

        throw new IllegalArgumentException(
                "Conversión JDBC no soportada para "
                        + targetType.getName()
        );
    }

    private static <T> T castNumber(
            Object value,
            Class<T> targetType,
            java.util.function.Function<Number, ?> converter
    ) {
        if (!(value instanceof Number number)) {
            throw new IllegalArgumentException(
                    "El valor no es numérico."
            );
        }
        @SuppressWarnings("unchecked")
        T result = (T) converter.apply(number);
        return result;
    }

    private static String stripAt(String value) {
        if (value == null) {
            return "";
        }
        return value.startsWith("@")
                ? value.substring(1)
                : value;
    }

    private static String decapitalizeTypedPrefix(
            String value
    ) {
        if (value == null || value.length() < 2) {
            return value;
        }

        char first = Character.toLowerCase(
                value.charAt(0)
        );

        if ("cndbgx".indexOf(first) < 0
                || !Character.isUpperCase(
                value.charAt(1)
        )) {
            return Character.toLowerCase(
                    value.charAt(0)
            ) + value.substring(1);
        }

        String withoutPrefix = value.substring(1);
        return Character.toLowerCase(
                withoutPrefix.charAt(0)
        ) + withoutPrefix.substring(1);
    }

    private static String normalize(String value) {
        if (value == null) {
            return "";
        }

        return value
                .replace("@", "")
                .replace("_", "")
                .replace("-", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }
}
