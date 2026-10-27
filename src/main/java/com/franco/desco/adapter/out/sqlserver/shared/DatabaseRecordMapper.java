package com.franco.desco.adapter.out.sqlserver.shared;

import org.springframework.stereotype.Component;

import java.lang.reflect.Constructor;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.RecordComponent;
import java.lang.reflect.Type;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Component
public final class DatabaseRecordMapper {

    public <T> T row(
            Map<String, Object> source,
            Class<T> targetType
    ) {
        if (source == null) {
            return null;
        }

        if (!targetType.isRecord()) {
            if (source.size() == 1) {
                Object value = source
                        .values()
                        .iterator()
                        .next();
                return SqlValues.convert(
                        value,
                        targetType
                );
            }
            throw new IllegalArgumentException(
                    "El destino debe ser un record o un valor escalar."
            );
        }

        try {
            RecordComponent[] components =
                    targetType.getRecordComponents();

            Class<?>[] types =
                    new Class<?>[components.length];

            Object[] values =
                    new Object[components.length];

            Map<String, Object> normalized =
                    normalize(source);

            for (int index = 0;
                 index < components.length;
                 index++) {

                RecordComponent component =
                        components[index];

                types[index] = component.getType();

                if (List.class.isAssignableFrom(
                        component.getType()
                )) {
                    values[index] = List.of();
                    continue;
                }

                if (component.getType().isRecord()) {
                    values[index] = row(
                            source,
                            component.getType()
                    );
                    continue;
                }

                Object raw = normalized.get(
                        key(component.getName())
                );

                values[index] = convertNullable(
                        raw,
                        component.getType()
                );
            }

            Constructor<T> constructor =
                    targetType.getDeclaredConstructor(types);

            constructor.setAccessible(true);

            return constructor.newInstance(values);

        } catch (ReflectiveOperationException exception) {
            throw new IllegalStateException(
                    "No se pudo mapear el resultado de persistencia.",
                    exception
            );
        }
    }

    public <T> List<T> rows(
            List<Map<String, Object>> rows,
            Class<T> targetType
    ) {
        if (rows == null || rows.isEmpty()) {
            return List.of();
        }

        return rows.stream()
                .map(row -> row(row, targetType))
                .toList();
    }

    public <T> T aggregate(
            List<List<Map<String, Object>>> resultSets,
            Class<T> targetType
    ) {
        if (resultSets == null
                || resultSets.isEmpty()
                || resultSets.getFirst().isEmpty()) {
            return null;
        }

        if (!targetType.isRecord()) {
            return row(
                    resultSets.getFirst().getFirst(),
                    targetType
            );
        }

        Map<String, Object> main =
                resultSets.getFirst().getFirst();

        try {
            RecordComponent[] components =
                    targetType.getRecordComponents();

            Class<?>[] types =
                    new Class<?>[components.length];

            Object[] values =
                    new Object[components.length];

            Map<String, Object> normalized =
                    normalize(main);

            int listResultSet = 1;

            for (int index = 0;
                 index < components.length;
                 index++) {

                RecordComponent component =
                        components[index];

                types[index] = component.getType();

                if (List.class.isAssignableFrom(
                        component.getType()
                )) {
                    Class<?> elementType =
                            listElementType(component);

                    List<Map<String, Object>> rows =
                            listResultSet < resultSets.size()
                                    ? resultSets.get(listResultSet)
                                    : List.of();

                    values[index] = rows(
                            rows,
                            elementType
                    );

                    listResultSet++;
                    continue;
                }

                if (component.getType().isRecord()) {
                    values[index] = row(
                            main,
                            component.getType()
                    );
                    continue;
                }

                Object raw = normalized.get(
                        key(component.getName())
                );

                values[index] = convertNullable(
                        raw,
                        component.getType()
                );
            }

            Constructor<T> constructor =
                    targetType.getDeclaredConstructor(types);

            constructor.setAccessible(true);

            return constructor.newInstance(values);

        } catch (ReflectiveOperationException exception) {
            throw new IllegalStateException(
                    "No se pudo construir el resultado agregado.",
                    exception
            );
        }
    }

    public Long firstLong(
            PaExecution execution
    ) {
        if (execution == null) {
            return null;
        }

        for (Map.Entry<String, Object> entry
                : execution.outputs().entrySet()) {

            String key = entry.getKey()
                    .toLowerCase(Locale.ROOT);

            if (key.contains("resultado")
                    || key.contains("http")
                    || key.contains("mensaje")
                    || key.contains("codigo")) {
                continue;
            }

            Object value = entry.getValue();

            if (value instanceof Number number) {
                return number.longValue();
            }
        }

        if (!execution.resultSets().isEmpty()
                && !execution.resultSets()
                .getFirst()
                .isEmpty()) {

            for (Object value : execution
                    .resultSets()
                    .getFirst()
                    .getFirst()
                    .values()) {

                if (value instanceof Number number) {
                    return number.longValue();
                }
            }
        }

        return null;
    }

    public long total(
            List<Map<String, Object>> rows
    ) {
        if (rows == null || rows.isEmpty()) {
            return 0L;
        }

        Map<String, Object> normalized =
                normalize(rows.getFirst());

        Object raw = normalized.get(
                key("totalRegistros")
        );

        return raw instanceof Number number
                ? number.longValue()
                : 0L;
    }

    private Class<?> listElementType(
            RecordComponent component
    ) {
        Type genericType =
                component.getGenericType();

        if (!(genericType
                instanceof ParameterizedType parameterizedType)) {
            return Map.class;
        }

        Type argument =
                parameterizedType
                        .getActualTypeArguments()[0];

        if (argument instanceof Class<?> clazz) {
            return clazz;
        }

        throw new IllegalArgumentException(
                "No se pudo resolver el tipo de la lista "
                        + component.getName()
        );
    }

    private Object convertNullable(
            Object raw,
            Class<?> type
    ) {
        if (raw == null) {
            if (!type.isPrimitive()) {
                return null;
            }

            if (type == boolean.class) {
                return false;
            }
            if (type == int.class) {
                return 0;
            }
            if (type == long.class) {
                return 0L;
            }
            if (type == double.class) {
                return 0D;
            }
            if (type == float.class) {
                return 0F;
            }
            if (type == short.class) {
                return (short) 0;
            }
            if (type == byte.class) {
                return (byte) 0;
            }
            if (type == char.class) {
                return '\0';
            }
        }

        return SqlValues.convert(
                raw,
                boxed(type)
        );
    }

    private Class<?> boxed(Class<?> type) {
        if (!type.isPrimitive()) {
            return type;
        }

        if (type == boolean.class) return Boolean.class;
        if (type == int.class) return Integer.class;
        if (type == long.class) return Long.class;
        if (type == double.class) return Double.class;
        if (type == float.class) return Float.class;
        if (type == short.class) return Short.class;
        if (type == byte.class) return Byte.class;
        if (type == char.class) return Character.class;

        return type;
    }

    private Map<String, Object> normalize(
            Map<String, Object> source
    ) {
        Map<String, Object> result =
                new LinkedHashMap<>();

        source.forEach(
                (column, value) ->
                        result.put(
                                key(column),
                                SqlValues.normalizeJdbcValue(value)
                        )
        );

        return result;
    }

    private String key(String value) {
        return value == null
                ? ""
                : value
                .replace("_", "")
                .replace("-", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }
}
