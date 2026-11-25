package com.franco.desco.adapter.out.persistence.productive;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.productive.port.out.GpProductorPersistencePort;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.productive.GpProductorModels;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.UUID;

@Repository
public class GpProductorRepository implements GpProductorPersistencePort {
    private final JdbcTemplate jdbc;

    public GpProductorRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static Long nullableLong(ResultSet result, String column) throws SQLException {
        long value = result.getLong(column);
        return result.wasNull() ? null : value;
    }

    @Override
    public List<GpProductorModels.Productor> listar(SessionIdentity user, long uotId, String buscar) {
        return PaTrace.call("prod.PA_GP_Productor_Sel_Listado", "LISTAR", () -> jdbc.query(
            "EXEC prod.PA_GP_Productor_Sel_Listado ?,?,?,?", (rs, row) -> new GpProductorModels.Productor(
                rs.getLong("personaId"), rs.getString("tipoDocumento"), rs.getString("numeroDocumento"),
                rs.getString("nombres"), rs.getString("apellidoPaterno"), rs.getString("apellidoMaterno"),
                rs.getString("nombreCompleto"), rs.getString("telefono"), rs.getString("correo"),
                rs.getDate("fechaNacimiento") == null ? null : rs.getDate("fechaNacimiento").toLocalDate(),
                rs.getString("distritoCodigo"), nullableLong(rs, "centroPobladoId"), rs.getString("referencia")),
            user.sesionPublicaId(), user.usuarioId(), uotId, buscar));
    }

    @Override
    public List<GpProductorModels.Parcela> parcelas(SessionIdentity user, long uotId, long personaId) {
        return PaTrace.call("prod.PA_GP_ProductorParcela_Sel_Listado", "LISTAR", () -> jdbc.query(
            "EXEC prod.PA_GP_ProductorParcela_Sel_Listado ?,?,?,?", (rs, row) -> new GpProductorModels.Parcela(
                rs.getLong("parcelaId"), rs.getLong("predioId"), rs.getString("codigo"),
                rs.getString("nombre"), rs.getBigDecimal("areaHa"), rs.getBoolean("estado"),
                rs.getString("distritoCodigo"), nullableLong(rs, "centroPobladoId"),
                rs.getBigDecimal("latitud"), rs.getBigDecimal("longitud"),
                rs.getString("referencia"), rs.getString("observacion")),
            user.sesionPublicaId(), user.usuarioId(), uotId, personaId));
    }

    @Override
    public long crearParcela(SessionIdentity user, long uotId, long personaId,
                             GpProductorModels.FichaParcela ficha, UUID solicitud) {
        Long id = PaTrace.call("prod.PA_GP_ProductorParcela_Ins_Registro", "CREAR", () -> jdbc.queryForObject(
            "EXEC prod.PA_GP_ProductorParcela_Ins_Registro " +
                "@Sesion=?,@Usuario=?,@Uot=?,@Persona=?,@Nombre=?,@Area=?,@Distrito=?," +
                "@Centro=?,@Lat=?,@Lon=?,@Solicitud=?,@Referencia=?,@Observacion=?", Long.class,
            user.sesionPublicaId(), user.usuarioId(), uotId, personaId,
            ficha.nombre(), ficha.areaHa(), ficha.distritoCodigo(), ficha.centroPobladoId(),
            ficha.latitud(), ficha.longitud(), solicitud, ficha.referencia(), ficha.observacion()));
        return id == null ? 0L : id;
    }

    @Override
    public long editar(SessionIdentity user, long uotId, long personaId,
                       GpProductorModels.FichaPersona ficha, UUID solicitud) {
        Long id = PaTrace.call("prod.PA_GP_Productor_Upd_Datos", "EDITAR", () -> jdbc.queryForObject(
            "EXEC prod.PA_GP_Productor_Upd_Datos " +
                "@Sesion=?,@Usuario=?,@Uot=?,@Persona=?,@Nombres=?,@Paterno=?,@Materno=?," +
                "@Telefono=?,@Correo=?,@Distrito=?,@Centro=?,@Referencia=?,@Solicitud=?", Long.class,
            user.sesionPublicaId(), user.usuarioId(), uotId, personaId,
            ficha.nombres(), ficha.apellidoPaterno(), ficha.apellidoMaterno(),
            ficha.telefono(), ficha.correo(), ficha.distritoCodigo(),
            ficha.centroPobladoId(), ficha.referencia(), solicitud));
        return id == null ? 0L : id;
    }

    @Override
    public long desactivar(SessionIdentity user, long uotId, long personaId, String motivo, UUID solicitud) {
        Long id = PaTrace.call("prod.PA_GP_Productor_Upd_Estado", "RETIRAR", () -> jdbc.queryForObject(
            "EXEC prod.PA_GP_Productor_Upd_Estado ?,?,?,?,?,?", Long.class,
            user.sesionPublicaId(), user.usuarioId(), uotId, personaId, motivo, solicitud));
        return id == null ? 0L : id;
    }
}
