IF OBJECT_ID(N'[logistica].[PA_Producto_Ins_RegistroComercial]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Producto_Ins_RegistroComercial];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Producto_Ins_RegistroComercial
' Descripción             : Registra un producto comercial producto.
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
        @nProductoId BIGINT,
        @nProductoPrecioId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_Producto_Ins_RegistroComercial]
        @nUsuarioId = 0,
        @nUotId = 0,
        @cCodigo = '',
        @cNombre = N'',
        @cDescripcion = N'',
        @cUnidad = '',
        @cCategoria = N'',
        @nPrecioInicial = 0,
        @nPrecioVenta = 0,
        @cMoneda = '',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @nProductoId = @nProductoId OUTPUT,
        @nProductoPrecioId = @nProductoPrecioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nProductoId, @nProductoPrecioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_Producto_Ins_RegistroComercial
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @cCodigo VARCHAR(50),
    @cNombre NVARCHAR(180),
    @cDescripcion NVARCHAR(700)=NULL,
    @cUnidad VARCHAR(20),
    @cCategoria NVARCHAR(100)=NULL,
    @nPrecioInicial DECIMAL(19,4),
    @nPrecioVenta DECIMAL(19,4),
    @cMoneda CHAR(3)='PEN',
    @gClaveIdempotencia UNIQUEIDENTIFIER,
    @nProductoId BIGINT OUTPUT,
    @nProductoPrecioId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT @nProductoId=NULL,@nProductoPrecioId=NULL,@bResultado=0,
           @cMensaje=N'No se pudo registrar el producto.',@cCodigoRespuesta='PRODUCTO_NO_CREADO',@nHttpRespuesta=400;

    SELECT @cCodigo=UPPER(NULLIF(LTRIM(RTRIM(@cCodigo)),'')),
           @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N''),
           @cDescripcion=NULLIF(LTRIM(RTRIM(@cDescripcion)),N''),
           @cUnidad=UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)),'')),
           @cCategoria=UPPER(NULLIF(LTRIM(RTRIM(@cCategoria)),N'')),
           @cMoneda=UPPER(NULLIF(LTRIM(RTRIM(@cMoneda)),''));

    IF @nUsuarioId IS NULL OR @nUotId IS NULL OR @gClaveIdempotencia IS NULL
    BEGIN SET @cMensaje=N'Complete correctamente los datos del producto.'; RETURN 1; END;

    SELECT @nProductoId=P.producto_id
    FROM logistica.Producto P
    WHERE P.clave_idempotencia=@gClaveIdempotencia;

    IF @nProductoId IS NOT NULL
    BEGIN
        SELECT TOP(1) @nProductoPrecioId=producto_precio_id
        FROM logistica.ProductoPrecio
        WHERE producto_id=@nProductoId AND uot_id=@nUotId
        ORDER BY version DESC,producto_precio_id DESC;
        SELECT @bResultado=1,@cMensaje=N'El producto ya fue registrado correctamente.',
               @cCodigoRespuesta='PRODUCTO_CREADO',@nHttpRespuesta=200;
        RETURN 0;
    END;

    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_CREAR')=0
       OR seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_PRECIO')=0
    BEGIN SET @cMensaje=N'No tiene permiso para registrar productos y precios en esta UOT.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;

    IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotId AND estado=1)
    BEGIN SET @cMensaje=N'La UOT seleccionada no está disponible.'; RETURN 1; END;
    IF @cCodigo IS NULL OR @cNombre IS NULL OR @cUnidad IS NULL
    BEGIN SET @cMensaje=N'Complete correctamente los datos del producto.'; RETURN 1; END;
    IF @nPrecioInicial IS NULL OR @nPrecioInicial<0 OR @nPrecioVenta IS NULL OR @nPrecioVenta<=0
    BEGIN SET @cMensaje=N'Ingrese precios válidos para el producto.'; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='UNIDAD_MEDIDA' AND codigo=@cUnidad AND estado=1)
    BEGIN SET @cMensaje=N'La unidad de medida seleccionada no está disponible.'; RETURN 1; END;
    IF @cCategoria IS NOT NULL AND NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='CATEGORIA_PRODUCTO' AND codigo=@cCategoria AND estado=1)
    BEGIN SET @cMensaje=N'La categoría seleccionada no está disponible.'; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='MONEDA' AND codigo=@cMoneda AND estado=1)
    BEGIN SET @cMensaje=N'La moneda seleccionada no está disponible.'; RETURN 1; END;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        IF EXISTS(SELECT 1 FROM logistica.Producto WITH(UPDLOCK,HOLDLOCK) WHERE codigo=@cCodigo)
            THROW 51070,N'PRODUCTO_CODIGO_DUPLICADO',1;

        INSERT logistica.Producto(codigo,nombre,descripcion,unidad_medida,categoria,estado,clave_idempotencia)
        VALUES(@cCodigo,@cNombre,@cDescripcion,@cUnidad,@cCategoria,1,@gClaveIdempotencia);
        SET @nProductoId=CONVERT(BIGINT,SCOPE_IDENTITY());

        INSERT logistica.ProductoPrecio(producto_id,uot_id,precio_inicial,precio_venta,moneda,version,fecha_desde,fecha_hasta,estado,usuario_id,clave_idempotencia)
        VALUES(@nProductoId,@nUotId,@nPrecioInicial,@nPrecioVenta,@cMoneda,1,SYSUTCDATETIME(),NULL,1,@nUsuarioId,@gClaveIdempotencia);
        SET @nProductoPrecioId=CONVERT(BIGINT,SCOPE_IDENTITY());

        COMMIT;
        SELECT @bResultado=1,@cMensaje=N'Producto y precio registrados correctamente.',
               @cCodigoRespuesta='PRODUCTO_CREADO',@nHttpRespuesta=201;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        SELECT @nProductoId=NULL,@nProductoPrecioId=NULL,@bResultado=0;
        IF ERROR_MESSAGE() LIKE '%PRODUCTO_CODIGO_DUPLICADO%'
        BEGIN SET @cMensaje=N'El código del producto ya está registrado.'; SET @cCodigoRespuesta='PRODUCTO_CODIGO_DUPLICADO'; SET @nHttpRespuesta=409; END
        ELSE IF ERROR_NUMBER() IN(2601,2627)
        BEGIN SET @cMensaje=N'El producto o la solicitud ya están registrados.'; SET @cCodigoRespuesta='PRODUCTO_DUPLICADO'; SET @nHttpRespuesta=409; END
        ELSE
        BEGIN SET @cMensaje=N'No se pudo registrar el producto. Revise los datos e intente nuevamente.'; END;
        RETURN 1;
    END CATCH;
END;
GO
