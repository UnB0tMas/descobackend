IF OBJECT_ID(N'[logistica].[PA_ProductoUOT_Upd_Politica]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProductoUOT_Upd_Politica];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProductoUOT_Upd_Politica
' Descripción             : Configura venta y uso interno de un producto del catálogo por UOT.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de política de productos UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_ProductoUOT_Upd_Politica]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nProductoId = 0,
        @bPermiteVenta = 0,
        @bPermiteUsoInterno = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProductoUOT_Upd_Politica
 @nUsuarioId BIGINT,@nUotId BIGINT,@nProductoId BIGINT,
 @bPermiteVenta BIT,@bPermiteUsoInterno BIT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar la disponibilidad del producto.';
 IF @bPermiteVenta IS NULL OR @bPermiteUsoInterno IS NULL
 BEGIN SET @cMensaje=N'Indique la configuración de venta y uso interno.';RETURN;END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'ALMACENES_MOVIMIENTO')=0
 BEGIN SET @cMensaje=N'No tiene permiso para configurar productos en esta UOT.';RETURN;END;
 IF @bPermiteVenta=1 AND NOT EXISTS (SELECT 1 FROM logistica.Producto WHERE producto_id=@nProductoId AND estado=1 AND permite_venta=1)
 BEGIN SET @cMensaje=N'El catálogo define este producto como exclusivamente operativo.';RETURN;END;
 IF @bPermiteVenta=1 AND NOT EXISTS(SELECT 1 FROM logistica.ProductoPrecio WHERE producto_id=@nProductoId
  AND (uot_id=@nUotId OR uot_id IS NULL) AND estado=1 AND fecha_hasta IS NULL)
 BEGIN SET @cMensaje=N'Configure un precio vigente antes de habilitar la venta.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotId AND estado=1)
 OR NOT EXISTS(SELECT 1 FROM logistica.Producto WHERE producto_id=@nProductoId AND estado=1)
 BEGIN SET @cMensaje=N'La UOT o el producto no están disponibles.';RETURN;END;
 BEGIN TRY
  BEGIN TRAN;
  UPDATE logistica.ProductoUOTPolitica WITH(UPDLOCK,SERIALIZABLE)
  SET permite_venta=@bPermiteVenta,permite_uso_interno=@bPermiteUsoInterno,estado=1,
      usuario_actualizacion_id=@nUsuarioId,fecha_actualizacion=SYSUTCDATETIME()
  WHERE uot_id=@nUotId AND producto_id=@nProductoId;
  IF @@ROWCOUNT=0
   INSERT logistica.ProductoUOTPolitica(uot_id,producto_id,permite_venta,permite_uso_interno,estado,usuario_actualizacion_id)
   VALUES(@nUotId,@nProductoId,@bPermiteVenta,@bPermiteUsoInterno,1,@nUsuarioId);
  COMMIT;SET @bResultado=1;SET @cMensaje=N'Configuración del producto guardada correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  SET @cMensaje=N'No se pudo guardar la configuración del producto.';
 END CATCH;
END;
GO
