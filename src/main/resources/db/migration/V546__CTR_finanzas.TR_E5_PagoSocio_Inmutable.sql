IF OBJECT_ID(N'[finanzas].[TR_E5_PagoSocio_Inmutable]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_PagoSocio_Inmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_PagoSocio_Inmutable
' Descripción            : Protege la integridad de e5 pago socio inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_E5_PagoSocio_Inmutable
ON finanzas.PagoSocio AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D
   WHERE (D.estado=1 AND D.estado_proceso='CONFIRMADO')
      OR EXISTS(SELECT 1 FROM finanzas.PagoBeneficiarioE5 B WHERE B.pago_socio_id=D.pago_socio_id))
  THROW 51840,N'Un pago confirmado es inmutable, incluso si procede de un registro histórico.',1;
 IF EXISTS(SELECT 1 FROM (SELECT liquidacion_socio_id FROM inserted
                          UNION SELECT liquidacion_socio_id FROM deleted) X
   JOIN finanzas.LiquidacionSnapshotE5 S ON S.liquidacion_socio_id=X.liquidacion_socio_id
   JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id
   WHERE C.estado_proceso<>'ACTIVA' OR CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) NOT BETWEEN C.fecha_inicio AND C.fecha_fin)
  THROW 51841,N'Las campañas terminadas son de consulta, no permiten cambios en los pagos.',1;
 IF EXISTS(SELECT 1 FROM inserted I
   JOIN finanzas.LiquidacionSnapshotE5 S ON S.liquidacion_socio_id=I.liquidacion_socio_id
   JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=I.liquidacion_socio_id
   WHERE I.estado=1 AND I.estado_proceso='CONFIRMADO'
   AND (I.importe<>ROUND(L.importe_neto,2)
     OR EXISTS(SELECT 1 FROM finanzas.PagoSocio P WHERE P.liquidacion_socio_id=I.liquidacion_socio_id
       AND P.pago_socio_id<>I.pago_socio_id AND P.estado=1 AND P.estado_proceso='CONFIRMADO')))
  THROW 51842,N'El pago al socio de APAPPSS debe cancelar su liquidación completa una sola vez.',1;
END;
GO
