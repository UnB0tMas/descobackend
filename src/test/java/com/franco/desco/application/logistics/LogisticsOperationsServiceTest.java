package com.franco.desco.application.logistics;

import com.franco.desco.application.logistics.LogisticsOperationsService.Policy;
import com.franco.desco.application.logistics.LogisticsOperationsService.ProductOperation;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LogisticsOperationsServiceTest {

    private static final SessionIdentity ACTOR =
            new SessionIdentity(99L, UUID.fromString("11111111-1111-1111-1111-111111111111"), 1, "test");

    @Test
    void writeVoidConservaNombreOrdenYTiposDeParametros() throws SQLException {
        Fixture fixture = fixture();
        when(fixture.statement().getBoolean(6)).thenReturn(true);
        when(fixture.statement().getString(7)).thenReturn("Acción realizada");

        var result = fixture.service().policy(ACTOR, new Policy(3L, 4L, true, false));

        assertThat(result.exitoso()).isTrue();
        assertThat(result.codigo()).isEqualTo("OPERACION_REALIZADA");
        verify(fixture.connection()).prepareCall(
                "{call logistica.PA_ProductoUOT_Upd_Politica(?,?,?,?,?,?,?)}"
        );
        verify(fixture.statement()).setLong(1, 99L);
        verify(fixture.statement()).setLong(2, 3L);
        verify(fixture.statement()).setLong(3, 4L);
        verify(fixture.statement()).setBoolean(4, true);
        verify(fixture.statement()).setBoolean(5, false);
        verify(fixture.statement()).registerOutParameter(6, Types.BIT);
        verify(fixture.statement()).registerOutParameter(7, Types.NVARCHAR);
    }

    @Test
    void writeIdConservaIdentificadorYParametros() throws SQLException {
        Fixture fixture = fixture();
        when(fixture.statement().getObject(7)).thenReturn(42L);
        when(fixture.statement().getBoolean(8)).thenReturn(true);
        when(fixture.statement().getString(9)).thenReturn("Registrado");
        UUID key = UUID.fromString("22222222-2222-2222-2222-222222222222");

        var result = fixture.service().operation(
                ACTOR, 7L, new ProductOperation("ENTREGAR", new BigDecimal("2.50"), "OK"), key
        );

        assertThat(result.exitoso()).isTrue();
        assertThat(result.datos()).isEqualTo(42L);
        verify(fixture.connection()).prepareCall(
                "{call logistica.PA_ProgramacionProducto_Ins_Operacion(?,?,?,?,?,?,?,?,?)}"
        );
        verify(fixture.statement()).setLong(1, 99L);
        verify(fixture.statement()).setLong(2, 7L);
        verify(fixture.statement()).setString(3, "ENTREGAR");
        verify(fixture.statement()).setBigDecimal(4, new BigDecimal("2.50"));
        verify(fixture.statement()).setString(5, "OK");
        verify(fixture.statement()).setString(6, key.toString());
        verify(fixture.statement()).registerOutParameter(7, Types.BIGINT);
    }

    @Test
    void readConservaUnaConsultaSinFilasComoExito() throws SQLException {
        Fixture fixture = fixture();
        when(fixture.statement().getBoolean(3)).thenReturn(true);
        when(fixture.statement().getString(4)).thenReturn("Sin resultados");

        var result = fixture.service().policies(ACTOR, 3L);

        assertThat(result.exitoso()).isTrue();
        assertThat(result.datos()).isEmpty();
        verify(fixture.connection()).prepareCall(
                "{call logistica.PA_ProductoUOT_Sel_Politicas(?,?,?,?)}"
        );
    }

    @Test
    void resultadoFuncionalFallidoSePropagaSinConvertirseEnExito() throws SQLException {
        Fixture fixture = fixture();
        when(fixture.statement().getBoolean(6)).thenReturn(false);
        when(fixture.statement().getString(7)).thenReturn("Acción rechazada");

        var result = fixture.service().policy(ACTOR, new Policy(3L, 4L, true, false));

        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("OPERACION_NO_COMPLETADA");
        assertThat(result.mensaje()).isEqualTo("Acción rechazada");
    }

    @Test
    void writeIdSinIdentificadorNoProduceUnExitoFalso() throws SQLException {
        Fixture fixture = fixture();
        when(fixture.statement().getObject(7)).thenReturn(null);
        when(fixture.statement().getBoolean(8)).thenReturn(true);
        when(fixture.statement().getString(9)).thenReturn("Registrado");

        var result = fixture.service().operation(
                ACTOR, 7L, new ProductOperation("ENTREGAR", BigDecimal.ONE, "OK"), UUID.randomUUID()
        );

        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("OPERACION_NO_COMPLETADA");
    }

    private static Fixture fixture() throws SQLException {
        DataSource dataSource = mock(DataSource.class);
        Connection connection = mock(Connection.class);
        CallableStatement statement = mock(CallableStatement.class);
        when(dataSource.getConnection()).thenReturn(connection);
        when(connection.prepareCall(anyString())).thenReturn(statement);
        when(statement.execute()).thenReturn(false);
        when(statement.getUpdateCount()).thenReturn(-1);
        return new Fixture(
                new LogisticsOperationsService(dataSource, new JsonMapper()),
                connection,
                statement
        );
    }

    private record Fixture(
            LogisticsOperationsService service,
            Connection connection,
            CallableStatement statement
    ) {
    }
}
