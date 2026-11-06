/* DESCO: registra catalogo y precio de venta por UOT de forma atomica. */
IF OBJECT_ID(N'logistica.PA_Producto_Ins_Catalogo',N'P') IS NOT NULL DROP PROCEDURE logistica.PA_Producto_Ins_Catalogo;
GO
IF OBJECT_ID(N'[logistica].[PA_Producto_Ins_Catalogo]', N'P') IS NOT NULL DROP PROCEDURE [logistica].[PA_Producto_Ins_Catalogo];
GO
CREATE PROCEDURE [logistica].[PA_Producto_Ins_Catalogo]
    @nUsuarioId BIGINT, @nUotId BIGINT, @cCodigo VARCHAR(50),
    @cNombre NVARCHAR(180), @cDescripcion NVARCHAR(700)=NULL,
    @cUnidad VARCHAR(20), @cCategoria NVARCHAR(100)=NULL,
    @bPermiteVenta BIT=0, @nPrecioVenta DECIMAL(19,4)=NULL, @cMonedaVenta CHAR(3)=NULL, @gClaveIdempotencia UNIQUEIDENTIFIER,
    @nProductoId BIGINT OUTPUT, @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT, @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT, @bRequiereLote BIT=0, @bControlaVencimiento BIT=0
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SELECT @nProductoId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el producto.',
           @cCodigoRespuesta='PRODUCTO_NO_CREADO',@nHttpRespuesta=400;
    SELECT @cCodigo=UPPER(NULLIF(LTRIM(RTRIM(@cCodigo)),'')),
           @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N''),
           @cUnidad=UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)),'')),
           @cCategoria=UPPER(NULLIF(LTRIM(RTRIM(@cCategoria)),N'')),
           @cDescripcion=NULLIF(LTRIM(RTRIM(@cDescripcion)),N'');
    IF @nUsuarioId IS NULL OR @nUotId IS NULL OR @gClaveIdempotencia IS NULL
       OR @cCodigo IS NULL OR @cNombre IS NULL OR @cUnidad IS NULL
    BEGIN SET @cMensaje=N'Complete los datos del catálogo.'; RETURN 1; END;
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_CREAR')=0
    BEGIN SELECT @cMensaje=N'No tiene permiso para crear productos.',@cCodigoRespuesta='NO_AUTORIZADO',@nHttpRespuesta=403; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotId AND estado=1)
    BEGIN SET @cMensaje=N'La UOT no está disponible.'; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='UNIDAD_MEDIDA' AND codigo=@cUnidad AND estado=1)
    BEGIN SET @cMensaje=N'Unidad de medida no válida.'; RETURN 1; END;
    IF @cCategoria IS NOT NULL AND NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='CATEGORIA_PRODUCTO' AND codigo=@cCategoria AND estado=1)
    BEGIN SET @cMensaje=N'Categoría no válida.'; RETURN 1; END;

    IF @bPermiteVenta=1 AND (@nPrecioVenta IS NULL OR @nPrecioVenta<=0 OR NULLIF(LTRIM(RTRIM(@cMonedaVenta)),'') IS NULL)
    BEGIN SET @cMensaje=N'Ingrese el precio de venta y la moneda al habilitar la comercializacion.'; RETURN 1; END;
    SELECT @nProductoId=producto_id FROM logistica.Producto WHERE clave_idempotencia=@gClaveIdempotencia;
    IF @nProductoId IS NOT NULL
    BEGIN SELECT @bResultado=1,@cMensaje=N'Producto registrado previamente.',@cCodigoRespuesta='PRODUCTO_CREADO',@nHttpRespuesta=200; RETURN 0; END;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM logistica.Producto WITH (UPDLOCK,HOLDLOCK) WHERE codigo=@cCodigo)
        BEGIN SELECT @cMensaje=N'El código ya existe.',@cCodigoRespuesta='PRODUCTO_CODIGO_DUPLICADO',@nHttpRespuesta=409; ROLLBACK; RETURN 1; END;
        INSERT INTO logistica.Producto(codigo,nombre,descripcion,unidad_medida,categoria,permite_venta,estado,clave_idempotencia,requiere_lote,controla_vencimiento)
        VALUES(@cCodigo,@cNombre,@cDescripcion,@cUnidad,@cCategoria,ISNULL(@bPermiteVenta,0),1,@gClaveIdempotencia,ISNULL(@bRequiereLote,0),ISNULL(@bControlaVencimiento,0));
        SET @nProductoId=CONVERT(BIGINT,SCOPE_IDENTITY());

        IF @bPermiteVenta=1 AND NOT EXISTS(SELECT 1 FROM logistica.ProductoPrecio WITH(UPDLOCK,HOLDLOCK) WHERE producto_id=@nProductoId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL AND precio_venta=@nPrecioVenta AND moneda=UPPER(@cMonedaVenta))
        BEGIN
            DECLARE @nPrecioId BIGINT,@bPrecioOk BIT;
            EXEC logistica.PA_ProductoPrecio_Ins_Version @nUsuarioId=@nUsuarioId,@nUotIdContexto=@nUotId,@nProductoId=@nProductoId,@nUotPrecioId=@nUotId,@nPrecio=@nPrecioVenta,@cMoneda=@cMonedaVenta,@nProductoPrecioId=@nPrecioId OUTPUT,@bResultado=@bPrecioOk OUTPUT,@cMensaje=@cMensaje OUTPUT,@cCodigoRespuesta=@cCodigoRespuesta OUTPUT,@nHttpRespuesta=@nHttpRespuesta OUTPUT;
            IF ISNULL(@bPrecioOk,0)=0 BEGIN IF XACT_STATE()<>0 ROLLBACK; SET @bResultado=0; SET @nProductoId=NULL; RETURN 1; END;
        END;
        COMMIT;
        SELECT @bResultado=1,@cMensaje=N'Producto agregado al catálogo.',@cCodigoRespuesta='PRODUCTO_CREADO',@nHttpRespuesta=201;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        IF ERROR_NUMBER() IN(2601,2627)
            SELECT @cMensaje=N'Código o solicitud duplicada.',@cCodigoRespuesta='PRODUCTO_DUPLICADO',@nHttpRespuesta=409;
        SET @nProductoId=NULL;
        RETURN 1;
    END CATCH;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Guarda producto con reglas de lote y vencimiento desde el alta, y precio de venta por UOT en una transaccion. Comercializacion exige precio positivo y moneda; no duplica versiones sin cambios. Ejemplo: enviar nPrecioVenta=15 y cMonedaVenta=PEN al habilitar venta.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'PROCEDURE',@level1name=N'PA_Producto_Ins_Catalogo';
GO
