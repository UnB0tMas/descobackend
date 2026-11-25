package com.franco.desco.application.caja;

import java.time.LocalTime;
import java.util.List;

/** Puerto de persistencia para turnos reutilizables. */
public interface PlantillaHorarioRepository {
    record Plantilla(Long plantillaId, String nombre, String horaInicio, String horaFin) {}
    record Respuesta(boolean exitoso, String codigo, String mensaje, int http, List<Plantilla> plantillas) {}

    Respuesta ejecutar(String accion, long usuario, long uot, Long plantillaId,
                       String nombre, LocalTime inicio, LocalTime fin);
}
