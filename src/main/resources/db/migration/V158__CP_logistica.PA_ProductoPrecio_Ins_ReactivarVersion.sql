IF OBJECT_ID(N'[logistica].[PA_ProductoPrecio_Ins_ReactivarVersion]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProductoPrecio_Ins_ReactivarVersion];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProductoPrecio_Ins_ReactivarVersion
' Descripción             : Reactiva una versión del precio de producto.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @nProductoPrecioId BIGINT,
        @nVersionNueva INT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_ProductoPrecio_Ins_ReactivarVersion]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nProductoId = 0,
        @nPrecioOrigenId = 0,
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @nProductoPrecioId = @nProductoPrecioId OUTPUT,
        @nVersionNueva = @nVersionNueva OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nProductoPrecioId, @nVersionNueva, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProductoPrecio_Ins_ReactivarVersion
    @nUsuarioId BIGINT,@nUotId BIGINT,@nProductoId BIGINT,@nPrecioOrigenId BIGINT,@gClaveIdempotencia UNIQUEIDENTIFIER,
    @nProductoPrecioId BIGINT OUTPUT,@nVersionNueva INT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @nProductoPrecioId=NULL,@nVersionNueva=NULL,@bResultado=0,@cMensaje=N'No se pudo reactivar el precio.',@cCodigoRespuesta='PRECIO_NO_REACTIVADO',@nHttpRespuesta=400;
 IF @nUotId IS NULL OR @nProductoId IS NULL OR @nPrecioOrigenId IS NULL OR @gClaveIdempotencia IS NULL BEGIN SET @cMensaje=N'Complete correctamente los datos del precio.'; RETURN 1; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_PRECIO')=0 OR seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_PRECIO_HISTORIAL')=0 BEGIN SET @cMensaje=N'No tiene permiso para reactivar precios históricos.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
 SELECT @nProductoPrecioId=producto_precio_id,@nVersionNueva=version FROM logistica.ProductoPrecio WHERE clave_idempotencia=@gClaveIdempotencia;
 IF @nProductoPrecioId IS NOT NULL BEGIN SELECT @bResultado=1,@cMensaje=N'El precio ya fue reactivado.',@cCodigoRespuesta='PRECIO_REACTIVADO',@nHttpRespuesta=200; RETURN 0; END;
 DECLARE @nPrecioInicial DECIMAL(19,4),@nPrecioVenta DECIMAL(19,4),@cMoneda CHAR(3),@bOrigenVigente BIT;
 SELECT @nPrecioInicial=precio_inicial,@nPrecioVenta=precio_venta,@cMoneda=moneda,@bOrigenVigente=CONVERT(BIT,CASE WHEN estado=1 AND fecha_hasta IS NULL THEN 1 ELSE 0 END)
 FROM logistica.ProductoPrecio WHERE producto_precio_id=@nPrecioOrigenId AND producto_id=@nProductoId AND uot_id=@nUotId;
 IF @nPrecioVenta IS NULL BEGIN SET @cMensaje=N'La versión de precio seleccionada no está disponible.'; SET @cCodigoRespuesta='PRECIO_ORIGEN_NO_DISPONIBLE'; SET @nHttpRespuesta=404; RETURN 1; END;
 IF @bOrigenVigente=1 BEGIN SET @cMensaje=N'La versión seleccionada ya es el precio vigente.'; SET @cCodigoRespuesta='PRECIO_YA_VIGENTE'; SET @nHttpRespuesta=409; RETURN 1; END;
 BEGIN TRY
   BEGIN TRAN;
   UPDATE logistica.ProductoPrecio SET estado=0,fecha_hasta=COALESCE(fecha_hasta,SYSUTCDATETIME()) WHERE producto_id=@nProductoId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL;
   SELECT @nVersionNueva=ISNULL(MAX(version),0)+1 FROM logistica.ProductoPrecio WITH(UPDLOCK,HOLDLOCK) WHERE producto_id=@nProductoId AND uot_id=@nUotId;
   INSERT logistica.ProductoPrecio(producto_id,uot_id,precio_inicial,precio_venta,moneda,version,fecha_desde,fecha_hasta,estado,usuario_id,producto_precio_origen_id,clave_idempotencia)
   VALUES(@nProductoId,@nUotId,@nPrecioInicial,@nPrecioVenta,@cMoneda,@nVersionNueva,SYSUTCDATETIME(),NULL,1,@nUsuarioId,@nPrecioOrigenId,@gClaveIdempotencia);
   SET @nProductoPrecioId=SCOPE_IDENTITY();
   COMMIT;
   SELECT @bResultado=1,@cMensaje=N'Precio reactivado como nueva versión vigente.',@cCodigoRespuesta='PRECIO_REACTIVADO',@nHttpRespuesta=201; RETURN 0;
 END TRY BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK;
   SET @nProductoPrecioId=NULL; SET @nVersionNueva=NULL; SET @cMensaje=N'No se pudo reactivar el precio.'; RETURN 1;
 END CATCH;
END;
GO
