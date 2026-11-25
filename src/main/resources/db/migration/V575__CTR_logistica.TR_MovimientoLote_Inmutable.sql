IF OBJECT_ID(N'[logistica].[TR_MovimientoLote_Inmutable]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_MovimientoLote_Inmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_MovimientoLote_Inmutable
' Descripción            : Protege la integridad de movimiento lote inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_MovimientoLote_Inmutable ON logistica.MovimientoInventarioLote AFTER UPDATE,DELETE AS
BEGIN THROW 51120,N'Las asignaciones de lotes son históricas y no se pueden modificar.',1;END;
GO
