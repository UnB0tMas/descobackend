IF OBJECT_ID(N'[finanzas].[V_E5_VentasConfirmadas]') IS NOT NULL
    DROP VIEW [finanzas].[V_E5_VentasConfirmadas];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Vista         : finanzas.V_E5_VentasConfirmadas
' Descripción            : Expone la información de v e5 ventas confirmadas para consulta.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   VIEW finanzas.V_E5_VentasConfirmadas
AS
SELECT P.campania_venta_id campaniaId,P.participacion_campania_socio_id participacionId,
  CONVERT(VARCHAR(12),'CAMPANIA') origen,R.campania_jaba_recepcion_id partidaId,
  CONVERT(BIGINT,NULL) entrega_detalle_id,J.campania_jaba_plan_id entregaId,
  R.numero_jaba numeroJaba,DATEADD(HOUR,-5,R.fecha_registro) fecha_hora,
  CONVERT(DECIMAL(19,3),R.peso_neto_kg) kilogramos,
  CONVERT(DECIMAL(19,3),R.peso_bruto_kg) pesoBruto,
  CONVERT(DECIMAL(19,3),R.descuento_jaba_kg) tara,
  X.precio_original_kg precio_base,X.precio_final_kg precio_aplicado,
  CONVERT(DECIMAL(19,4),R.peso_neto_kg*X.precio_final_kg) importe,
  G.variedad_palta_id variedad_palta_id,V.nombre variedad,
  G.calibre condicion,G.campania_calibre_id condicion_comercial_id
FROM comercial.ParticipacionCampaniaSocio P
JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id
  AND J.activo=1 AND J.recepcion_confirmada=1
JOIN comercial.CampaniaJabaRecepcion R ON R.campania_jaba_plan_id=J.campania_jaba_plan_id
JOIN comercial.CampaniaJabaPrecioSancion X ON X.campania_jaba_recepcion_id=R.campania_jaba_recepcion_id
JOIN comercial.CampaniaCalibre G ON G.campania_calibre_id=R.campania_calibre_id AND G.campania_venta_id=P.campania_venta_id
JOIN prod.VariedadPalta V ON V.variedad_palta_id=G.variedad_palta_id
WHERE P.estado=1 AND R.peso_neto_kg>0
UNION ALL
SELECT O.campania_venta_id,OS.participacion_campania_socio_id,
 CONVERT(VARCHAR(12),'OPERATIVO'),D.entrega_detalle_id,D.entrega_detalle_id,E.entrega_socio_id,
 CONVERT(INT,NULL),E.fecha_hora,D.kilogramos,E.peso_bruto_kg,E.tara_kg,
 D.precio_base,D.precio_aplicado,D.importe,D.variedad_palta_id,V.nombre,CC.nombre,D.condicion_comercial_id
FROM comercial.EntregaDetalle D
JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id AND OS.estado=1
JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id AND O.estado=1
JOIN prod.VariedadPalta V ON V.variedad_palta_id=D.variedad_palta_id
JOIN comercial.CondicionComercial CC ON CC.condicion_comercial_id=D.condicion_comercial_id
WHERE D.estado=1 AND D.kilogramos>0
 AND NOT EXISTS(SELECT 1 FROM comercial.CampaniaJabaPlan J WHERE J.participacion_campania_socio_id=OS.participacion_campania_socio_id AND J.activo=1);
GO
