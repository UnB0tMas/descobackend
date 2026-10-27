IF OBJECT_ID(N'[logistica].[PA_Producto_Sel_DetalleUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Producto_Sel_DetalleUOT];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Producto_Sel_DetalleUOT
' Descripción             : Consulta el detalle por UOT de producto.
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
    EXEC [logistica].[PA_Producto_Sel_DetalleUOT]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @nProductoId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_Producto_Sel_DetalleUOT
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT,@nProductoId BIGINT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el producto.',@cCodigoRespuesta='PRODUCTO_NO_DISPONIBLE',@nHttpRespuesta=404;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300);
 EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'PRODUCTOS_VER',1,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
 SELECT P.producto_id productoId,@Uot uotId,U.codigo uotCodigo,U.nombre uotNombre,P.codigo,P.nombre,P.descripcion,
        P.unidad_medida unidadMedidaCodigo,COALESCE(UM.nombre,P.unidad_medida) unidadMedidaNombre,
        CONVERT(VARCHAR(100),P.categoria) categoriaCodigo,COALESCE(CAT.nombre,CONVERT(NVARCHAR(100),P.categoria)) categoriaNombre,
        P.requiere_lote requiereLote,P.controla_vencimiento controlaVencimiento,
        Pr.precio_inicial precioInicial,Pr.precio_venta precioVenta,Pr.moneda,Pr.producto_precio_id productoPrecioId,Pr.version precioVersion,
        Img.archivo_id archivoPrincipalId,P.estado
 FROM logistica.Producto P JOIN org.UOT U ON U.uot_id=@Uot AND U.estado=1
 LEFT JOIN config.CatalogoRecursoValor UM ON UM.catalogo='UNIDAD_MEDIDA' AND UM.codigo=UPPER(P.unidad_medida) AND UM.estado=1
 LEFT JOIN config.CatalogoRecursoValor CAT ON CAT.catalogo='CATEGORIA_PRODUCTO' AND CAT.codigo=UPPER(CONVERT(VARCHAR(100),P.categoria)) AND CAT.estado=1
 OUTER APPLY(SELECT TOP(1) PP.* FROM logistica.ProductoPrecio PP WHERE PP.producto_id=P.producto_id AND PP.estado=1 AND PP.fecha_hasta IS NULL AND (PP.uot_id=@Uot OR PP.uot_id IS NULL) ORDER BY CASE WHEN PP.uot_id=@Uot THEN 0 ELSE 1 END,PP.version DESC,PP.producto_precio_id DESC) Pr
 OUTER APPLY(SELECT TOP(1) PI.archivo_id FROM logistica.ProductoImagen PI JOIN archivo.Archivo A ON A.archivo_id=PI.archivo_id AND A.estado=1 AND A.uot_id=@Uot WHERE PI.producto_id=P.producto_id AND PI.estado=1 ORDER BY PI.es_principal DESC,PI.orden,PI.producto_imagen_id) Img
 WHERE P.producto_id=@nProductoId;
 IF @@ROWCOUNT=0 RETURN 1;
 SELECT @bResultado=1,@cMensaje=N'Producto consultado.',@cCodigoRespuesta='PRODUCTO_OBTENIDO',@nHttpRespuesta=200; RETURN 0;
END;
GO
