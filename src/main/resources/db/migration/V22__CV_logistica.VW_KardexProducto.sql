IF OBJECT_ID(N'[logistica].[VW_KardexProducto]') IS NOT NULL
    DROP VIEW [logistica].[VW_KardexProducto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Vista         : logistica.VW_KardexProducto
' Descripción            : Expone movimientos del kardex de productos.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE VIEW logistica.VW_KardexProducto
AS
SELECT M.movimiento_inventario_id,M.almacen_id,M.uot_id,M.tipo_movimiento,M.naturaleza,M.fecha_hora,M.usuario_id,
       D.detalle_movimiento_inventario_id,D.producto_id,D.cantidad,D.costo_unitario,D.moneda,D.lote,D.fecha_vencimiento,
       CASE WHEN M.naturaleza='E' THEN D.cantidad ELSE -D.cantidad END cantidad_firmada,
       M.documento_referencia,M.observacion,M.estado
FROM logistica.MovimientoInventario M
JOIN logistica.DetalleMovimientoInventario D ON D.movimiento_inventario_id=M.movimiento_inventario_id;
GO
