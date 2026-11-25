IF OBJECT_ID(N'[logistica].[TR_DetMov_ProductoActivo]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DetMov_ProductoActivo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DetMov_ProductoActivo
' Descripción            : Controla las modificaciones de det mov producto activo mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DetMov_ProductoActivo ON logistica.DetalleMovimientoInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted D JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id JOIN logistica.AlmacenProductoStock S ON S.almacen_id=M.almacen_id AND S.producto_id=D.producto_id WHERE S.estado=0)
 THROW 51080,N'El producto esta inactivo en este almacen. Reactive su configuracion antes de registrar movimientos.',1;
END;
GO
