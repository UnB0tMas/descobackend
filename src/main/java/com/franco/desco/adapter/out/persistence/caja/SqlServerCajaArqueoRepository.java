package com.franco.desco.adapter.out.persistence.caja;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.caja.CajaArqueoRepository;
import com.franco.desco.application.shared.PersistenceResult;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Types;

@Repository
public class SqlServerCajaArqueoRepository implements CajaArqueoRepository {
    private static final String PA = "comercial.PA_CajaSesion_EjecutarArqueo";
    private static final String CALL = "{call " + PA + "(?,?,?,?,?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;

    public SqlServerCajaArqueoRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public CajaArqueoResult ejecutar(String accion, long usuarioId, long uotId, long sesionId,
                                     BigDecimal declarado, String observacion) {
        PersistenceResult<String> resultado = PaTrace.call(PA, accion, () -> jdbc.execute(con -> {
            CallableStatement call = con.prepareCall(CALL);
            call.setString(1, accion);
            call.setLong(2, usuarioId);
            call.setLong(3, uotId);
            call.setLong(4, sesionId);
            if (declarado == null) call.setNull(5, Types.DECIMAL);
            else call.setBigDecimal(5, declarado);
            if (observacion == null) call.setNull(6, Types.NVARCHAR);
            else call.setNString(6, observacion);
            call.registerOutParameter(7, Types.LONGNVARCHAR);
            call.registerOutParameter(8, Types.BIT);
            call.registerOutParameter(9, Types.NVARCHAR);
            call.registerOutParameter(10, Types.VARCHAR);
            call.registerOutParameter(11, Types.SMALLINT);
            return call;
        }, (CallableStatement call) -> {
            call.execute();
            boolean exitoso = call.getBoolean(8);
            String codigo = call.getString(10);
            String mensaje = call.getNString(9);
            int http = call.getInt(11);
            if (!exitoso) {
                return PersistenceResult.<String>error(codigo, mensaje, http == 0 ? 409 : http);
            }
            return PersistenceResult.ok(codigo, mensaje, http == 0 ? 200 : http, call.getNString(7));
        }));
        return new CajaArqueoResult(resultado.exitoso(), resultado.codigo(), resultado.mensaje(),
                resultado.httpSugerido(), resultado.datos());
    }
}
