IF OBJECT_ID(N'[logistica].[PA_AlmacenProducto_Sel_Transferibles]') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_AlmacenProducto_Sel_Transferibles];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : logistica.PA_AlmacenProducto_Sel_Transferibles
' Descripción            : Consulta almacen producto para transferibles.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
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
  logistica.FN_Producto_StockDespachable(S.almacen_id,S.producto_id) stockDisponible,CONVERT(BIT,CASE WHEN R.motivo IS NULL THEN 1 ELSE 0 END) apto,R.motivo
 FROM logistica.AlmacenProductoStock S JOIN logistica.Producto P ON P.producto_id=S.producto_id
 CROSS APPLY(SELECT logistica.FN_AlmacenProducto_MotivoTransferencia(@nUsuarioId,@nAlmacenOrigenId,@nAlmacenDestinoId,S.producto_id) motivo) R
 WHERE S.almacen_id=@nAlmacenOrigenId ORDER BY P.nombre;
 SELECT @bResultado=1,@cMensaje=N'Productos para transferencia consultados.';
END;
GO
