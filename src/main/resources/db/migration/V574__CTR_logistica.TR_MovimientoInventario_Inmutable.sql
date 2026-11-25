IF OBJECT_ID(N'[logistica].[TR_MovimientoInventario_Inmutable]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_MovimientoInventario_Inmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_MovimientoInventario_Inmutable
' Descripción            : Impide modificaciones y eliminaciones de movimientos de inventario.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_MovimientoInventario_Inmutable
ON logistica.MovimientoInventario INSTEAD OF UPDATE,DELETE
AS
BEGIN
    THROW 51030,N'Los movimientos de inventario son inmutables; registre un movimiento de ajuste o reversa.',1;
END;
GO
