package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Repository;

@Repository
public class GpFotoRepository {
    private final JdbcTemplate jdbc;
    public GpFotoRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }
    public Long registrar(SessionIdentity s, long uot, long evento, String archivo, String mime, long bytes) {
        Boolean permitido=jdbc.queryForObject("""
            SELECT CONVERT(BIT,CASE WHEN EXISTS (
              SELECT 1 FROM prod.GPEvento E JOIN prod.GPActividad A ON A.actividad_id=E.actividad_id
              JOIN campo.SalidaDestinoE2 D ON D.predio_id=A.predio_id
              JOIN campo.SalidaE2 S ON S.salida_campo_id=D.salida_campo_id
              JOIN campo.SalidaVisitaE2 X ON X.destino_id=D.destino_id
              JOIN campo.VisitaTecnica V ON V.visita_tecnica_id=X.visita_tecnica_id
              JOIN campo.SalidaParticipante P ON P.salida_campo_id=S.salida_campo_id AND P.estado=1
              JOIN seg.Usuario U ON U.persona_id=P.empleado_id AND U.estado=1
              WHERE E.evento_id=? AND A.uot_id=? AND S.uot_id=? AND U.usuario_id=?
                AND S.estado='EN_EJECUCION' AND V.estado_proceso='INICIADA'
            ) THEN 1 ELSE 0 END)
            """,Boolean.class,evento,uot,uot,s.usuarioId());
        if(!Boolean.TRUE.equals(permitido))
            throw new AccessDeniedException("La fotografía requiere una visita activa al predio.");
        return jdbc.queryForObject("EXEC prod.PA_GP_Foto_Ins_Registro ?,?,?,?,?,?,?", Long.class,
                s.sesionPublicaId(), s.usuarioId(), uot, evento, archivo, mime, bytes);
    }
    public FotoArchivo obtener(SessionIdentity s, long uot, long foto) {
        var resultados = jdbc.query("EXEC prod.PA_GP_Foto_Sel_Archivo ?,?,?,?",
                (rs, i) -> new FotoArchivo(rs.getString("archivoInterno"), rs.getString("mimeType")),
                s.sesionPublicaId(), s.usuarioId(), uot, foto);
        return resultados.isEmpty() ? null : resultados.getFirst();
    }
    public record FotoArchivo(String nombre, String mime) {}
}
