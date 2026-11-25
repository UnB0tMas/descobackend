package com.franco.desco.adapter.out.persistence.caja;

import com.franco.desco.application.caja.AtencionSemanalRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class SqlServerAtencionSemanalRepository implements AtencionSemanalRepository {
    private static final Logger LOG = LoggerFactory.getLogger(SqlServerAtencionSemanalRepository.class);
    private static final String PA = "comercial.PA_HorarioAtencionPOS_Ejecutar";
    private static final String CALL = "{call " + PA + "(?,?,?,?,?,?,?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    public SqlServerAtencionSemanalRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Override
    public Respuesta ejecutar(String accion, long usuario, long uot, String modo, Integer dia,
                              LocalTime inicio, LocalTime fin, boolean ajustar, String vistaConfirmada) {
        long start = System.nanoTime();
        LOG.info(">> PA INICIO | {} | accion={} | uot={}", PA, accion, uot);
        try {
            var respuesta = jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(CALL);
                statement.setString(1, accion);
                statement.setLong(2, usuario);
                statement.setLong(3, uot);
                statement.setString(4, modo);
                if (dia == null) statement.setNull(5, Types.TINYINT);
                else statement.setInt(5, dia);
                if (inicio == null) statement.setNull(6, Types.TIME);
                else statement.setTime(6, java.sql.Time.valueOf(inicio));
                if (fin == null) statement.setNull(7, Types.TIME);
                else statement.setTime(7, java.sql.Time.valueOf(fin));
                statement.setBoolean(8, ajustar);
                if (vistaConfirmada == null) statement.setNull(9, Types.NVARCHAR);
                else statement.setNString(9, vistaConfirmada);
                statement.registerOutParameter(10, Types.BIT);
                statement.registerOutParameter(11, Types.NVARCHAR);
                statement.registerOutParameter(12, Types.VARCHAR);
                statement.registerOutParameter(13, Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                var afectados = new ArrayList<Afectado>();
                if (statement.execute()) {
                    try (ResultSet rs = statement.getResultSet()) {
                        while (rs.next()) {
                            afectados.add(new Afectado(rs.getLong("horarioId"), rs.getLong("empleadoId"),
                                rs.getString("empleado"), rs.getInt("diaSemana"), rs.getString("horaInicio"),
                                rs.getString("horaFin"), rs.getString("nuevoInicio"), rs.getString("nuevoFin"),
                                rs.getBoolean("quitar")));
                        }
                    }
                }
                return new Respuesta(statement.getBoolean(10), statement.getString(12),
                    statement.getNString(11), statement.getInt(13), List.copyOf(afectados));
            });
            long duration = (System.nanoTime() - start) / 1_000_000;
            if (respuesta.exitoso()) LOG.info(">> PA EXITOSO | {} | accion={} | codigo={} | http={} | duracionMs={}",
                    PA, accion, respuesta.codigo(), respuesta.http(), duration);
            else LOG.warn(">> PA ERROR FUNCIONAL | {} | accion={} | descripcion={} | codigo={} | http={} | duracionMs={}",
                    PA, accion, respuesta.mensaje(), respuesta.codigo(), respuesta.http(), duration);
            return respuesta;
        } catch (RuntimeException ex) {
            LOG.error(">> PA ERROR SQL/TECNICO | {} | accion={} | descripcion={} | codigo=ATENCION_SQL_ERROR | http=503 | duracionMs={}",
                PA, accion, ex.getMessage(), (System.nanoTime()-start)/1_000_000, ex);
            throw ex;
        }
    }
}
