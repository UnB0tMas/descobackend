IF OBJECT_ID(N'[finanzas].[TR_E5_PagoSocio_ValidaCaja]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_PagoSocio_ValidaCaja];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_PagoSocio_ValidaCaja
' Descripción            : Controla las modificaciones de e5 pago socio valida caja mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_E5_PagoSocio_ValidaCaja
ON finanzas.PagoSocio
AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM (
   SELECT DISTINCT S.campania_venta_id
   FROM inserted I JOIN finanzas.LiquidacionSnapshotE5 S
    ON S.liquidacion_socio_id=I.liquidacion_socio_id
  ) Camp
  WHERE
   COALESCE((SELECT SUM(P.importe)
     FROM finanzas.PagoSocio P JOIN finanzas.LiquidacionSnapshotE5 S
      ON S.liquidacion_socio_id=P.liquidacion_socio_id
     WHERE S.campania_venta_id=Camp.campania_venta_id
      AND P.estado=1 AND P.estado_proceso='CONFIRMADO'),0)
   +COALESCE((SELECT SUM(G.importe)
     FROM finanzas.GastoCampania G
     WHERE G.campania_venta_id=Camp.campania_venta_id
      AND G.estado=1 AND G.estado_proceso='APROBADO'),0)
   >COALESCE((SELECT SUM(B.importe)
     FROM finanzas.CobroComprador B
     WHERE B.campania_venta_id=Camp.campania_venta_id
      AND B.estado=1 AND B.estado_proceso='CONFIRMADO'),0)
 )
 THROW 51744,N'Fondos insuficientes: los cobros confirmados no cubren los pagos y gastos aprobados.',1;
END;
GO
