package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class GpFotoRepository {
    private final JdbcTemplate jdbc;
    private final GpRepository gestionProductiva;

    public GpFotoRepository(JdbcTemplate jdbc, GpRepository gestionProductiva) {
        this.jdbc = jdbc;
        this.gestionProductiva = gestionProductiva;
    }

    public Long registrar(SessionIdentity s, long uot, long evento, String archivo, String mime, long bytes) {
        // El evento y su predio deben pertenecer a la UOT solicitada.
        // Se reutiliza la misma validación de visita y administrador que registra el seguimiento.
        gestionProductiva.verificarVisita(s, uot, gestionProductiva.predioEvento(uot, evento));
        // El PA valida además sesión, permisos, UOT y autor original del evento.
        return PaTrace.call("prod.PA_GP_Foto_Ins_Registro", () -> jdbc.queryForObject(
                "EXEC prod.PA_GP_Foto_Ins_Registro ?,?,?,?,?,?,?", Long.class,
                s.sesionPublicaId(), s.usuarioId(), uot, evento, archivo, mime, bytes));
    }

    public FotoArchivo obtener(SessionIdentity s, long uot, long foto) {
        var resultados = PaTrace.call("prod.PA_GP_Foto_Sel_Archivo", () -> jdbc.query(
                "EXEC prod.PA_GP_Foto_Sel_Archivo ?,?,?,?",
                (rs, i) -> new FotoArchivo(rs.getString("archivoInterno"), rs.getString("mimeType")),
                s.sesionPublicaId(), s.usuarioId(), uot, foto));
        return resultados.isEmpty() ? null : resultados.getFirst();
    }

    public record FotoArchivo(String nombre, String mime) {}
}
