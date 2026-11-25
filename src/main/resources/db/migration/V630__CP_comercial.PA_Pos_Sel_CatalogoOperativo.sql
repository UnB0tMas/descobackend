IF OBJECT_ID(N'[comercial].[PA_Pos_Sel_CatalogoOperativo]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Pos_Sel_CatalogoOperativo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Catálogo operativo de almacenes y productos, sin permisos administrativos de inventario.
CREATE PROCEDURE [comercial].[PA_Pos_Sel_CatalogoOperativo]
    @nUsuarioId BIGINT,
    @gSesionPublicaId UNIQUEIDENTIFIER,
    @nUotId BIGINT,
    @nAlmacenId BIGINT = NULL,
    @bUsoInterno BIT = 0,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) OUTPUT,
    @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @bResultado = 0,
           @cMensaje = N'No se pudo consultar el catálogo.',
           @cCodigoRespuesta = 'POS_CATALOGO_NO_DISPONIBLE',
           @nHttpRespuesta = 400;

    DECLARE @cPermiso VARCHAR(40) = CASE WHEN @bUsoInterno = 1
        THEN 'VENTAS_ENTREGA_TECNICA' ELSE 'POS_OPERAR' END;

    IF @nUsuarioId IS NULL OR @nUotId IS NULL OR @gSesionPublicaId IS NULL
       OR @bUsoInterno IS NULL
       OR NOT EXISTS (
           SELECT 1
           FROM seg.SesionUsuario S
           JOIN seg.UsuarioUOT UU ON UU.usuario_id = S.usuario_id AND UU.uot_id = @nUotId
           WHERE S.usuario_id = @nUsuarioId
             AND S.sesion_publica_id = @gSesionPublicaId
             AND S.uot_contexto_id = @nUotId
             AND S.modo_uot = 'ESPECIFICA'
             AND S.estado = 1 AND S.fecha_revocacion IS NULL
             AND S.fecha_expiracion_renovacion > SYSUTCDATETIME()
             AND UU.estado = 1 AND UU.fecha_desde <= SYSUTCDATETIME()
             AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta >= SYSUTCDATETIME()))
       OR ISNULL(seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, @cPermiso), 0) <> 1
    BEGIN
        SELECT @cMensaje = N'No tiene acceso a este catálogo.',
               @cCodigoRespuesta = 'NO_AUTORIZADO', @nHttpRespuesta = 403;
        RETURN;
    END;

    IF @nAlmacenId IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM logistica.Almacen A
        JOIN logistica.AlmacenUOT AU ON AU.almacen_id = A.almacen_id
        WHERE A.almacen_id = @nAlmacenId AND A.uot_propietaria_id = @nUotId
          AND A.estado = 1 AND AU.uot_id = @nUotId AND AU.estado = 1
          AND AU.fecha_desde <= SYSUTCDATETIME()
          AND (AU.fecha_hasta IS NULL OR AU.fecha_hasta >= SYSUTCDATETIME())
          AND AU.permite_salida = 1)
    BEGIN
        SELECT @cMensaje = N'El almacén no está disponible.',
               @cCodigoRespuesta = 'POS_ALMACEN_NO_DISPONIBLE', @nHttpRespuesta = 404;
        RETURN;
    END;

    SELECT A.almacen_id AS warehouseId, A.codigo AS code, A.nombre AS name
    FROM logistica.Almacen A WITH (NOLOCK)
    JOIN logistica.AlmacenUOT AU WITH (NOLOCK) ON AU.almacen_id = A.almacen_id
    WHERE A.uot_propietaria_id = @nUotId AND A.estado = 1
      AND AU.uot_id = @nUotId AND AU.estado = 1 AND AU.permite_salida = 1
      AND AU.fecha_desde <= SYSUTCDATETIME()
      AND (AU.fecha_hasta IS NULL OR AU.fecha_hasta >= SYSUTCDATETIME())
    ORDER BY A.nombre, A.almacen_id;

    SELECT P.producto_id AS productId, P.codigo AS code, P.nombre AS name,
           P.descripcion AS description,
           COALESCE(UM.nombre, P.unidad_medida) AS unit,
           COALESCE(CAT.nombre, P.categoria) AS category,
           CONVERT(DECIMAL(19,4), CASE WHEN @bUsoInterno = 1 THEN 0 ELSE PR.precio_venta END) AS unitPrice,
           CONVERT(DECIMAL(19,4), CASE WHEN @bUsoInterno = 1 THEN 0 ELSE PR.precio_inicial END) AS initialPrice,
           COALESCE(PR.moneda, 'PEN') AS currency,
           S.stock_disponible AS stockAvailable,
           IMG.archivo_id AS imageFileId,
           IMG.secure_url AS imageUrl
    FROM logistica.AlmacenProductoStock S WITH (NOLOCK)
    JOIN logistica.Producto P WITH (NOLOCK) ON P.producto_id = S.producto_id AND P.estado = 1
    JOIN logistica.ProductoUOTPolitica POL WITH (NOLOCK)
         ON POL.producto_id = P.producto_id AND POL.uot_id = @nUotId AND POL.estado = 1
    LEFT JOIN config.CatalogoRecursoValor UM WITH (NOLOCK)
         ON UM.catalogo = 'UNIDAD_MEDIDA' AND UM.codigo = UPPER(P.unidad_medida) AND UM.estado = 1
    LEFT JOIN config.CatalogoRecursoValor CAT WITH (NOLOCK)
         ON CAT.catalogo = 'CATEGORIA_PRODUCTO'
         AND CAT.codigo = UPPER(CONVERT(VARCHAR(100), P.categoria)) AND CAT.estado = 1
    OUTER APPLY (
        SELECT TOP (1) PP.precio_inicial, PP.precio_venta, PP.moneda
        FROM logistica.ProductoPrecio PP WITH (NOLOCK)
        WHERE PP.producto_id = P.producto_id AND PP.uot_id = @nUotId
          AND PP.estado = 1 AND PP.fecha_hasta IS NULL
        ORDER BY PP.version DESC, PP.producto_precio_id DESC
    ) PR
    OUTER APPLY (
        SELECT TOP (1) PI.archivo_id, F.secure_url
        FROM logistica.ProductoImagen PI WITH (NOLOCK)
        JOIN archivo.Archivo F WITH (NOLOCK) ON F.archivo_id = PI.archivo_id
        WHERE PI.producto_id = P.producto_id AND PI.estado = 1
          AND F.estado = 1 AND F.uot_id = @nUotId
        ORDER BY PI.es_principal DESC, PI.orden, PI.producto_imagen_id
    ) IMG
    WHERE @nAlmacenId IS NOT NULL
      AND S.almacen_id = @nAlmacenId AND S.estado = 1
      AND S.stock_disponible > 0
      AND ((@bUsoInterno = 1 AND POL.permite_uso_interno = 1)
           OR (@bUsoInterno = 0 AND P.permite_venta = 1 AND POL.permite_venta = 1
               AND PR.precio_venta > 0))
    ORDER BY P.nombre, P.producto_id;

    SELECT @bResultado = 1, @cMensaje = N'Catálogo disponible.',
           @cCodigoRespuesta = 'POS_CATALOGO_CONSULTADO', @nHttpRespuesta = 200;
END;
GO
