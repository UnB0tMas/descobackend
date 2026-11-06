IF OBJECT_ID(N'[logistica].[PA_AlmacenProducto_Ins_StockInicial]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_AlmacenProducto_Ins_StockInicial];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_AlmacenProducto_Ins_StockInicial
' Descripción             : Registra stock inicial manteniendo contratos y validaciones del sistema.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Actualización de registro de stock inicial por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @nMovimientoId BIGINT,
            @nStockActual DECIMAL(19,3),
            @nStockMinimoFinal DECIMAL(19,3),
            @bResultado BIT,
            @cMensaje NVARCHAR(300),
            @cCodigoRespuesta VARCHAR(60),
            @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_AlmacenProducto_Ins_StockInicial]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @nAlmacenId = 0,
        @nProductoId = 0,
        @nStockInicial = 0,
        @nStockMinimo = 0,
        @nCostoUnitario = 0,
        @cMoneda = '',
        @cLote = '',
        @dFechaVencimiento = '2026-10-11',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @nArchivoSustentoId = 0,
        @cDocumento = N'',
        @cObservacion = N'',
        @nMovimientoId = @nMovimientoId OUTPUT,
        @nStockActual = @nStockActual OUTPUT,
        @nStockMinimoFinal = @nStockMinimoFinal OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nMovimientoId, @nStockActual, @nStockMinimoFinal, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
IF OBJECT_ID(N'[logistica].[PA_AlmacenProducto_Ins_StockInicial]', N'P') IS NOT NULL DROP PROCEDURE [logistica].[PA_AlmacenProducto_Ins_StockInicial];
GO
CREATE PROCEDURE [logistica].[PA_AlmacenProducto_Ins_StockInicial]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nUotId BIGINT,
    @nAlmacenId BIGINT,
    @nProductoId BIGINT,
    @nStockInicial DECIMAL(19,3) = 0,
    @nStockMinimo DECIMAL(19,3) = 0,
    @nCostoUnitario DECIMAL(19,4) = NULL,
    @nPrecioVenta DECIMAL(19,4) = NULL,
    @cMoneda CHAR(3) = NULL,
    @cLote VARCHAR(80) = NULL,
    @dFechaVencimiento DATE = NULL,
    @gClaveIdempotencia UNIQUEIDENTIFIER,
    @nArchivoSustentoId BIGINT = NULL,
    @cDocumento NVARCHAR(120) = NULL,
    @cObservacion NVARCHAR(500) = NULL,
    @cMonedaVenta CHAR(3) = NULL,
    @nMovimientoId BIGINT OUTPUT,
    @nStockActual DECIMAL(19,3) OUTPUT,
    @nStockMinimoFinal DECIMAL(19,3) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nMovimientoId = NULL,
        @nStockActual = NULL,
        @nStockMinimoFinal = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo configurar el producto en el almacén.',
        @cCodigoRespuesta = 'STOCK_INICIAL_NO_REGISTRADO',
        @nHttpRespuesta = 400;

    SET @nStockInicial = COALESCE(@nStockInicial, 0);
    SET @nStockMinimo = COALESCE(@nStockMinimo, 0);
    SET @cLote = NULLIF(LTRIM(RTRIM(@cLote)), '');
    SET @cMoneda = UPPER(NULLIF(LTRIM(RTRIM(@cMoneda)), ''));
    SET @cDocumento = NULLIF(LTRIM(RTRIM(@cDocumento)), N'');
    SET @cObservacion = NULLIF(LTRIM(RTRIM(@cObservacion)), N'');

    IF @nStockInicial < 0 OR @nStockMinimo < 0
    BEGIN
        SET @cMensaje = N'El stock inicial y el stock mínimo no pueden ser negativos.';
        RETURN 1;
    END;

    IF @gClaveIdempotencia IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no contiene una clave válida.';
        RETURN 1;
    END;

    DECLARE @bComercial BIT=(SELECT permite_venta FROM logistica.Producto WHERE producto_id=@nProductoId AND estado=1);
    SET @cMonedaVenta=UPPER(NULLIF(LTRIM(RTRIM(@cMonedaVenta)),''));
    IF @nPrecioVenta IS NULL AND @bComercial=1
        SELECT TOP(1) @nPrecioVenta=precio_venta,@cMonedaVenta=moneda FROM logistica.ProductoPrecio
        WHERE producto_id=@nProductoId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL ORDER BY version DESC;
    IF @bComercial=1 AND @nPrecioVenta IS NULL
    BEGIN SET @cMensaje=N'Ingrese el precio de venta para comercializar este producto en la UOT.';RETURN 1;END;
    SET @cMonedaVenta=COALESCE(@cMonedaVenta,@cMoneda,'PEN');
    IF @nPrecioVenta IS NOT NULL AND NOT EXISTS(SELECT 1 FROM config.CatalogoRecursoValor WHERE catalogo='MONEDA' AND codigo=@cMonedaVenta AND estado=1)
    BEGIN SET @cMensaje=N'La moneda de venta seleccionada no esta disponible.';RETURN 1;END;
    IF @nPrecioVenta IS NOT NULL
    BEGIN
        IF @nPrecioVenta<=0
        BEGIN SET @cMensaje=N'El precio de venta debe ser mayor que cero.'; RETURN 1; END;
        IF NOT EXISTS (SELECT 1 FROM logistica.Producto WHERE producto_id=@nProductoId AND estado=1 AND permite_venta=1)
        BEGIN SET @cMensaje=N'Producto de uso operativo: no admite venta.'; RETURN 1; END;
        IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'PRODUCTOS_PRECIO')=0
        BEGIN SELECT @cMensaje=N'No tiene permiso para definir precios comerciales.',@cCodigoRespuesta='NO_AUTORIZADO',@nHttpRespuesta=403; RETURN 1; END;
    END;

    IF @nCostoUnitario IS NOT NULL AND @nCostoUnitario < 0
    BEGIN
        SET @cMensaje = N'El costo unitario no puede ser negativo.';
        RETURN 1;
    END;

    IF @dFechaVencimiento IS NOT NULL
       AND @dFechaVencimiento < CONVERT(date, SYSDATETIME())
    BEGIN
        SET @cMensaje = N'La fecha de vencimiento no puede ser anterior a hoy.';
        RETURN 1;
    END;

    IF @nArchivoSustentoId IS NOT NULL
       AND @nStockInicial <= 0
    BEGIN
        SET @cMensaje = N'El documento de sustento solo corresponde cuando se registra stock inicial.';
        RETURN 1;
    END;

    IF @nCostoUnitario IS NOT NULL AND @cMoneda IS NULL
        SET @cMoneda = 'PEN';

    IF @cMoneda IS NOT NULL
       AND (LEN(@cMoneda) <> 3 OR @cMoneda LIKE '%[^A-Z]%')
    BEGIN
        SET @cMensaje = N'La moneda seleccionada no es válida.';
        RETURN 1;
    END;

    DECLARE
        @nUotResuelta BIGINT = @nUotId,
        @bModoGeneral BIT,
        @bOk BIT,
        @cMsg NVARCHAR(300);

    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
        @nUsuarioId = @nUsuarioId,
        @nSesionUsuarioId = @nSesionUsuarioId,
        @nUotSolicitada = @nUotResuelta,
        @cCodigoPermiso = 'ALMACENES_MOVIMIENTO',
        @bRequiereUot = 1,
        @nUotId = @nUotResuelta OUTPUT,
        @bModoGeneral = @bModoGeneral OUTPUT,
        @bResultado = @bOk OUTPUT,
        @cMensaje = @cMsg OUTPUT;

    IF ISNULL(@bOk, 0) = 0
    BEGIN
        SET @cMensaje = COALESCE(NULLIF(@cMsg, N''), @cMensaje);
        RETURN 1;
    END;

    IF @nArchivoSustentoId IS NOT NULL
    BEGIN
        SELECT
            @cDocumento = LEFT(A.nombre_original, 120)
        FROM [archivo].[Archivo] A
        WHERE A.archivo_id = @nArchivoSustentoId
          AND A.uot_id = @nUotResuelta
          AND A.estado = 1;

        IF @cDocumento IS NULL
        BEGIN
            SET @cMensaje = N'El documento de sustento seleccionado no está disponible.';
            RETURN 1;
        END;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [logistica].[Almacen] A
        INNER JOIN [logistica].[AlmacenUOT] AU
            ON AU.almacen_id = A.almacen_id
           AND AU.uot_id = @nUotResuelta
           AND AU.estado = 1
           AND AU.fecha_hasta IS NULL
           AND AU.permite_entrada = 1
        WHERE A.almacen_id = @nAlmacenId
          AND A.uot_propietaria_id = @nUotResuelta
          AND A.estado = 1
    )
    BEGIN
        SET @cMensaje = N'El almacén seleccionado no permite registrar entradas para esta UOT.';
        RETURN 1;
    END;

    DECLARE
        @bRequiereLote BIT,
        @bControlaVencimiento BIT;

    SELECT
        @bRequiereLote = P.requiere_lote,
        @bControlaVencimiento = P.controla_vencimiento
    FROM [logistica].[Producto] P
    WHERE P.producto_id = @nProductoId
      AND P.estado = 1;

    IF @bRequiereLote IS NULL
    BEGIN
        SET @cMensaje = N'El producto seleccionado no está disponible.';
        RETURN 1;
    END;

    IF @bRequiereLote = 1 AND @cLote IS NULL
    BEGIN
        SET @cMensaje = N'El producto requiere indicar un lote.';
        RETURN 1;
    END;

    IF @bControlaVencimiento = 1 AND @dFechaVencimiento IS NULL
    BEGIN
        SET @cMensaje = N'El producto requiere indicar una fecha de vencimiento.';
        RETURN 1;
    END;

    /* Repetición idempotente de un stock inicial con movimiento. */
    IF EXISTS
    (
        SELECT 1
        FROM [logistica].[MovimientoInventario] M
        WHERE M.clave_idempotencia = @gClaveIdempotencia
    )
    BEGIN
        SELECT TOP (1)
            @nMovimientoId = M.movimiento_inventario_id
        FROM [logistica].[MovimientoInventario] M
        INNER JOIN [logistica].[DetalleMovimientoInventario] D
            ON D.movimiento_inventario_id = M.movimiento_inventario_id
           AND D.producto_id = @nProductoId
        WHERE M.clave_idempotencia = @gClaveIdempotencia
          AND M.almacen_id = @nAlmacenId
          AND M.uot_id = @nUotResuelta
          AND M.estado = 1;

        IF @nMovimientoId IS NULL
        BEGIN
            SET @cMensaje = N'La clave de solicitud ya fue utilizada en otra operación.';
            SET @cCodigoRespuesta = 'CLAVE_IDEMPOTENCIA_REUTILIZADA';
            SET @nHttpRespuesta = 409;
            RETURN 1;
        END;

        SELECT
            @nStockActual = S.stock_actual,
            @nStockMinimoFinal = S.stock_minimo
        FROM [logistica].[AlmacenProductoStock] S
        WHERE S.almacen_id = @nAlmacenId
          AND S.producto_id = @nProductoId;

        IF @nArchivoSustentoId IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM [archivo].[ArchivoVinculo] AV
               WHERE AV.archivo_id = @nArchivoSustentoId
                 AND AV.movimiento_inventario_id = @nMovimientoId
                 AND AV.estado = 1
           )
        BEGIN
            INSERT INTO [archivo].[ArchivoVinculo]
            (
                archivo_id,
                movimiento_inventario_id,
                estado
            )
            VALUES
            (
                @nArchivoSustentoId,
                @nMovimientoId,
                1
            );
        END;

        SELECT
            @bResultado = 1,
            @cMensaje = N'El producto ya fue configurado correctamente.',
            @cCodigoRespuesta = 'STOCK_INICIAL_REGISTRADO',
            @nHttpRespuesta = 200;

        RETURN 0;
    END;

    IF @nStockInicial > 0
       AND EXISTS
       (
           SELECT 1
           FROM [logistica].[AlmacenProductoStock]
           WHERE almacen_id = @nAlmacenId
             AND producto_id = @nProductoId
             AND (stock_actual <> 0 OR stock_reservado <> 0)
       )
    BEGIN
        SET @cMensaje = N'El producto ya tiene stock en el almacén. Registre un movimiento de inventario.';
        SET @cCodigoRespuesta = 'PRODUCTO_YA_TIENE_STOCK';
        SET @nHttpRespuesta = 409;
        RETURN 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS(SELECT 1 FROM logistica.ProductoUOTPolitica WITH(UPDLOCK,HOLDLOCK) WHERE uot_id=@nUotResuelta AND producto_id=@nProductoId)
        INSERT logistica.ProductoUOTPolitica(uot_id,producto_id,permite_venta,permite_uso_interno,estado,usuario_actualizacion_id)
        VALUES(@nUotResuelta,@nProductoId,0,1,1,@nUsuarioId);

        IF @nStockInicial > 0
        BEGIN
            DECLARE
                @cDetalleJson NVARCHAR(MAX),
                @bMovimiento BIT,
                @cMensajeMovimiento NVARCHAR(300);

            SELECT @cDetalleJson =
            (
                SELECT
                    @nProductoId AS productoId,
                    @nStockInicial AS cantidad,
                    @nCostoUnitario AS costoUnitario,
                    @cMoneda AS moneda,
                    @cLote AS lote,
                    @dFechaVencimiento AS fechaVencimiento
                FOR JSON PATH
            );

            EXEC [logistica].[PA_MovimientoInventario_Ins_Registrar]
                @nUsuarioId = @nUsuarioId,
                @nUotId = @nUotResuelta,
                @nAlmacenId = @nAlmacenId,
                @cTipo = 'AJUSTE',
                @cNaturaleza = 'E',
                @gClaveIdempotencia = @gClaveIdempotencia,
                @cDetalleJson = @cDetalleJson,
                @nProveedorPersonaId = NULL,
                @nProveedorEmpresaId = NULL,
                @cDocumento = @cDocumento,
                @cObservacion = @cObservacion,
                @nMovimientoId = @nMovimientoId OUTPUT,
                @bResultado = @bMovimiento OUTPUT,
                @cMensaje = @cMensajeMovimiento OUTPUT;

            IF ISNULL(@bMovimiento, 0) = 0
            BEGIN
                SET @cMensaje = COALESCE(
                    NULLIF(@cMensajeMovimiento, N''),
                    N'No se pudo registrar el stock inicial.'
                );
                THROW 51070, N'DESCO_STOCK_INICIAL_NO_REGISTRADO', 1;
            END;

            IF @nArchivoSustentoId IS NOT NULL
            BEGIN
                INSERT INTO [archivo].[ArchivoVinculo]
                (
                    archivo_id,
                    movimiento_inventario_id,
                    estado
                )
                VALUES
                (
                    @nArchivoSustentoId,
                    @nMovimientoId,
                    1
                );
            END;
        END
        ELSE
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM [logistica].[AlmacenProductoStock] WITH (UPDLOCK, HOLDLOCK)
                WHERE almacen_id = @nAlmacenId
                  AND producto_id = @nProductoId
            )
            BEGIN
                INSERT INTO [logistica].[AlmacenProductoStock]
                (
                    almacen_id,
                    producto_id,
                    stock_actual,
                    stock_reservado,
                    stock_minimo,
                    fecha_actualizacion
                )
                VALUES
                (
                    @nAlmacenId,
                    @nProductoId,
                    0,
                    0,
                    @nStockMinimo,
                    SYSUTCDATETIME()
                );
            END;
        END;

        UPDATE [logistica].[AlmacenProductoStock]
        SET
            stock_minimo = @nStockMinimo,
            fecha_actualizacion = SYSUTCDATETIME()
        WHERE almacen_id = @nAlmacenId
          AND producto_id = @nProductoId;

        SELECT
            @nStockActual = S.stock_actual,
            @nStockMinimoFinal = S.stock_minimo
        FROM [logistica].[AlmacenProductoStock] S
        WHERE S.almacen_id = @nAlmacenId
          AND S.producto_id = @nProductoId;

        /* Precio de SALIDA de la UOT; no se confunde con el costo de ENTRADA del Kardex.
           La versión se guarda en la misma transacción del stock inicial. */
        IF @nPrecioVenta IS NOT NULL AND NOT EXISTS
             (SELECT 1 FROM logistica.ProductoPrecio WITH(UPDLOCK,HOLDLOCK) WHERE producto_id=@nProductoId AND uot_id=@nUotResuelta AND estado=1 AND fecha_hasta IS NULL AND precio_venta=@nPrecioVenta AND moneda=@cMonedaVenta)
        BEGIN
            UPDATE logistica.ProductoPrecio SET estado=0,fecha_hasta=COALESCE(fecha_hasta,SYSUTCDATETIME())
            WHERE producto_id=@nProductoId AND uot_id=@nUotResuelta AND estado=1 AND fecha_hasta IS NULL;
            DECLARE @nNuevaVersion INT;
            SELECT @nNuevaVersion=ISNULL(MAX(version),0)+1 FROM logistica.ProductoPrecio WITH(UPDLOCK,HOLDLOCK)
            WHERE producto_id=@nProductoId AND uot_id=@nUotResuelta;
            INSERT INTO logistica.ProductoPrecio
              (producto_id,uot_id,precio_inicial,precio_venta,moneda,version,fecha_desde,estado,usuario_id,clave_idempotencia)
            VALUES(@nProductoId,@nUotResuelta,CASE WHEN COALESCE(@cMoneda,'PEN')=@cMonedaVenta THEN COALESCE(@nCostoUnitario,0) ELSE 0 END,@nPrecioVenta,@cMonedaVenta,@nNuevaVersion,SYSUTCDATETIME(),1,@nUsuarioId,@gClaveIdempotencia);
        END;
        IF @nPrecioVenta IS NOT NULL
            UPDATE logistica.ProductoUOTPolitica
            SET permite_venta=1,permite_uso_interno=1,estado=1,
                usuario_actualizacion_id=@nUsuarioId,fecha_actualizacion=SYSUTCDATETIME()
            WHERE producto_id=@nProductoId AND uot_id=@nUotResuelta;
        COMMIT TRANSACTION;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Producto configurado en el almacén.',
            @cCodigoRespuesta = 'STOCK_INICIAL_REGISTRADO',
            @nHttpRespuesta = 201;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @nMovimientoId = NULL;
        SET @nStockActual = NULL;
        SET @nStockMinimoFinal = NULL;
        SET @bResultado = 0;

        IF @cMensaje IS NULL
           OR @cMensaje = N'No se pudo configurar el producto en el almacén.'
            SET @cMensaje = N'No se pudo configurar el producto en el almacén.';

        RETURN 1;
    END CATCH;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Incorpora producto y precio por UOT con monedas separadas. No copia costo referencial a otra moneda sin conversion. Reutiliza precio vigente sin duplicar versiones. Lote y vencimiento obedecen al catalogo. Ejemplo: nPrecioVenta=15,cMonedaVenta=PEN.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'PROCEDURE',@level1name=N'PA_AlmacenProducto_Ins_StockInicial';
GO
