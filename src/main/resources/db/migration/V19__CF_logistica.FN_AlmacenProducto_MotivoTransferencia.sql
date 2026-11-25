IF OBJECT_ID(N'[logistica].[FN_AlmacenProducto_MotivoTransferencia]') IS NOT NULL
    DROP FUNCTION [logistica].[FN_AlmacenProducto_MotivoTransferencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : logistica.FN_AlmacenProducto_MotivoTransferencia
' Descripción            : Devuelve el resultado de almacen producto motivo transferencia.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE FUNCTION logistica.FN_AlmacenProducto_MotivoTransferencia
(@Usuario BIGINT,@Origen BIGINT,@Destino BIGINT,@Producto BIGINT)
RETURNS NVARCHAR(300)
AS
BEGIN
 DECLARE @UotOrigen BIGINT,@UotDestino BIGINT;
 SELECT @UotOrigen=uot_propietaria_id FROM logistica.Almacen WHERE almacen_id=@Origen AND estado=1;
 SELECT @UotDestino=uot_propietaria_id FROM logistica.Almacen WHERE almacen_id=@Destino AND estado=1;
 IF @UotOrigen IS NULL OR @UotDestino IS NULL OR @Origen=@Destino
  RETURN N'Seleccione almacenes distintos y activos.';
 IF seg.FN_Usuario_TienePermisoUOT(@Usuario,@UotOrigen,'ALMACENES_MOVIMIENTO')=0
  OR seg.FN_Usuario_TienePermisoUOT(@Usuario,@UotDestino,'ALMACENES_MOVIMIENTO')=0
  RETURN N'Sin autorización para operar ambos almacenes.';
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@Origen AND uot_id=@UotOrigen AND estado=1 AND fecha_hasta IS NULL AND permite_salida=1)
  RETURN N'El almacén origen no permite salidas.';
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@Destino AND uot_id=@UotDestino AND estado=1 AND fecha_hasta IS NULL AND permite_entrada=1)
  RETURN N'El almacén destino no permite entradas.';
 IF NOT EXISTS(SELECT 1 FROM logistica.Producto WHERE producto_id=@Producto AND estado=1)
  RETURN N'Producto inactivo en el catálogo.';
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@Origen AND producto_id=@Producto AND estado=1)
  RETURN N'Producto no incorporado o inactivo en origen.';
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@Destino AND producto_id=@Producto)
  RETURN N'Primero agregue el producto al almacén destino.';
 IF EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@Destino AND producto_id=@Producto AND estado=0)
  RETURN N'Producto inactivo en el almacén destino.';
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@Origen AND producto_id=@Producto AND logistica.FN_Producto_StockDespachable(@Origen,@Producto)>0)
  RETURN N'Sin stock disponible o sin lotes vigentes y trazables en origen.';
 RETURN NULL;
END;
GO
