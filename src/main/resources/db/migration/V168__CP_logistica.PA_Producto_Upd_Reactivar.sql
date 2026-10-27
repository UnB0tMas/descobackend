IF OBJECT_ID(N'[logistica].[PA_Producto_Upd_Reactivar]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Producto_Upd_Reactivar];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Producto_Upd_Reactivar
' Descripción             : Reactiva producto.
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
    EXEC [logistica].[PA_Producto_Upd_Reactivar]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nProductoId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_Producto_Upd_Reactivar
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nProductoId BIGINT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT @bResultado = 0,
           @cMensaje = N'No se pudo reactivar el producto.',
           @cCodigoRespuesta = 'PRODUCTO_NO_REACTIVADO',
           @nHttpRespuesta = 400;

    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, 'PRODUCTOS_EDITAR') = 0
    BEGIN
        SELECT @cMensaje = N'No tiene permiso para reactivar productos en esta UOT.',
               @cCodigoRespuesta = 'NO_AUTORIZADO', @nHttpRespuesta = 403;
        RETURN 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM logistica.Producto WHERE producto_id = @nProductoId)
    BEGIN
        SELECT @cMensaje = N'El producto no está disponible.',
               @cCodigoRespuesta = 'PRODUCTO_NO_DISPONIBLE', @nHttpRespuesta = 404;
        RETURN 1;
    END;

    UPDATE logistica.Producto
       SET estado = 1
     WHERE producto_id = @nProductoId
       AND estado = 0;

    SELECT @bResultado = 1,
           @cMensaje = CASE WHEN @@ROWCOUNT = 0 THEN N'El producto ya se encontraba activo.' ELSE N'Producto reactivado correctamente.' END,
           @cCodigoRespuesta = 'PRODUCTO_REACTIVADO',
           @nHttpRespuesta = 200;
    RETURN 0;
END;
GO
