-- Ejecutar únicamente después de aplicar V437-V440. Consultas de diagnóstico, sin mutaciones.
SET NOCOUNT ON;
SELECT A.jaba_asignacion_id, A.cantidad_asignada,
       COUNT(U.unidad_id) AS unidades_reales
FROM comercial.JabaAsignacion A
JOIN comercial.JabaUnidadE4 U ON U.jaba_asignacion_id=A.jaba_asignacion_id
GROUP BY A.jaba_asignacion_id,A.cantidad_asignada
HAVING COUNT(U.unidad_id)<>A.cantidad_asignada;

SELECT A.jaba_asignacion_id,A.cantidad_devuelta,
       SUM(CASE WHEN U.retorno_estado LIKE 'DEVUELTA%' THEN 1 ELSE 0 END) AS devoluciones_unitarias
FROM comercial.JabaAsignacion A
JOIN comercial.JabaUnidadE4 U ON U.jaba_asignacion_id=A.jaba_asignacion_id
GROUP BY A.jaba_asignacion_id,A.cantidad_devuelta
HAVING A.cantidad_devuelta<>SUM(CASE WHEN U.retorno_estado LIKE 'DEVUELTA%' THEN 1 ELSE 0 END);

SELECT U.unidad_id, U.peso_bruto_kg, U.tara_kg, U.peso_neto_kg
FROM comercial.JabaUnidadE4 U
WHERE U.pesaje_estado='PESADA'
  AND (U.peso_neto_kg<=0 OR U.peso_neto_kg<>U.peso_bruto_kg-U.tara_kg);

SELECT U.unidad_id, U.peso_neto_kg, COALESCE(SUM(C.peso_kg),0) AS clasificado
FROM comercial.JabaUnidadE4 U
LEFT JOIN comercial.JabaClasificacionE4 C ON C.unidad_id=U.unidad_id
WHERE U.pesaje_estado='PESADA'
GROUP BY U.unidad_id,U.peso_neto_kg
HAVING COALESCE(SUM(C.peso_kg),0)<>U.peso_neto_kg;

SELECT E.entrega_socio_id, E.peso_aceptado_kg,
       COALESCE(SUM(CASE WHEN C.rechazada=0 THEN C.peso_kg ELSE 0 END),0) AS peso_unidades
FROM comercial.EntregaSocio E
JOIN comercial.JabaUnidadE4 U ON U.entrega_socio_id=E.entrega_socio_id
JOIN comercial.JabaClasificacionE4 C ON C.unidad_id=U.unidad_id
GROUP BY E.entrega_socio_id,E.peso_aceptado_kg
HAVING E.peso_aceptado_kg<>SUM(CASE WHEN C.rechazada=0 THEN C.peso_kg ELSE 0 END);

SELECT S.sancion_id,S.diferencia,
       S.kilos_afectados*(S.precio_original-S.precio_nuevo) AS descuento_esperado
FROM comercial.SancionSocioE4 S
WHERE S.diferencia<>CONVERT(DECIMAL(19,4),S.kilos_afectados*(S.precio_original-S.precio_nuevo));
