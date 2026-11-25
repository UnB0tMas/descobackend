IF OBJECT_ID(N'[finanzas].[TR_DESCO_Liquidacion_Importe]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_DESCO_Liquidacion_Importe];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_DESCO_Liquidacion_Importe
' Descripción            : Valida importes en liquidaciones de socios.
' Aplicativo / Módulo    : DESCO / Finanzas
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_DESCO_Liquidacion_Importe
ON finanzas.LiquidacionSocio AFTER UPDATE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.liquidacion_socio_id=I.liquidacion_socio_id
 WHERE (I.moneda<>D.moneda OR I.participacion_campania_socio_id<>D.participacion_campania_socio_id
  OR I.estado=0 OR I.estado_proceso NOT IN('APROBADA','PAGADA_PARCIAL','PAGADA'))
 AND EXISTS(SELECT 1 FROM finanzas.PagoSocio P WHERE P.liquidacion_socio_id=I.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso IN('REGISTRADO','CONFIRMADO')))
  THROW 51000,N'La liquidación ya tiene pagos registrados.',1;
 IF EXISTS(SELECT 1 FROM inserted I CROSS APPLY(SELECT SUM(P.importe) total FROM finanzas.PagoSocio P WITH(READCOMMITTEDLOCK)
  WHERE P.liquidacion_socio_id=I.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso IN('REGISTRADO','CONFIRMADO')) P
  WHERE P.total>I.importe_neto) THROW 51100,N'DESCO_PAGO_EXCESO',1;
END;
GO
