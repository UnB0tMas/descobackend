IF OBJECT_ID(N'[logistica].[FN_Producto_StockDespachable]') IS NOT NULL
    DROP FUNCTION [logistica].[FN_Producto_StockDespachable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : logistica.FN_Producto_StockDespachable
' Descripción            : Devuelve el resultado de producto stock despachable.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE FUNCTION logistica.FN_Producto_StockDespachable(@Almacen BIGINT,@Producto BIGINT)
RETURNS DECIMAL(19,3)
AS
BEGIN
 DECLARE @Fisico DECIMAL(19,3),@Reservado DECIMAL(19,3),@Lotes DECIMAL(19,3),@Trazado BIT;
 SELECT @Fisico=S.stock_disponible,@Reservado=S.stock_reservado,@Trazado=CASE WHEN P.requiere_lote=1 OR P.controla_vencimiento=1 THEN 1 ELSE 0 END
 FROM logistica.AlmacenProductoStock S JOIN logistica.Producto P ON P.producto_id=S.producto_id
 WHERE S.almacen_id=@Almacen AND S.producto_id=@Producto AND S.estado=1 AND P.estado=1;
 IF @Fisico IS NULL RETURN 0;
 IF @Trazado=0 AND NOT EXISTS(SELECT 1 FROM logistica.MovimientoInventarioLote L JOIN logistica.DetalleMovimientoInventario D ON D.detalle_movimiento_inventario_id=L.detalle_movimiento_id
  JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id WHERE D.producto_id=@Producto AND M.almacen_id=@Almacen) RETURN @Fisico;
 SET @Lotes=logistica.FN_ProductoLote_StockVigente(@Almacen,@Producto)-@Reservado;
 RETURN CASE WHEN @Lotes<=0 THEN 0 WHEN @Lotes<@Fisico THEN @Lotes ELSE @Fisico END;
END;
GO
