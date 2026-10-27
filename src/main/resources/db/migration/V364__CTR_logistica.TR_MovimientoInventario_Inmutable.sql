IF OBJECT_ID(N'[logistica].[TR_MovimientoInventario_Inmutable]', N'TR') IS NOT NULL
    DROP TRIGGER [logistica].[TR_MovimientoInventario_Inmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : logistica.TR_MovimientoInventario_Inmutable
' Descripción              : Impide modificaciones y eliminaciones de movimientos de inventario.
' Tabla asociada          : logistica.MovimientoInventario
' Evento que lo dispara   : INSTEAD OF UPDATE,DELETE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante INSTEAD OF UPDATE,DELETE sobre logistica.MovimientoInventario.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[logistica].[TR_MovimientoInventario_Inmutable]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_MovimientoInventario_Inmutable
ON logistica.MovimientoInventario INSTEAD OF UPDATE,DELETE
AS
BEGIN
    THROW 51030,N'Los movimientos de inventario son inmutables; registre un movimiento de ajuste o reversa.',1;
END;
GO
