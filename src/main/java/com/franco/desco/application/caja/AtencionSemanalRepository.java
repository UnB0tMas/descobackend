package com.franco.desco.application.caja;

import java.time.LocalTime;
import java.util.List;

public interface AtencionSemanalRepository {
    record Afectado(long horarioId, long empleadoId, String empleado, int diaSemana,
                    String horaInicio, String horaFin, String nuevoInicio, String nuevoFin, boolean quitar) {}
    record Respuesta(boolean exitoso, String codigo, String mensaje, int http, List<Afectado> afectados) {}
    Respuesta ejecutar(String accion, long usuario, long uot, String modo, Integer dia,
                       LocalTime inicio, LocalTime fin, boolean ajustar, String vistaConfirmada);
}
