IF OBJECT_ID(N'[logistica].[PA_Producto_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Producto_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Producto_Upd_Registro
' Descripción             : Actualiza los datos de producto.
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
    EXEC [logistica].[PA_Producto_Upd_Registro]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nProductoId = 0,
        @cNombre = N'',
        @cDescripcion = N'',
        @cUnidad = '',
        @cCategoria = '',
        @bRequiereLote = 0,
        @bControlaVencimiento = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
IF OBJECT_ID(N'logistica.PA_Producto_Upd_Registro', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_Producto_Upd_Registro;
GO
CREATE PROCEDURE logistica.PA_Producto_Upd_Registro
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nProductoId BIGINT,
    @cNombre NVARCHAR(180),
    @cDescripcion NVARCHAR(700) = NULL,
    @cUnidad VARCHAR(20),
    @cCategoria VARCHAR(40) = NULL,
    @bRequiereLote BIT,
    @bControlaVencimiento BIT,
    @bPermiteVenta BIT, @nPrecioVenta DECIMAL(19,4)=NULL, @cMonedaVenta CHAR(3)=NULL,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo actualizar el producto.',
        @cCodigoRespuesta = 'PRODUCTO_NO_ACTUALIZADO',
        @nHttpRespuesta = 400;

    SELECT
        @cNombre = NULLIF(LTRIM(RTRIM(@cNombre)), N''),
        @cDescripcion = NULLIF(LTRIM(RTRIM(@cDescripcion)), N''),
        @cUnidad = UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)), '')),
        @cCategoria = UPPER(NULLIF(LTRIM(RTRIM(@cCategoria)), ''));

    IF @nUsuarioId IS NULL OR @nUotId IS NULL OR @nProductoId IS NULL
       OR @cNombre IS NULL OR @cUnidad IS NULL
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos del producto.';
        RETURN 1;
    END;

    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId, @nUotId, 'PRODUCTOS_EDITAR') = 0
    BEGIN
        SELECT @cMensaje = N'No tiene permiso para editar productos en esta UOT.',
               @cCodigoRespuesta = 'NO_AUTORIZADO', @nHttpRespuesta = 403;
        RETURN 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM logistica.Producto WHERE producto_id = @nProductoId AND estado = 1)
    BEGIN
        SELECT @cMensaje = N'El producto no está disponible.',
               @cCodigoRespuesta = 'PRODUCTO_NO_DISPONIBLE', @nHttpRespuesta = 404;
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1 FROM config.CatalogoRecursoValor
        WHERE catalogo = 'UNIDAD_MEDIDA' AND codigo = @cUnidad AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La unidad de medida seleccionada no está disponible.';
        RETURN 1;
    END;

    IF @cCategoria IS NOT NULL AND NOT EXISTS
    (
        SELECT 1 FROM config.CatalogoRecursoValor
        WHERE catalogo = 'CATEGORIA_PRODUCTO' AND codigo = @cCategoria AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La categoría seleccionada no está disponible.';
        RETURN 1;
    END;


    IF @bPermiteVenta=1 AND (@nPrecioVenta IS NULL OR @nPrecioVenta<=0 OR NULLIF(LTRIM(RTRIM(@cMonedaVenta)),'') IS NULL)
    BEGIN SET @cMensaje=N'Ingrese el precio de venta y la moneda al habilitar la comercializacion.'; RETURN 1; END;
    IF @bPermiteVenta=0 AND EXISTS (SELECT 1 FROM logistica.ProductoUOTPolitica WHERE producto_id=@nProductoId AND estado=1 AND permite_venta=1)
    BEGIN SET @cMensaje=N'Deshabilite primero los precios comerciales de las UOT afectadas.'; RETURN 1; END;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @bPermiteVenta=0
            UPDATE logistica.ProductoPrecio SET estado=0,fecha_hasta=COALESCE(fecha_hasta,SYSUTCDATETIME())
            WHERE producto_id=@nProductoId AND estado=1 AND fecha_hasta IS NULL;
        UPDATE logistica.Producto
           SET nombre = @cNombre,
               descripcion = @cDescripcion,
               unidad_medida = @cUnidad,
               categoria = @cCategoria,
               requiere_lote = @bRequiereLote,
               controla_vencimiento = @bControlaVencimiento,
               permite_venta = @bPermiteVenta
         WHERE producto_id = @nProductoId
           AND estado = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT @cMensaje = N'El producto no está disponible.',
                   @cCodigoRespuesta = 'PRODUCTO_NO_DISPONIBLE', @nHttpRespuesta = 404;
            ROLLBACK TRANSACTION;
            RETURN 1;
        END;

        IF @bPermiteVenta=1 AND NOT EXISTS(SELECT 1 FROM logistica.ProductoPrecio WITH(UPDLOCK,HOLDLOCK) WHERE producto_id=@nProductoId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL AND precio_venta=@nPrecioVenta AND moneda=UPPER(@cMonedaVenta))
        BEGIN
            DECLARE @nPrecioId BIGINT,@bPrecioOk BIT;
            EXEC logistica.PA_ProductoPrecio_Ins_Version @nUsuarioId=@nUsuarioId,@nUotIdContexto=@nUotId,@nProductoId=@nProductoId,@nUotPrecioId=@nUotId,@nPrecio=@nPrecioVenta,@cMoneda=@cMonedaVenta,@nProductoPrecioId=@nPrecioId OUTPUT,@bResultado=@bPrecioOk OUTPUT,@cMensaje=@cMensaje OUTPUT,@cCodigoRespuesta=@cCodigoRespuesta OUTPUT,@nHttpRespuesta=@nHttpRespuesta OUTPUT;
            IF ISNULL(@bPrecioOk,0)=0 BEGIN IF XACT_STATE()<>0 ROLLBACK; SET @bResultado=0;  RETURN 1; END;
        END;
        COMMIT TRANSACTION;

        SELECT @bResultado = 1,
               @cMensaje = N'Producto actualizado correctamente.',
               @cCodigoRespuesta = 'PRODUCTO_ACTUALIZADO',
               @nHttpRespuesta = 200;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        SET @cMensaje = N'No se pudo actualizar el producto.';
        RETURN 1;
    END CATCH;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Guarda producto y precio de venta por UOT en una transaccion. Comercializacion exige precio positivo y moneda; no duplica versiones sin cambios. Ejemplo: enviar nPrecioVenta=15 y cMonedaVenta=PEN al habilitar venta.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'PROCEDURE',@level1name=N'PA_Producto_Upd_Registro';
GO
