IF OBJECT_ID(N'[logistica].[PA_ProductoPrecio_Sel_Historial]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProductoPrecio_Sel_Historial];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProductoPrecio_Sel_Historial
' Descripción             : Consulta el historial de precio de producto.
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
    EXEC [logistica].[PA_ProductoPrecio_Sel_Historial]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nProductoId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProductoPrecio_Sel_Historial
    @nUsuarioId BIGINT,@nUotId BIGINT,@nProductoId BIGINT,
    @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el historial de precios.',@cCodigoRespuesta='HISTORIAL_PRECIOS_NO_LISTADO',@nHttpRespuesta=400;
 IF @nUotId IS NULL OR @nProductoId IS NULL BEGIN SET @cMensaje=N'Seleccione una UOT y un producto.'; RETURN 1; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_PRECIO_HISTORIAL')=0 BEGIN SET @cMensaje=N'No tiene permiso para consultar el historial de precios.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Producto WHERE producto_id=@nProductoId) BEGIN SET @cMensaje=N'El producto no está disponible.'; SET @cCodigoRespuesta='PRODUCTO_NO_DISPONIBLE'; SET @nHttpRespuesta=404; RETURN 1; END;
 SELECT PP.producto_precio_id productoPrecioId,PP.producto_id productoId,P.codigo productoCodigo,P.nombre producto,
        PP.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,PP.precio_inicial precioInicial,PP.precio_venta precioVenta,PP.moneda,PP.version,
        PP.fecha_desde fechaDesde,PP.fecha_hasta fechaHasta,CONVERT(BIT,CASE WHEN PP.estado=1 AND PP.fecha_hasta IS NULL THEN 1 ELSE 0 END) vigente,
        PP.usuario_id usuarioId,US.nombre_usuario nombreUsuario,PP.producto_precio_origen_id precioOrigenId,PO.version precioOrigenVersion
 FROM logistica.ProductoPrecio PP JOIN logistica.Producto P ON P.producto_id=PP.producto_id
 JOIN org.UOT U ON U.uot_id=PP.uot_id LEFT JOIN seg.Usuario US ON US.usuario_id=PP.usuario_id
 LEFT JOIN logistica.ProductoPrecio PO ON PO.producto_precio_id=PP.producto_precio_origen_id
 WHERE PP.producto_id=@nProductoId AND PP.uot_id=@nUotId
 ORDER BY PP.version DESC,PP.fecha_desde DESC,PP.producto_precio_id DESC;
 SELECT @bResultado=1,@cMensaje=N'Historial de precios consultado.',@cCodigoRespuesta='HISTORIAL_PRECIOS_LISTADO',@nHttpRespuesta=200; RETURN 0;
END;
GO
