package com.franco.desco.adapter.out.sqlserver.shared;

import org.springframework.jdbc.core.ColumnMapRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;

@Component
public class SqlServerPaFactory {

    private final DataSource dataSource;

    public SqlServerPaFactory(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public SimpleJdbcCall call(
            String schema,
            String procedure
    ) {
        return new SimpleJdbcCall(dataSource)
                .withSchemaName(schema)
                .withProcedureName(procedure);
    }

    public SimpleJdbcCall callWithResultSets(
            String schema,
            String procedure,
            String... resultSetNames
    ) {
        SimpleJdbcCall call = call(schema, procedure);

        if (resultSetNames == null) {
            return call;
        }

        for (String resultSetName : resultSetNames) {
            if (resultSetName == null || resultSetName.isBlank()) {
                continue;
            }

            call.returningResultSet(
                    resultSetName,
                    new ColumnMapRowMapper()
            );
        }

        return call;
    }
}
