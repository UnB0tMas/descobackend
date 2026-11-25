package com.franco.desco.adapter.out.sqlserver.shared;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;

import javax.sql.DataSource;
import java.util.Map;

/** SimpleJdbcCall compatible con el código existente y trazable por operación. */
public final class LoggedSimpleJdbcCall extends SimpleJdbcCall {
    private final String procedure;

    public LoggedSimpleJdbcCall(DataSource dataSource, String procedure) {
        super(dataSource);
        this.procedure = procedure;
    }

    public LoggedSimpleJdbcCall(JdbcTemplate jdbcTemplate, String procedure) {
        super(jdbcTemplate);
        this.procedure = procedure;
    }

    @Override
    public Map<String, Object> execute(Map<String, ?> args) {
        return PaTrace.call(procedure, () -> super.execute(args));
    }

    @Override
    public Map<String, Object> execute(SqlParameterSource args) {
        return PaTrace.call(procedure, () -> super.execute(args));
    }

    @Override
    public Map<String, Object> execute(Object... args) {
        return PaTrace.call(procedure, () -> super.execute(args));
    }
}
