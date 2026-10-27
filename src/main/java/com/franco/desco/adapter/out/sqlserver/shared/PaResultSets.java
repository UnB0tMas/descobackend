package com.franco.desco.adapter.out.sqlserver.shared;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

public class PaResultSets {

    protected PaResultSets() {
    }

    public static Object value(
            Map<?, ?> values,
            String key
    ) {
        if (values == null
                || values.isEmpty()
                || key == null
                || key.isBlank()) {
            return null;
        }

        if (values.containsKey(key)) {
            return values.get(key);
        }

        String requested = normalize(key);
        String requestedWithoutPrefix =
                normalize(decapitalizeTypedPrefix(stripAt(key)));

        for (Map.Entry<?, ?> entry : values.entrySet()) {
            if (entry.getKey() == null) {
                continue;
            }

            String current = entry.getKey().toString();
            String normalized = normalize(current);
            String normalizedWithoutPrefix =
                    normalize(decapitalizeTypedPrefix(stripAt(current)));

            if (normalized.equals(requested)
                    || normalized.equals(requestedWithoutPrefix)
                    || normalizedWithoutPrefix.equals(requested)
                    || normalizedWithoutPrefix.equals(requestedWithoutPrefix)) {
                return entry.getValue();
            }
        }

        return null;
    }

    public static String string(
            Map<?, ?> values,
            String key
    ) {
        Object value = value(values, key);

        if (value == null) {
            return null;
        }

        String text = value.toString().trim();

        return text.isEmpty()
                ? null
                : text;
    }

    public static Long longValue(
            Map<?, ?> values,
            String key
    ) {
        Object value = value(values, key);

        if (value instanceof Number number) {
            return number.longValue();
        }

        String text = string(values, key);

        if (text == null) {
            return null;
        }

        try {
            return Long.valueOf(text);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    public static Integer intValue(
            Map<?, ?> values,
            String key
    ) {
        Object value = value(values, key);

        if (value instanceof Number number) {
            return number.intValue();
        }

        String text = string(values, key);

        if (text == null) {
            return null;
        }

        try {
            return Integer.valueOf(text);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    public static BigDecimal decimal(
            Map<?, ?> values,
            String key
    ) {
        Object value = value(values, key);

        if (value instanceof BigDecimal decimal) {
            return decimal;
        }

        if (value instanceof Number number) {
            return BigDecimal.valueOf(
                    number.doubleValue()
            );
        }

        String text = string(values, key);

        if (text == null) {
            return null;
        }

        try {
            return new BigDecimal(text);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    public static boolean bool(
            Map<?, ?> values,
            String key
    ) {
        Object value = value(values, key);

        if (value instanceof Boolean booleanValue) {
            return booleanValue;
        }

        if (value instanceof Number number) {
            return number.intValue() != 0;
        }

        if (value == null) {
            return false;
        }

        String text =
                value.toString()
                        .trim()
                        .toUpperCase(Locale.ROOT);

        return "1".equals(text)
                || "TRUE".equals(text)
                || "SI".equals(text)
                || "SÍ".equals(text)
                || "S".equals(text)
                || "YES".equals(text)
                || "Y".equals(text);
    }

    public static Instant instant(
            Map<?, ?> values,
            String key
    ) {
        Object value = value(values, key);

        if (value == null) {
            return null;
        }

        if (value instanceof Instant instant) {
            return instant;
        }

        if (value instanceof Timestamp timestamp) {
            return timestamp.toInstant();
        }

        if (value instanceof OffsetDateTime offsetDateTime) {
            return offsetDateTime.toInstant();
        }

        if (value instanceof LocalDateTime localDateTime) {
            return localDateTime.toInstant(ZoneOffset.UTC);
        }

        if (value instanceof java.util.Date date) {
            return date.toInstant();
        }

        String text = value.toString().trim();

        if (text.isEmpty()) {
            return null;
        }

        try {
            return Instant.parse(text);
        } catch (RuntimeException ignored) {
            // Probar formatos SQL/ISO sin zona explícita.
        }

        try {
            return OffsetDateTime.parse(text).toInstant();
        } catch (RuntimeException ignored) {
            // Probar fecha-hora local como UTC.
        }

        try {
            return LocalDateTime.parse(text).toInstant(ZoneOffset.UTC);
        } catch (RuntimeException ignored) {
            return null;
        }
    }

    public static UUID uuid(
            Map<?, ?> values,
            String key
    ) {
        Object value = value(values, key);

        if (value instanceof UUID uuid) {
            return uuid;
        }

        if (value == null) {
            return null;
        }

        String text = value.toString().trim();

        if (text.isEmpty()) {
            return null;
        }

        try {
            return UUID.fromString(text);
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    private static String stripAt(String value) {
        if (value == null) {
            return "";
        }

        String text = value.trim();

        return text.startsWith("@")
                ? text.substring(1)
                : text;
    }

    private static String decapitalizeTypedPrefix(
            String value
    ) {
        if (value == null || value.length() < 2) {
            return value;
        }

        char first =
                Character.toLowerCase(
                        value.charAt(0)
                );

        if ("cndbgx".indexOf(first) < 0
                || !Character.isUpperCase(
                value.charAt(1)
        )) {
            return value;
        }

        String withoutPrefix =
                value.substring(1);

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
                .replace(" ", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }
}
