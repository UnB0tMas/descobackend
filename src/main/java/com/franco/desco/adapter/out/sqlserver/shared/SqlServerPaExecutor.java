package com.franco.desco.adapter.out.sqlserver.shared;

import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public final class SqlServerPaExecutor {

    private final JdbcTemplate jdbcTemplate;

    private final Map<String, List<ParameterMetadata>>
            metadataCache =
            new ConcurrentHashMap<>();

    public SqlServerPaExecutor(
            JdbcTemplate jdbcTemplate
    ) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public PaExecution execute(
            String procedure,
            Map<String, ?> inputs
    ) {
        String normalizedProcedure =
                normalizeProcedure(procedure);

        List<ParameterMetadata> parameters =
                metadataCache.computeIfAbsent(
                        normalizedProcedure,
                        this::loadMetadata
                );

        if (parameters.isEmpty()) {
            throw new IllegalArgumentException(
                    "El procedimiento no existe o no expone parámetros: "
                            + normalizedProcedure
            );
        }

        String callSql =
                buildCall(
                        normalizedProcedure,
                        parameters.size()
                );

        try {
            return jdbcTemplate.execute(
                    (ConnectionCallback<PaExecution>) (Connection connection) ->
                            execute(
                                    connection,
                                    normalizedProcedure,
                                    callSql,
                                    parameters,
                                    inputs == null
                                            ? Map.of()
                                            : inputs
                            )
            );

        } catch (DataAccessException exception) {
            Throwable root =
                    rootCause(exception);

            if (root instanceof SQLException sqlException) {
                throw new PaExecutionException(
                        normalizedProcedure,
                        sqlException.getErrorCode(),
                        sqlException.getSQLState(),
                        exception
                );
            }

            throw new PaExecutionException(
                    normalizedProcedure,
                    0,
                    null,
                    exception
            );
        }
    }

    public void clearMetadataCache() {
        metadataCache.clear();
    }

    private PaExecution execute(
            Connection connection,
            String procedure,
            String callSql,
            List<ParameterMetadata> parameters,
            Map<String, ?> inputs
    ) throws SQLException {

        try (CallableStatement statement =
                     connection.prepareCall(callSql)) {

            for (int index = 0;
                 index < parameters.size();
                 index++) {

                ParameterMetadata parameter =
                        parameters.get(index);

                int jdbcIndex = index + 1;

                boolean hasInput =
                        SqlValues.containsInput(
                                inputs,
                                parameter.name()
                        );

                if (hasInput) {
                    set(
                            statement,
                            jdbcIndex,
                            parameter,
                            SqlValues.input(
                                    inputs,
                                    parameter.name()
                            )
                    );
                } else if (!parameter.output()) {
                    /*
                     * Los PA V3 utilizan parámetros con valores por defecto
                     * únicamente cuando se invocan por nombre desde T-SQL.
                     * En JDBC posicional todos los parámetros declarados deben
                     * representarse, por lo que se envía NULL si el adapter no
                     * suministró un valor.
                     */
                    statement.setNull(
                            jdbcIndex,
                            parameter.jdbcType()
                    );
                }

                if (parameter.output()) {
                    statement.registerOutParameter(
                            jdbcIndex,
                            parameter.jdbcType()
                    );
                }
            }

            List<List<Map<String, Object>>> resultSets =
                    new ArrayList<>();

            boolean result =
                    statement.execute();

            while (true) {
                if (result) {
                    try (ResultSet resultSet =
                                 statement.getResultSet()) {

                        resultSets.add(
                                read(resultSet)
                        );
                    }
                } else {
                    int updateCount =
                            statement.getUpdateCount();

                    if (updateCount == -1) {
                        break;
                    }
                }

                result = statement.getMoreResults(
                        Statement.CLOSE_CURRENT_RESULT
                );
            }

            Map<String, Object> outputs =
                    new LinkedHashMap<>();

            for (int index = 0;
                 index < parameters.size();
                 index++) {

                ParameterMetadata parameter =
                        parameters.get(index);

                if (!parameter.output()) {
                    continue;
                }

                Object value =
                        statement.getObject(index + 1);

                outputs.put(
                        SqlValues.outputKey(
                                parameter.name()
                        ),
                        SqlValues.normalizeJdbcValue(
                                value
                        )
                );
            }

            boolean successful =
                    booleanOutput(
                            outputs,
                            "resultado",
                            true
                    );

            String message =
                    stringOutput(
                            outputs,
                            "mensaje",
                            successful
                                    ? "Acción realizada."
                                    : "No se pudo completar la acción."
                    );

            String code =
                    stringOutput(
                            outputs,
                            "codigoRespuesta",
                            successful
                                    ? "ACCION_REALIZADA"
                                    : "ACCION_NO_COMPLETADA"
                    );

            Integer http =
                    integerOutput(
                            outputs,
                            "httpRespuesta",
                            successful ? 200 : 400
                    );

            return new PaExecution(
                    successful,
                    code,
                    message,
                    http,
                    resultSets,
                    outputs
            );

        } catch (SQLException exception) {
            throw new PaExecutionException(
                    procedure,
                    exception.getErrorCode(),
                    exception.getSQLState(),
                    exception
            );
        }
    }

    private List<ParameterMetadata> loadMetadata(
            String procedure
    ) {
        String sql = """
                SELECT
                    P.parameter_id,
                    P.name,
                    T.name AS type_name,
                    P.max_length,
                    P.precision,
                    P.scale,
                    P.is_output
                FROM sys.parameters P
                INNER JOIN sys.types T
                    ON T.user_type_id = P.user_type_id
                WHERE P.object_id = OBJECT_ID(?)
                ORDER BY P.parameter_id
                """;

        return jdbcTemplate.query(
                sql,
                (resultSet, rowNumber) ->
                        new ParameterMetadata(
                                resultSet.getInt("parameter_id"),
                                resultSet.getString("name"),
                                resultSet.getString("type_name"),
                                jdbcType(
                                        resultSet.getString("type_name")
                                ),
                                resultSet.getInt("max_length"),
                                resultSet.getInt("precision"),
                                resultSet.getInt("scale"),
                                resultSet.getBoolean("is_output")
                        ),
                procedure
        );
    }

    private List<Map<String, Object>> read(
            ResultSet resultSet
    ) throws SQLException {

        List<Map<String, Object>> rows =
                new ArrayList<>();

        ResultSetMetaData metadata =
                resultSet.getMetaData();

        int columns =
                metadata.getColumnCount();

        while (resultSet.next()) {
            Map<String, Object> row =
                    new LinkedHashMap<>();

            for (int column = 1;
                 column <= columns;
                 column++) {

                String label =
                        metadata.getColumnLabel(column);

                row.put(
                        label,
                        SqlValues.normalizeJdbcValue(
                                resultSet.getObject(column)
                        )
                );
            }

            rows.add(row);
        }

        return rows;
    }

    private void set(
            CallableStatement statement,
            int index,
            ParameterMetadata parameter,
            Object value
    ) throws SQLException {

        if (value == null) {
            statement.setNull(
                    index,
                    parameter.jdbcType()
            );
            return;
        }

        if (value instanceof java.util.UUID uuid) {
            statement.setObject(
                    index,
                    uuid.toString(),
                    Types.VARCHAR
            );
            return;
        }

        if (value instanceof LocalDate date) {
            statement.setDate(
                    index,
                    java.sql.Date.valueOf(date)
            );
            return;
        }

        if (value instanceof java.time.Instant instant) {
            statement.setTimestamp(
                    index,
                    java.sql.Timestamp.from(instant)
            );
            return;
        }

        if (value instanceof LocalDateTime dateTime) {
            statement.setTimestamp(
                    index,
                    java.sql.Timestamp.valueOf(dateTime)
            );
            return;
        }

        if (value instanceof Boolean bool) {
            statement.setBoolean(index, bool);
            return;
        }

        if (value instanceof BigDecimal decimal) {
            statement.setBigDecimal(index, decimal);
            return;
        }

        /*
         * SQL Server JDBC convierte correctamente Number/String para los
         * tipos escalares restantes. El tipo JDBC explícito evita inferencias
         * distintas entre ambientes.
         */
        statement.setObject(
                index,
                value,
                parameter.jdbcType()
        );
    }

    private int jdbcType(String sqlType) {
        String type =
                sqlType == null
                        ? ""
                        : sqlType
                        .trim()
                        .toLowerCase(Locale.ROOT);

        return switch (type) {
            case "bigint" -> Types.BIGINT;
            case "int" -> Types.INTEGER;
            case "smallint" -> Types.SMALLINT;
            case "tinyint" -> Types.TINYINT;
            case "bit" -> Types.BIT;
            case "decimal", "numeric", "money", "smallmoney" ->
                    Types.DECIMAL;
            case "float" -> Types.DOUBLE;
            case "real" -> Types.REAL;
            case "date" -> Types.DATE;
            case "datetime", "datetime2", "smalldatetime" ->
                    Types.TIMESTAMP;
            case "time" -> Types.TIME;
            case "uniqueidentifier" -> Types.VARCHAR;
            case "char" -> Types.CHAR;
            case "nchar" -> Types.NCHAR;
            case "varchar" -> Types.VARCHAR;
            case "nvarchar", "sysname" -> Types.NVARCHAR;
            case "text" -> Types.LONGVARCHAR;
            case "ntext" -> Types.LONGNVARCHAR;
            case "binary" -> Types.BINARY;
            case "varbinary", "timestamp", "rowversion" ->
                    Types.VARBINARY;
            case "xml" -> Types.SQLXML;
            default -> Types.OTHER;
        };
    }

    private String buildCall(
            String procedure,
            int parameterCount
    ) {
        return "{call "
                + bracketProcedure(procedure)
                + "("
                + String.join(
                        ",",
                        java.util.Collections.nCopies(
                                parameterCount,
                                "?"
                        )
                )
                + ")}";
    }

    private String normalizeProcedure(
            String procedure
    ) {
        if (procedure == null
                || !procedure.matches(
                "[A-Za-z_][A-Za-z0-9_]*\\.[A-Za-z_][A-Za-z0-9_]*"
        )) {
            throw new IllegalArgumentException(
                    "Nombre de procedimiento no válido."
            );
        }

        return procedure;
    }

    private String bracketProcedure(
            String procedure
    ) {
        String[] parts =
                procedure.split("\\.", 2);

        return "["
                + parts[0]
                + "].["
                + parts[1]
                + "]";
    }

    private boolean booleanOutput(
            Map<String, Object> outputs,
            String key,
            boolean fallback
    ) {
        Object value =
                findOutput(outputs, key);

        if (value == null) {
            return fallback;
        }

        if (value instanceof Boolean bool) {
            return bool;
        }

        if (value instanceof Number number) {
            return number.intValue() != 0;
        }

        return Boolean.parseBoolean(
                value.toString()
        );
    }

    private Integer integerOutput(
            Map<String, Object> outputs,
            String key,
            Integer fallback
    ) {
        Object value =
                findOutput(outputs, key);

        if (value instanceof Number number) {
            return number.intValue();
        }

        if (value == null) {
            return fallback;
        }

        try {
            return Integer.valueOf(
                    value.toString()
            );
        } catch (NumberFormatException exception) {
            return fallback;
        }
    }

    private String stringOutput(
            Map<String, Object> outputs,
            String key,
            String fallback
    ) {
        Object value =
                findOutput(outputs, key);

        if (value == null
                || value.toString().isBlank()) {
            return fallback;
        }

        return value.toString().trim();
    }

    private Object findOutput(
            Map<String, Object> outputs,
            String key
    ) {
        String normalized =
                normalizeKey(key);

        for (Map.Entry<String, Object> entry
                : outputs.entrySet()) {

            if (normalizeKey(
                    entry.getKey()
            ).equals(normalized)) {
                return entry.getValue();
            }
        }

        return null;
    }

    private String normalizeKey(String value) {
        return value == null
                ? ""
                : value
                .replace("_", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }

    private Throwable rootCause(Throwable value) {
        Throwable current = value;

        while (current.getCause() != null
                && current.getCause() != current) {
            current = current.getCause();
        }

        return current;
    }

    private record ParameterMetadata(
            int parameterId,
            String name,
            String sqlType,
            int jdbcType,
            int maxLength,
            int precision,
            int scale,
            boolean output
    ) {
    }
}
