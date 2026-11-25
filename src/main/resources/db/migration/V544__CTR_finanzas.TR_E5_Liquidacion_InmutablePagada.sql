IF OBJECT_ID(N'[finanzas].[TR_E5_Liquidacion_InmutablePagada]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Liquidacion_InmutablePagada];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Liquidacion_InmutablePagada
' Descripción            : Protege la integridad de e5 liquidacion inmutable pagada ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_E5_Liquidacion_InmutablePagada
ON finanzas.LiquidacionSocio AFTER UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D
   JOIN finanzas.LiquidacionSnapshotE5 S ON S.liquidacion_socio_id=D.liquidacion_socio_id
   JOIN finanzas.PagoSocio P ON P.liquidacion_socio_id=D.liquidacion_socio_id
    AND P.estado=1 AND P.estado_proceso='CONFIRMADO')
  THROW 51843,N'La liquidación pagada es de consulta y no permite modificaciones.',1;
END;
GO
