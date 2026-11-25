package com.franco.desco.adapter.out.persistence.caja;

import com.franco.desco.application.caja.PlantillaHorarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class SqlServerPlantillaHorarioRepository implements PlantillaHorarioRepository {
    private static final Logger LOG = LoggerFactory.getLogger(SqlServerPlantillaHorarioRepository.class);
    private static final String PA = "comercial.PA_TurnoPlantillaPOS_Ejecutar";
    private static final String CALL = "{call " + PA + "(?,?,?,?,?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;

    public SqlServerPlantillaHorarioRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Respuesta ejecutar(String accion, long usuario, long uot, Long plantillaId,
                              String nombre, LocalTime inicio, LocalTime fin) {
        long start = System.nanoTime();
        LOG.info(">> PA INICIO | {} | accion={}", PA, accion);
        try {
            Respuesta respuesta = jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(CALL);
                statement.setString(1, accion);
                statement.setLong(2, usuario);
                statement.setLong(3, uot);
                if (plantillaId == null) statement.setNull(4, Types.BIGINT);
                else statement.setLong(4, plantillaId);
                if (nombre == null) statement.setNull(5, Types.NVARCHAR);
                else statement.setNString(5, nombre);
                if (inicio == null) statement.setNull(6, Types.TIME);
                else statement.setTime(6, java.sql.Time.valueOf(inicio));
                if (fin == null) statement.setNull(7, Types.TIME);
                else statement.setTime(7, java.sql.Time.valueOf(fin));
                statement.registerOutParameter(8, Types.BIT);
                statement.registerOutParameter(9, Types.NVARCHAR);
                statement.registerOutParameter(10, Types.VARCHAR);
                statement.registerOutParameter(11, Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                List<Plantilla> plantillas = new ArrayList<>();
                boolean resultadoSql = statement.execute();
                if (resultadoSql) {
                    try (ResultSet rs = statement.getResultSet()) {
                        while (rs.next()) {
                            plantillas.add(new Plantilla(rs.getLong("plantillaId"), rs.getString("nombre"),
                                    rs.getString("horaInicio"), rs.getString("horaFin")));
                        }
                    }
                }
                return new Respuesta(statement.getBoolean(8), statement.getString(10),
                        statement.getNString(9), statement.getInt(11), List.copyOf(plantillas));
            });
            long ms = (System.nanoTime() - start) / 1_000_000;
            if (respuesta.exitoso())
                LOG.info(">> PA EXITOSO | {} | accion={} | codigo={} | http={} | duracionMs={}",
                        PA, accion, respuesta.codigo(), respuesta.http(), ms);
            else
                LOG.warn(">> PA ERROR FUNCIONAL | {} | accion={} | descripcion={} | codigo={} | http={} | duracionMs={}",
                        PA, accion, respuesta.mensaje(), respuesta.codigo(), respuesta.http(), ms);
            return respuesta;
        } catch (RuntimeException ex) {
            LOG.error(">> PA ERROR SQL/TECNICO | {} | accion={} | descripcion={} | codigo=TURNO_SQL_ERROR | http=503 | duracionMs={}",
                    PA, accion, ex.getMessage(), (System.nanoTime() - start) / 1_000_000, ex);
            throw ex;
        }
    }
}
