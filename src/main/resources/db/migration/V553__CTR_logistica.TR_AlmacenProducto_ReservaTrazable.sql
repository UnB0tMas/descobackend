IF OBJECT_ID(N'[logistica].[TR_AlmacenProducto_ReservaTrazable]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_AlmacenProducto_ReservaTrazable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_AlmacenProducto_ReservaTrazable
' Descripción            : Controla las modificaciones de almacen producto reserva trazable mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_AlmacenProducto_ReservaTrazable ON logistica.AlmacenProductoStock AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.almacen_id=I.almacen_id AND D.producto_id=I.producto_id
  JOIN logistica.Producto P ON P.producto_id=I.producto_id
  WHERE I.stock_reservado>D.stock_reservado AND (P.requiere_lote=1 OR P.controla_vencimiento=1 OR EXISTS(
   SELECT 1 FROM logistica.MovimientoInventarioLote L JOIN logistica.DetalleMovimientoInventario X ON X.detalle_movimiento_inventario_id=L.detalle_movimiento_id
   JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=X.movimiento_inventario_id WHERE X.producto_id=I.producto_id AND M.almacen_id=I.almacen_id))
  AND I.stock_reservado>logistica.FN_ProductoLote_StockVigente(I.almacen_id,I.producto_id))
  THROW 51120,N'La reserva supera las existencias de lotes vigentes y trazables.',1;
END;
GO
