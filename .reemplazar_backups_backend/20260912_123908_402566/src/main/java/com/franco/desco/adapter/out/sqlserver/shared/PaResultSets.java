package com.franco.desco.adapter.out.sqlserver.shared;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;

public final class PaResultSets {

    private final Map<String, Object> raw;

    public PaResultSets(Map<String, Object> raw) {
        this.raw = raw == null
                ? Map.of()
                : Collections.unmodifiableMap(
                        new LinkedHashMap<>(raw)
                );
    }

    public Map<String, Object> raw() {
        return raw;
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> rows(
            String resultSetName
    ) {
        Object value = SqlValues.value(
                raw,
                resultSetName
        );

        if (!(value instanceof List<?> list)) {
            return List.of();
        }

        return list.stream()
                .filter(Map.class::isInstance)
                .map(item ->
                        (Map<String, Object>) item
                )
                .toList();
    }

    public Optional<Map<String, Object>> one(
            String resultSetName
    ) {
        return rows(resultSetName)
                .stream()
                .findFirst();
    }

    public <T> List<T> map(
            String resultSetName,
            Function<Map<String, Object>, T> mapper
    ) {
        return rows(resultSetName)
                .stream()
                .map(mapper)
                .toList();
    }

    public <T> Optional<T> mapOne(
            String resultSetName,
            Function<Map<String, Object>, T> mapper
    ) {
        return one(resultSetName)
                .map(mapper);
    }
}
