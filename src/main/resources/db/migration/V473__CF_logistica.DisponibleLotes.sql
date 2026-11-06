IF OBJECT_ID(N'logistica.FN_ProductoLote_StockVigente', N'FN') IS NOT NULL DROP FUNCTION logistica.FN_ProductoLote_StockVigente;
GO
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
IF OBJECT_ID(N'logistica.FN_Producto_StockDespachable', N'FN') IS NOT NULL DROP FUNCTION logistica.FN_Producto_StockDespachable;
GO
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
CREATE OR ALTER VIEW logistica.VW_StockProducto AS
SELECT S.almacen_id,A.codigo almacen_codigo,A.nombre almacen,A.uot_propietaria_id,
 S.producto_id,P.codigo producto_codigo,P.nombre producto,P.unidad_medida,
 S.stock_actual,S.stock_reservado,logistica.FN_Producto_StockDespachable(S.almacen_id,S.producto_id) stock_disponible,
 S.stock_minimo,S.fecha_actualizacion,S.estado,logistica.FN_AlmacenProducto_TieneHistorial(S.almacen_id,S.producto_id) tiene_historial,
 CONVERT(BIT,CASE WHEN S.estado=1 AND logistica.FN_Producto_StockDespachable(S.almacen_id,S.producto_id)<=S.stock_minimo THEN 1 ELSE 0 END) requiere_reposicion
FROM logistica.AlmacenProductoStock S JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id JOIN logistica.Producto P ON P.producto_id=S.producto_id;
GO
IF OBJECT_ID(N'logistica.TR_AlmacenProducto_ReservaTrazable', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_AlmacenProducto_ReservaTrazable;
GO
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
