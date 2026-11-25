IF OBJECT_ID(N'[logistica].[FN_AlmacenProducto_TieneHistorial]') IS NOT NULL
    DROP FUNCTION [logistica].[FN_AlmacenProducto_TieneHistorial];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : logistica.FN_AlmacenProducto_TieneHistorial
' Descripción            : Devuelve el resultado de almacen producto tiene historial.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE FUNCTION logistica.FN_AlmacenProducto_TieneHistorial(@Almacen BIGINT,@Producto BIGINT) RETURNS BIT
AS BEGIN
 IF EXISTS(SELECT 1 FROM logistica.DetalleMovimientoInventario D JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id WHERE M.almacen_id=@Almacen AND D.producto_id=@Producto) RETURN 1;
 IF EXISTS(SELECT 1 FROM logistica.ProgramacionProducto WHERE almacen_id=@Almacen AND producto_id=@Producto) RETURN 1;
 IF EXISTS(SELECT 1 FROM comercial.DetalleVenta D JOIN comercial.Venta V ON V.venta_id=D.venta_id WHERE V.almacen_id=@Almacen AND D.producto_id=@Producto) RETURN 1;
 RETURN 0;
END;
GO
