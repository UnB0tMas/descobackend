IF OBJECT_ID(N'[finanzas].[PA_E5_Campania_CierreAutomatico]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_E5_Campania_CierreAutomatico];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_E5_Campania_CierreAutomatico
' Descripción            : Ejecuta el proceso de e5 campania cierre automatico.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE finanzas.PA_E5_Campania_CierreAutomatico
 @campaniaId BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 -- Vencimiento comercial independiente del procesamiento financiero.
 UPDATE comercial.CampaniaVenta
 SET estado_proceso='VENCIDA'
 WHERE campania_venta_id=@campaniaId AND estado=1 AND estado_proceso='ACTIVA' AND fecha_fin<@hoy;
 IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WITH(UPDLOCK,HOLDLOCK)
    WHERE campania_venta_id=@campaniaId AND estado=1 AND estado_proceso='VENCIDA' AND fecha_fin<@hoy) RETURN;
 IF EXISTS(SELECT 1 FROM comercial.CierreCampaniaE5 WHERE campania_venta_id=@campaniaId) RETURN;
 IF EXISTS(SELECT 1 FROM comercial.CampaniaJabaPlan J JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@campaniaId AND P.estado=1 AND J.activo=1 AND J.recepcion_confirmada=0) RETURN;
 IF EXISTS(SELECT 1 FROM comercial.CampaniaJabaPlan J
   JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
   JOIN comercial.CampaniaJabaRecepcion R ON R.campania_jaba_plan_id=J.campania_jaba_plan_id AND R.peso_neto_kg>0
   LEFT JOIN comercial.CampaniaJabaPrecioSancion X ON X.campania_jaba_recepcion_id=R.campania_jaba_recepcion_id
   WHERE P.campania_venta_id=@campaniaId AND J.activo=1 AND P.estado=1 AND X.campania_jaba_recepcion_id IS NULL) RETURN;
 IF EXISTS(SELECT 1 FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@campaniaId AND G.estado=1 AND G.estado_proceso<>'APROBADO') RETURN;
 IF EXISTS(SELECT 1 FROM finanzas.CobroComprador B WHERE B.campania_venta_id=@campaniaId AND B.estado=1 AND B.estado_proceso NOT IN('CONFIRMADO','ANULADO')) RETURN;
 IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1
    WHERE O.campania_venta_id=@campaniaId AND E.estado_proceso<>'CONFIRMADA') RETURN;
 IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
    WHERE O.campania_venta_id=@campaniaId AND NOT EXISTS(SELECT 1 FROM comercial.JabaRetornoValidadoE4 V WHERE V.jaba_asignacion_id=A.jaba_asignacion_id)) RETURN;
 -- Todos los socios vendedores deben tener liquidación aprobada y saldo pagado o regularizado.
 IF EXISTS(
    SELECT 1 FROM comercial.ParticipacionCampaniaSocio P
    WHERE P.campania_venta_id=@campaniaId AND P.estado=1
      AND EXISTS(SELECT 1 FROM finanzas.V_E5_VentasConfirmadas V
        WHERE V.participacionId=P.participacion_campania_socio_id AND V.kilogramos>0)
      AND NOT EXISTS(
        SELECT 1 FROM (
          SELECT TOP(1) L.liquidacion_socio_id,L.importe_neto,L.estado_proceso
          FROM finanzas.LiquidacionSocio L
          WHERE L.participacion_campania_socio_id=P.participacion_campania_socio_id AND L.estado=1 AND L.estado_proceso<>'ANULADA'
          ORDER BY L.version DESC
        ) Ult
        OUTER APPLY (SELECT COALESCE(SUM(PG.importe),0) importe
          FROM finanzas.PagoSocio PG WHERE PG.liquidacion_socio_id=Ult.liquidacion_socio_id AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') Q
        WHERE Ult.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA') AND Ult.importe_neto>=0
          AND ROUND(Ult.importe_neto-Q.importe,2)=0
      )
 ) RETURN;
 -- Deben estar conciliados también los importes por cobrar al comprador.
 DECLARE @venta DECIMAL(19,4),@cobrado DECIMAL(19,4);
 SELECT @venta=COALESCE(SUM(D.importe),0)
 FROM finanzas.V_E5_VentasConfirmadas D WHERE D.campaniaId=@campaniaId;
 SELECT @cobrado=COALESCE(SUM(B.importe),0) FROM finanzas.CobroComprador B
 WHERE B.campania_venta_id=@campaniaId AND B.estado=1 AND B.estado_proceso='CONFIRMADO';
 IF @cobrado<@venta RETURN;
 DECLARE @balance NVARCHAR(MAX)=(SELECT @campaniaId campaniaId,SYSUTCDATETIME() fecha,
   @venta ventaEfectiva,@cobrado cobros,
   (SELECT COALESCE(SUM(G.importe),0) FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@campaniaId AND G.estado=1 AND G.estado_proceso='APROBADO') gastos,
   (SELECT COALESCE(SUM(L.importe_neto),0) FROM finanzas.LiquidacionSocio L
     JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
     WHERE P.campania_venta_id=@campaniaId AND L.estado=1 AND L.estado_proceso='APROBADA') netoAprobado
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 UPDATE comercial.CampaniaVenta SET estado_proceso='CERRADA'
 WHERE campania_venta_id=@campaniaId AND estado=1 AND estado_proceso='VENCIDA';
 IF @@ROWCOUNT<>1 RETURN;
 INSERT comercial.CierreCampaniaE5(campania_venta_id,usuario_id,observacion,excepcion_autorizada,balance_final)
 VALUES(@campaniaId,NULL,N'Cierre automático por vencimiento y obligaciones financieras concluidas.',0,@balance);
END;
GO
