IF OBJECT_ID(N'[finanzas].[TR_E5_Gasto_VersionCongelada]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Gasto_VersionCongelada];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Gasto_VersionCongelada
' Descripción            : Controla las modificaciones de e5 gasto version congelada mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_E5_Gasto_VersionCongelada
ON finanzas.GastoCampania AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.gasto_campania_id=I.gasto_campania_id
   WHERE EXISTS(SELECT 1 FROM finanzas.GastoRepartoVersionE5 V
                 WHERE V.gasto_campania_id=I.gasto_campania_id AND V.estado='APROBADO')
      AND (I.importe<>D.importe OR I.moneda<>D.moneda OR I.campania_venta_id<>D.campania_venta_id))
 THROW 51511,N'El gasto con reparto aprobado conserva importe y moneda históricos.',1;
END;
GO
