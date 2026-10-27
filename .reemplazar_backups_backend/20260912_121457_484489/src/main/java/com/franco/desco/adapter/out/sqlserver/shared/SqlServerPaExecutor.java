package com.franco.desco.adapter.out.sqlserver.shared;

import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;

@Component
public class SqlServerPaExecutor {

    private final JsonMapper jsonMapper;

    public SqlServerPaExecutor(JsonMapper jsonMapper) {
        this.jsonMapper = jsonMapper;
    }

    public Map<String, Object> execute(
            SimpleJdbcCall call,
            Map<String, ?> parameters
    ) {
        try {
            return call.execute(
                    parameters == null
                            ? Map.of()
                            : parameters
            );
        } catch (DataAccessException exception) {
            throw databaseFailure(exception);
        }
    }

    public Map<String, Object> executeJson(
            SimpleJdbcCall call,
            Object payload
    ) {
        try {
            String json = jsonMapper.writeValueAsString(payload);
            return execute(
                    call,
                    Map.of("cJson", json)
            );
        } catch (PaExecutionException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new PaExecutionException(
                    "No fue posible preparar el contrato JSON del procedimiento almacenado.",
                    exception
            );
        }
    }

    public Map<String, Object> executeMutation(
            SimpleJdbcCall call,
            Map<String, ?> parameters
    ) {
        return execute(call, parameters);
    }

    public Map<String, Object> executeJsonMutation(
            SimpleJdbcCall call,
            Object payload
    ) {
        return executeJson(call, payload);
    }

    public <T> Optional<T> executeOne(
            SimpleJdbcCall call,
            Map<String, ?> parameters,
            String resultSetName,
            Function<Map<String, Object>, T> mapper
    ) {
        return executeMultiResult(call, parameters)
                .one(resultSetName)
                .map(mapper);
    }

    public <T> Optional<T> executeJsonOne(
            SimpleJdbcCall call,
            Object payload,
            String resultSetName,
            Function<Map<String, Object>, T> mapper
    ) {
        return executeJsonMultiResult(call, payload)
                .one(resultSetName)
                .map(mapper);
    }

    public <T> List<T> executeList(
            SimpleJdbcCall call,
            Map<String, ?> parameters,
            String resultSetName,
            Function<Map<String, Object>, T> mapper
    ) {
        return executeMultiResult(call, parameters)
                .rows(resultSetName)
                .stream()
                .map(mapper)
                .toList();
    }

    public <T> List<T> executeJsonList(
            SimpleJdbcCall call,
            Object payload,
            String resultSetName,
            Function<Map<String, Object>, T> mapper
    ) {
        return executeJsonMultiResult(call, payload)
                .rows(resultSetName)
                .stream()
                .map(mapper)
                .toList();
    }

    public PaResultSets executeMultiResult(
            SimpleJdbcCall call,
            Map<String, ?> parameters
    ) {
        return new PaResultSets(
                execute(call, parameters)
        );
    }

    public PaResultSets executeJsonMultiResult(
            SimpleJdbcCall call,
            Object payload
    ) {
        return new PaResultSets(
                executeJson(call, payload)
        );
    }

    private PaExecutionException databaseFailure(
            DataAccessException exception
    ) {
        return new PaExecutionException(
                "No fue posible ejecutar el procedimiento almacenado.",
                exception
        );
    }
}
