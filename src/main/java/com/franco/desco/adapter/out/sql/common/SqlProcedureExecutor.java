package com.franco.desco.adapter.out.sql.common;

import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.util.Map;

@Component
public class SqlProcedureExecutor {

    private final DataSource dataSource;

    public SqlProcedureExecutor(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public Map<String, Object> call(
            String schema,
            String procedure,
            Map<String, ?> input,
            SqlParameter... parameters
    ) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withSchemaName(schema)
                .withProcedureName(procedure)
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(parameters);

        return call.execute(new MapSqlParameterSource(input));
    }

    public static boolean success(Map<String, Object> output) {
        Object value = output == null ? null : output.get("bResultado");
        if (value instanceof Boolean bool) return bool;
        if (value instanceof Number number) return number.intValue() != 0;
        return "true".equalsIgnoreCase(String.valueOf(value)) || "1".equals(String.valueOf(value));
    }

    public static String message(Map<String, Object> output, String fallback) {
        Object value = output == null ? null : output.get("cMensaje");
        if (value == null || value.toString().isBlank()) return fallback;
        return value.toString().trim();
    }

    public static Long longValue(Map<String, Object> output, String key) {
        Object value = output == null ? null : output.get(key);
        return value instanceof Number number ? number.longValue() : null;
    }

    public static Integer intValue(Map<String, Object> output, String key) {
        Object value = output == null ? null : output.get(key);
        return value instanceof Number number ? number.intValue() : null;
    }
}
