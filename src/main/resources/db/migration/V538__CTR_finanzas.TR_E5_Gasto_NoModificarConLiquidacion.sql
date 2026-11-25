IF OBJECT_ID(N'[finanzas].[TR_E5_Gasto_NoModificarConLiquidacion]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Gasto_NoModificarConLiquidacion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Gasto_NoModificarConLiquidacion
' Descripción            : Controla las modificaciones de e5 gasto no modificar con liquidacion mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_E5_Gasto_NoModificarConLiquidacion
ON finanzas.GastoCampania AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM (SELECT campania_venta_id FROM inserted UNION SELECT campania_venta_id FROM deleted) X
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.campania_venta_id=X.campania_venta_id
        JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=PC.participacion_campania_socio_id
        WHERE L.estado=1 AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
    ) THROW 51700,N'Los gastos comunes están congelados porque ya existe una liquidación aprobada.',1;
END;
GO
