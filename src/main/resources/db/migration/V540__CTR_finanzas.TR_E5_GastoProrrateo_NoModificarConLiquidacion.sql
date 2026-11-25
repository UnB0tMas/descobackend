IF OBJECT_ID(N'[finanzas].[TR_E5_GastoProrrateo_NoModificarConLiquidacion]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_GastoProrrateo_NoModificarConLiquidacion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_GastoProrrateo_NoModificarConLiquidacion
' Descripción            : Controla las modificaciones de e5 gasto prorrateo no modificar con liquidacion mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_E5_GastoProrrateo_NoModificarConLiquidacion
ON finanzas.GastoProrrateoSocio AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM (SELECT gasto_campania_id FROM inserted UNION SELECT gasto_campania_id FROM deleted) X
        JOIN finanzas.GastoCampania G ON G.gasto_campania_id=X.gasto_campania_id
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.campania_venta_id=G.campania_venta_id
        JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=PC.participacion_campania_socio_id
        WHERE L.estado=1 AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
    ) THROW 51701,N'El reparto ya forma parte de liquidaciones aprobadas y no puede modificarse.',1;
END;
GO
