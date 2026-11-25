IF OBJECT_ID(N'[finanzas].[TR_E5_Pago_Saldo]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Pago_Saldo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Pago_Saldo
' Descripción            : Controla las modificaciones de e5 pago saldo mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_E5_Pago_Saldo
ON finanzas.PagoSocio AFTER INSERT, UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
   SELECT 1 FROM (SELECT DISTINCT liquidacion_socio_id FROM inserted) I
   JOIN finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK) ON L.liquidacion_socio_id=I.liquidacion_socio_id
   CROSS APPLY(SELECT COALESCE(SUM(P.importe),0) pagado FROM finanzas.PagoSocio P
     WHERE P.liquidacion_socio_id=I.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso='CONFIRMADO') T
   WHERE L.importe_neto<0 OR T.pagado>L.importe_neto
 ) THROW 51501,N'El pago excede el saldo autorizado.',1;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=I.liquidacion_socio_id
  JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
  JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=P.campania_venta_id)
 THROW 51502,N'La campaña cerrada no permite modificar pagos.',1;
END;
GO
