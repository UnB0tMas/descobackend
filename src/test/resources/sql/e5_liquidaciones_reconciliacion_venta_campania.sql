-- QA solo lectura: reconciliación de producción / venta y liquidación.
-- Indicar la campaña que se revisará (o NULL para tomar una con jabas registradas).
DECLARE @campaniaId BIGINT=NULL;
IF @campaniaId IS NULL
 SELECT TOP(1) @campaniaId=P.campania_venta_id
 FROM comercial.ParticipacionCampaniaSocio P
 JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
 JOIN comercial.CampaniaJabaRecepcion R ON R.campania_jaba_plan_id=J.campania_jaba_plan_id
 WHERE P.estado=1 GROUP BY P.campania_venta_id ORDER BY MAX(R.fecha_registro) DESC;

SELECT @campaniaId campaniaId;
SELECT P.participacion_campania_socio_id participacionId,
 CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socio,
 COALESCE(SUM(CASE WHEN J.recepcion_confirmada=1 THEN R.peso_neto_kg ELSE 0 END),0) kgConfirmadosOrigen,
 COALESCE(SUM(CASE WHEN J.recepcion_confirmada=0 THEN R.peso_neto_kg ELSE 0 END),0) kgPendientesRecepcion,
 COALESCE(SUM(CASE WHEN J.recepcion_confirmada=1 THEN CONVERT(DECIMAL(19,4),R.peso_neto_kg*X.precio_final_kg) ELSE 0 END),0) ventaConfirmadaOrigen,
 (SELECT COALESCE(SUM(F.kilogramos),0) FROM finanzas.V_E5_VentasConfirmadas F WHERE F.participacionId=P.participacion_campania_socio_id) kgFinanzas,
 (SELECT COALESCE(SUM(F.importe),0) FROM finanzas.V_E5_VentasConfirmadas F WHERE F.participacionId=P.participacion_campania_socio_id) ventaFinanzas,
 (SELECT COUNT_BIG(1) FROM comercial.CampaniaJabaPlan JP
   JOIN comercial.CampaniaJabaRecepcion RR ON RR.campania_jaba_plan_id=JP.campania_jaba_plan_id
   LEFT JOIN comercial.CampaniaJabaPrecioSancion XX ON XX.campania_jaba_recepcion_id=RR.campania_jaba_recepcion_id
   WHERE JP.participacion_campania_socio_id=P.participacion_campania_socio_id AND JP.activo=1
    AND RR.peso_neto_kg>0 AND XX.campania_jaba_recepcion_id IS NULL) jabasSinPrecio
FROM comercial.ParticipacionCampaniaSocio P
JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
JOIN org.Socio S ON S.socio_id=SA.socio_id
JOIN org.Persona PE ON PE.persona_id=S.socio_id
LEFT JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
LEFT JOIN comercial.CampaniaJabaRecepcion R ON R.campania_jaba_plan_id=J.campania_jaba_plan_id
LEFT JOIN comercial.CampaniaJabaPrecioSancion X ON X.campania_jaba_recepcion_id=R.campania_jaba_recepcion_id
WHERE P.campania_venta_id=@campaniaId AND P.estado=1
GROUP BY P.participacion_campania_socio_id,PE.nombres,PE.apellido_paterno,PE.apellido_materno
ORDER BY socio;

-- Vigencia y cierre son estados distintos: la liquidación puede continuar tras el vencimiento.
SELECT C.campania_venta_id campaniaId,C.nombre,C.estado_proceso,C.fecha_fin,
 COUNT(DISTINCT L.liquidacion_socio_id) liquidacionesRegistradas
FROM comercial.CampaniaVenta C
LEFT JOIN comercial.ParticipacionCampaniaSocio P ON P.campania_venta_id=C.campania_venta_id AND P.estado=1
LEFT JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=P.participacion_campania_socio_id AND L.estado=1
WHERE C.campania_venta_id=@campaniaId
GROUP BY C.campania_venta_id,C.nombre,C.estado_proceso,C.fecha_fin;
