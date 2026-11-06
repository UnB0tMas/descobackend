-- Criterio compartido entre consulta y registro de transferencias.
-- Ejemplo: SELECT logistica.FN_AlmacenProducto_MotivoTransferencia(1,1,2,1);
IF OBJECT_ID(N'logistica.FN_AlmacenProducto_MotivoTransferencia',N'FN') IS NOT NULL
 DROP FUNCTION logistica.FN_AlmacenProducto_MotivoTransferencia;
GO
IF OBJECT_ID(N'logistica.FN_AlmacenProducto_MotivoTransferencia', N'FN') IS NOT NULL DROP FUNCTION logistica.FN_AlmacenProducto_MotivoTransferencia;
GO
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
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@Origen AND producto_id=@Producto AND stock_disponible>0)
  RETURN N'Sin stock disponible en origen.';
 RETURN NULL;
END;
GO
IF OBJECT_ID(N'logistica.PA_AlmacenProducto_Sel_Transferibles',N'P') IS NOT NULL
 DROP PROCEDURE logistica.PA_AlmacenProducto_Sel_Transferibles;
GO
-- Ejemplo: EXEC logistica.PA_AlmacenProducto_Sel_Transferibles 1,1,2,@ok OUTPUT,@mensaje OUTPUT;
IF OBJECT_ID(N'logistica.PA_AlmacenProducto_Sel_Transferibles', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_AlmacenProducto_Sel_Transferibles;
GO
CREATE PROCEDURE logistica.PA_AlmacenProducto_Sel_Transferibles
 @nUsuarioId BIGINT,@nAlmacenOrigenId BIGINT,@nAlmacenDestinoId BIGINT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No tiene permiso para consultar el almacén origen.';
 IF NOT EXISTS(SELECT 1 FROM logistica.Almacen A WHERE A.almacen_id=@nAlmacenOrigenId
  AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,A.uot_propietaria_id,'ALMACENES_LISTAR')=1) RETURN;
 SELECT S.producto_id productoId,P.nombre producto,P.unidad_medida unidadMedida,
  S.stock_disponible stockDisponible,CONVERT(BIT,CASE WHEN R.motivo IS NULL THEN 1 ELSE 0 END) apto,R.motivo
 FROM logistica.AlmacenProductoStock S JOIN logistica.Producto P ON P.producto_id=S.producto_id
 CROSS APPLY(SELECT logistica.FN_AlmacenProducto_MotivoTransferencia(@nUsuarioId,@nAlmacenOrigenId,@nAlmacenDestinoId,S.producto_id) motivo) R
 WHERE S.almacen_id=@nAlmacenOrigenId ORDER BY P.nombre;
 SELECT @bResultado=1,@cMensaje=N'Productos para transferencia consultados.';
END;
GO
