IF OBJECT_ID(N'[logistica].[PA_Producto_Upd_Estado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Producto_Upd_Estado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Producto_Upd_Estado
' Descripción             : Actualiza el estado de producto.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_Producto_Upd_Estado]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nProductoId = 0,
        @bEstado = 0,
        @cMotivo = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_Producto_Upd_Estado
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nProductoId BIGINT,
    @bEstado BIT,
    @cMotivo NVARCHAR(500),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT @bResultado=0,@cMensaje=N'No se pudo cambiar el estado del producto.',@cCodigoRespuesta='PRODUCTO_ESTADO_NO_ACTUALIZADO',@nHttpRespuesta=400;
    SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
    IF @nUsuarioId IS NULL OR @nUotId IS NULL OR @nProductoId IS NULL OR @bEstado IS NULL OR @cMotivo IS NULL
    BEGIN SET @cMensaje=N'Indique el motivo del cambio de estado.'; RETURN 1; END;
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_DESACTIVAR')=0
    BEGIN SET @cMensaje=N'No tiene permiso para cambiar el estado de productos en esta UOT.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM logistica.Producto WHERE producto_id=@nProductoId)
    BEGIN SET @cMensaje=N'El producto no está disponible.'; SET @cCodigoRespuesta='PRODUCTO_NO_DISPONIBLE'; SET @nHttpRespuesta=404; RETURN 1; END;
    IF @bEstado=0 AND EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE producto_id=@nProductoId AND (stock_actual>0 OR stock_reservado>0))
    BEGIN SET @cMensaje=N'No puede desactivar un producto que mantiene stock actual o reservado.'; SET @cCodigoRespuesta='PRODUCTO_CON_STOCK'; SET @nHttpRespuesta=409; RETURN 1; END;

    UPDATE logistica.Producto SET estado=@bEstado WHERE producto_id=@nProductoId;
    SELECT @bResultado=1,
           @cMensaje=CASE WHEN @bEstado=1 THEN N'Producto reactivado correctamente.' ELSE N'Producto desactivado correctamente.' END,
           @cCodigoRespuesta=CASE WHEN @bEstado=1 THEN 'PRODUCTO_ACTIVADO' ELSE 'PRODUCTO_DESACTIVADO' END,
           @nHttpRespuesta=200;
    RETURN 0;
END;
GO
