package com.franco.desco.adapter.out.sqlserver.shared;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

public final class SqlValues {

    private SqlValues() {
    }

    public static Object value(Map<String, ?> map, String key) {
        if (map == null || key == null) return null;
        if (map.containsKey(key)) return map.get(key);
        return map.entrySet().stream()
                .filter(entry -> entry.getKey() != null && entry.getKey().equalsIgnoreCase(key))
                .map(Map.Entry::getValue)
                .findFirst().orElse(null);
    }

    public static String string(Map<String, ?> map, String key) {
        Object value = value(map, key);
        return value == null ? null : value.toString();
    }

    public static Long longValue(Map<String, ?> map, String key) {
        Object value = value(map, key);
        if (value == null) return null;
        if (value instanceof Number number) return number.longValue();
        return Long.valueOf(value.toString());
    }

    public static Integer intValue(Map<String, ?> map, String key) {
        Object value = value(map, key);
        if (value == null) return null;
        if (value instanceof Number number) return number.intValue();
        return Integer.valueOf(value.toString());
    }

    public static BigDecimal decimal(Map<String, ?> map, String key) {
        Object value = value(map, key);
        if (value == null) return null;
        if (value instanceof BigDecimal decimal) return decimal;
        if (value instanceof Number number) return new BigDecimal(number.toString());
        return new BigDecimal(value.toString());
    }

    public static boolean bool(Map<String, ?> map, String key) {
        Object value = value(map, key);
        if (value == null) return false;
        if (value instanceof Boolean bool) return bool;
        if (value instanceof Number number) return number.intValue() != 0;
        String text = value.toString().trim();
        return "1".equals(text) || "true".equalsIgnoreCase(text) || "si".equalsIgnoreCase(text) || "sí".equalsIgnoreCase(text);
    }

    public static UUID uuid(Map<String, ?> map, String key) {
        Object value = value(map, key);
        if (value == null) return null;
        if (value instanceof UUID uuid) return uuid;
        return UUID.fromString(value.toString());
    }

    public static Instant instant(Map<String, ?> map, String key) {
        Object value = value(map, key);
        if (value == null) return null;
        if (value instanceof Instant instant) return instant;
        if (value instanceof Timestamp timestamp) return timestamp.toInstant();
        if (value instanceof OffsetDateTime offsetDateTime) return offsetDateTime.toInstant();
        if (value instanceof LocalDateTime localDateTime) return localDateTime.toInstant(ZoneOffset.UTC);
        if (value instanceof Date date) return date.toInstant();
        return Instant.parse(value.toString());
    }

    public static LocalDate localDate(Map<String, ?> map, String key) {
        Object value = value(map, key);
        if (value == null) return null;
        if (value instanceof LocalDate localDate) return localDate;
        if (value instanceof java.sql.Date sqlDate) return sqlDate.toLocalDate();
        if (value instanceof Timestamp timestamp) return timestamp.toLocalDateTime().toLocalDate();
        if (value instanceof LocalDateTime localDateTime) return localDateTime.toLocalDate();
        return LocalDate.parse(value.toString());
    }
}
