-- QA E3 - CONSULTA SIN ESCRITURA: identificar altas repetidas sin borrar históricos.
-- Cambiar el predio solo durante la prueba.
DECLARE @predio BIGINT=10032;
SELECT P.predio_id,P.variedad_palta_id,P.estado_actual,COUNT_BIG(*) cantidad,
       MIN(P.creado_en) primera_alta,MAX(P.creado_en) ultima_alta
FROM prod.PlantaPaltaE3 P WHERE P.predio_id=@predio
GROUP BY P.predio_id,P.variedad_palta_id,P.estado_actual
ORDER BY P.variedad_palta_id,P.estado_actual;
SELECT E.correlacion_id,E.usuario_id,MIN(E.fecha_hecho) fecha_lote,
 COUNT_BIG(*) plantas_asociadas
FROM prod.PlantaEventoE3 E JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id
WHERE P.predio_id=@predio AND E.tipo='ALTA'
GROUP BY E.correlacion_id,E.usuario_id ORDER BY fecha_lote DESC;
-- No eliminar registros duplicados sin análisis y autorización.
