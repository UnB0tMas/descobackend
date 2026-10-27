IF OBJECT_ID(N'[logistica].[PA_ProductoPrecio_Ins_VersionComercial]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProductoPrecio_Ins_VersionComercial];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProductoPrecio_Ins_VersionComercial
' Descripción             : Crea una versión comercial de precio de producto.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_ProductoPrecio_Ins_VersionComercial]
        @nUsuarioId = 0,
        @nUotIdContexto = 0,
        @nProductoId = 0,
        @nUotPrecioId = 0,
        @nPrecioInicial = 0,
        @nPrecioVenta = 0,
        @cMoneda = '',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @nProductoPrecioId = @nProductoPrecioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nProductoPrecioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProductoPrecio_Ins_VersionComercial
    @nUsuarioId BIGINT,
    @nUotIdContexto BIGINT,
    @nProductoId BIGINT,
    @nUotPrecioId BIGINT,
    @nPrecioInicial DECIMAL(19,4),
    @nPrecioVenta DECIMAL(19,4),
    @cMoneda CHAR(3)='PEN',
    @gClaveIdempotencia UNIQUEIDENTIFIER,
    @nProductoPrecioId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SELECT @nProductoPrecioId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el precio.',
           @cCodigoRespuesta='PRECIO_NO_REGISTRADO',@nHttpRespuesta=400;
    SET @cMoneda=UPPER(NULLIF(LTRIM(RTRIM(@cMoneda)),''));

    IF @nUotIdContexto IS NULL OR @nProductoId IS NULL OR @nUotPrecioId IS NULL OR @gClaveIdempotencia IS NULL
    BEGIN SET @cMensaje=N'Complete correctamente los datos del precio.'; RETURN 1; END;
    IF @nUotPrecioId<>@nUotIdContexto
    BEGIN SET @cMensaje=N'El precio debe pertenecer a la UOT seleccionada.'; RETURN 1; END;
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotIdContexto,'PRODUCTOS_PRECIO')=0
    BEGIN SET @cMensaje=N'No tiene permiso para modificar precios en esta UOT.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
    SELECT @nPrecioInicial=COALESCE(@nPrecioInicial,(SELECT TOP(1) PP.precio_inicial FROM logistica.ProductoPrecio PP WHERE PP.producto_id=@nProductoId AND PP.uot_id=@nUotIdContexto ORDER BY PP.version DESC,PP.producto_precio_id DESC),0);
    IF @nPrecioInicial<0 OR @nPrecioVenta IS NULL OR @nPrecioVenta<=0
    BEGIN SET @cMensaje=N'Ingrese precios válidos.'; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM logistica.Producto WHERE producto_id=@nProductoId AND estado=1)
    BEGIN SET @cMensaje=N'El producto no está disponible.'; SET @cCodigoRespuesta='PRODUCTO_NO_DISPONIBLE'; SET @nHttpRespuesta=404; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='MONEDA' AND codigo=@cMoneda AND estado=1)
    BEGIN SET @cMensaje=N'La moneda seleccionada no está disponible.'; RETURN 1; END;

    IF NOT EXISTS(SELECT 1 FROM logistica.Producto WHERE producto_id=@nProductoId AND estado=1 AND permite_venta=1)
    BEGIN SET @cMensaje=N'Producto no habilitado para venta.'; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM logistica.ProductoUOTPolitica P
                  WHERE P.uot_id=@nUotIdContexto AND P.producto_id=@nProductoId
                    AND P.permite_venta=1 AND P.estado=1)
    BEGIN SET @cMensaje=N'La venta no está habilitada para este producto en la UOT.'; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock S
                  JOIN logistica.AlmacenUOT AU ON AU.almacen_id=S.almacen_id AND AU.uot_id=@nUotIdContexto
                  AND AU.estado=1 AND AU.fecha_hasta IS NULL AND AU.permite_salida=1
                  WHERE S.producto_id=@nProductoId)
    BEGIN SET @cMensaje=N'Primero incorpore el producto a un almacén de la UOT.'; RETURN 1; END;

    SELECT @nProductoPrecioId=producto_precio_id
    FROM logistica.ProductoPrecio WHERE clave_idempotencia=@gClaveIdempotencia;
    IF @nProductoPrecioId IS NOT NULL
    BEGIN SELECT @bResultado=1,@cMensaje=N'El precio ya fue registrado correctamente.',@cCodigoRespuesta='PRECIO_REGISTRADO',@nHttpRespuesta=200; RETURN 0; END;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;
        UPDATE logistica.ProductoPrecio
        SET estado=0,fecha_hasta=COALESCE(fecha_hasta,SYSUTCDATETIME())
        WHERE producto_id=@nProductoId AND uot_id=@nUotPrecioId AND estado=1 AND fecha_hasta IS NULL;

        DECLARE @Version INT;
        SELECT @Version=ISNULL(MAX(version),0)+1
        FROM logistica.ProductoPrecio WITH(UPDLOCK,HOLDLOCK)
        WHERE producto_id=@nProductoId AND uot_id=@nUotPrecioId;

        INSERT logistica.ProductoPrecio(producto_id,uot_id,precio_inicial,precio_venta,moneda,version,fecha_desde,fecha_hasta,estado,usuario_id,clave_idempotencia)
        VALUES(@nProductoId,@nUotPrecioId,@nPrecioInicial,@nPrecioVenta,@cMoneda,@Version,SYSUTCDATETIME(),NULL,1,@nUsuarioId,@gClaveIdempotencia);
        SET @nProductoPrecioId=CONVERT(BIGINT,SCOPE_IDENTITY());
        COMMIT;
        SELECT @bResultado=1,@cMensaje=N'Precio registrado correctamente.',@cCodigoRespuesta='PRECIO_REGISTRADO',@nHttpRespuesta=201;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        SET @nProductoPrecioId=NULL;
        IF ERROR_NUMBER() IN(2601,2627)
        BEGIN SET @cMensaje=N'La versión de precio ya fue registrada.'; SET @cCodigoRespuesta='PRECIO_DUPLICADO'; SET @nHttpRespuesta=409; END
        ELSE SET @cMensaje=N'No se pudo registrar el precio. Revise los datos e intente nuevamente.';
        RETURN 1;
    END CATCH;
END;
GO
