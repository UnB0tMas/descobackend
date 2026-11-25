IF OBJECT_ID(N'[finanzas].[TR_E5_Liquidacion_ImporteCongelado]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Liquidacion_ImporteCongelado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Liquidacion_ImporteCongelado
' Descripción            : Controla las modificaciones de e5 liquidacion importe congelado mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_E5_Liquidacion_ImporteCongelado
ON finanzas.LiquidacionSocio AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.liquidacion_socio_id=I.liquidacion_socio_id
  JOIN finanzas.LiquidacionSnapshotE5 S ON S.liquidacion_socio_id=I.liquidacion_socio_id
  WHERE S.aprobado IS NOT NULL AND
   (I.importe_neto<>D.importe_neto OR I.importe_bruto<>D.importe_bruto
    OR I.participacion_campania_socio_id<>D.participacion_campania_socio_id OR I.version<>D.version
    OR I.moneda<>D.moneda))
 THROW 51508,N'Una liquidación aprobada conserva importes, versión y moneda inmutables.',1;
END;
GO
