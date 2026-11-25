IF OBJECT_ID(N'[logistica].[FN_ProductoLote_StockVigente]') IS NOT NULL
    DROP FUNCTION [logistica].[FN_ProductoLote_StockVigente];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : logistica.FN_ProductoLote_StockVigente
' Descripción            : Devuelve el resultado de producto lote stock vigente.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE FUNCTION logistica.FN_ProductoLote_StockVigente(@Almacen BIGINT,@Producto BIGINT)
RETURNS DECIMAL(19,3)
AS
BEGIN
 DECLARE @Stock DECIMAL(19,3);
 SELECT @Stock=COALESCE(SUM(CASE WHEN M.naturaleza='E' THEN L.cantidad ELSE -L.cantidad END),0)
 FROM logistica.MovimientoInventarioLote L JOIN logistica.DetalleMovimientoInventario D ON D.detalle_movimiento_inventario_id=L.detalle_movimiento_id
 JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id
 WHERE M.almacen_id=@Almacen AND D.producto_id=@Producto AND M.estado=1
  AND (L.fecha_vencimiento IS NULL OR L.fecha_vencimiento>=CONVERT(DATE,SYSDATETIME()));
 RETURN CASE WHEN @Stock>0 THEN @Stock ELSE 0 END;
END;
GO
