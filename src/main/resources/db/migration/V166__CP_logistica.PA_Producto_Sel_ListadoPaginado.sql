IF OBJECT_ID(N'[logistica].[PA_Producto_Sel_ListadoPaginado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Producto_Sel_ListadoPaginado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Producto_Sel_ListadoPaginado
' Descripción             : Consulta el listado paginado de producto.
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
    EXEC [logistica].[PA_Producto_Sel_ListadoPaginado]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @cBuscar = N'',
        @cCategoria = '',
        @bEstado = 0,
        @nPagina = 0,
        @nTamano = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_Producto_Sel_ListadoPaginado
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT=NULL,@cBuscar NVARCHAR(180)=NULL,@cCategoria VARCHAR(40)=NULL,@bEstado BIT=NULL,@nPagina INT=1,@nTamano INT=20,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar los productos.',@cCodigoRespuesta='PRODUCTOS_NO_LISTADOS',@nHttpRespuesta=400;
 SELECT @cBuscar=NULLIF(LTRIM(RTRIM(@cBuscar)),N''),@cCategoria=UPPER(NULLIF(LTRIM(RTRIM(@cCategoria)),''));
 SET @nPagina=CASE WHEN ISNULL(@nPagina,0)<1 THEN 1 ELSE @nPagina END; SET @nTamano=CASE WHEN ISNULL(@nTamano,0)<1 THEN 20 WHEN @nTamano>100 THEN 100 ELSE @nTamano END;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300);
 EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'PRODUCTOS_LISTAR',0,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; RETURN 1; END;
 ;WITH Uots AS(
   SELECT U.uot_id,U.codigo,U.nombre FROM org.UOT U WHERE U.estado=1 AND ((@General=0 AND U.uot_id=@Uot) OR (@General=1 AND (@Uot IS NULL OR U.uot_id=@Uot) AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,U.uot_id,'PRODUCTOS_LISTAR')=1))
 ), Base AS(
   SELECT P.producto_id productoId,U.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,P.codigo,P.nombre,P.descripcion,
          P.unidad_medida unidadMedidaCodigo,COALESCE(UM.nombre,P.unidad_medida) unidadMedidaNombre,
          CONVERT(VARCHAR(100),P.categoria) categoriaCodigo,COALESCE(CAT.nombre,CONVERT(NVARCHAR(100),P.categoria)) categoriaNombre,
          P.requiere_lote requiereLote,P.controla_vencimiento controlaVencimiento,
          Pr.precio_inicial precioInicial,Pr.precio_venta precioVenta,Pr.moneda,Pr.producto_precio_id productoPrecioId,Pr.version precioVersion,
          Img.archivo_id archivoPrincipalId,P.estado
   FROM logistica.Producto P CROSS JOIN Uots U
   LEFT JOIN config.CatalogoRecursoValor UM ON UM.catalogo='UNIDAD_MEDIDA' AND UM.codigo=UPPER(P.unidad_medida) AND UM.estado=1
   LEFT JOIN config.CatalogoRecursoValor CAT ON CAT.catalogo='CATEGORIA_PRODUCTO' AND CAT.codigo=UPPER(CONVERT(VARCHAR(100),P.categoria)) AND CAT.estado=1
   OUTER APPLY(SELECT TOP(1) PP.* FROM logistica.ProductoPrecio PP WHERE PP.producto_id=P.producto_id AND PP.estado=1 AND PP.fecha_hasta IS NULL AND (PP.uot_id=U.uot_id OR PP.uot_id IS NULL) ORDER BY CASE WHEN PP.uot_id=U.uot_id THEN 0 ELSE 1 END,PP.version DESC,PP.producto_precio_id DESC) Pr
   OUTER APPLY(SELECT TOP(1) PI.archivo_id FROM logistica.ProductoImagen PI JOIN archivo.Archivo A ON A.archivo_id=PI.archivo_id AND A.estado=1 AND A.uot_id=U.uot_id WHERE PI.producto_id=P.producto_id AND PI.estado=1 ORDER BY PI.es_principal DESC,PI.orden,PI.producto_imagen_id) Img
   WHERE (@bEstado IS NULL OR P.estado=@bEstado) AND (@cCategoria IS NULL OR UPPER(CONVERT(VARCHAR(100),P.categoria))=@cCategoria)
     AND (@cBuscar IS NULL OR P.codigo LIKE N'%'+@cBuscar+N'%' OR P.nombre LIKE N'%'+@cBuscar+N'%' OR P.descripcion LIKE N'%'+@cBuscar+N'%')
 )
 SELECT *,COUNT_BIG(*) OVER() totalRegistros FROM Base ORDER BY uotNombre,nombre,productoId OFFSET(@nPagina-1)*@nTamano ROWS FETCH NEXT @nTamano ROWS ONLY;
 SELECT @bResultado=1,@cMensaje=N'Productos consultados.',@cCodigoRespuesta='PRODUCTOS_LISTADOS',@nHttpRespuesta=200; RETURN 0;
END;
GO
