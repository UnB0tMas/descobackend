IF OBJECT_ID(N'[finanzas].[TR_E5_Gasto_Cierre]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Gasto_Cierre];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Gasto_Cierre
' Descripción            : Controla las condiciones de cierre de e5 gasto cierre.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_E5_Gasto_Cierre
ON finanzas.GastoCampania AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT campania_venta_id FROM inserted UNION SELECT campania_venta_id FROM deleted) X
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=X.campania_venta_id)
 THROW 51504,N'La campaña cerrada no permite modificar gastos.',1;
END;
GO
