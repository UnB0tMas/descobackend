IF OBJECT_ID(N'[logistica].[PA_ProductoPrecio_Ins_Version]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProductoPrecio_Ins_Version];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProductoPrecio_Ins_Version
' Descripción             : Crea una versión de precio de producto.
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
    EXEC [logistica].[PA_ProductoPrecio_Ins_Version]
        @nUsuarioId = 0,
        @nUotIdContexto = 0,
        @nProductoId = 0,
        @nUotPrecioId = 0,
        @nPrecio = 0,
        @cMoneda = '',
        @nProductoPrecioId = @nProductoPrecioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nProductoPrecioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_ProductoPrecio_Ins_Version]
    @nUsuarioId BIGINT,
    @nUotIdContexto BIGINT,
    @nProductoId BIGINT,
    @nUotPrecioId BIGINT = NULL,
    @nPrecio DECIMAL(19,4),
    @cMoneda CHAR(3) = 'PEN',
    @nProductoPrecioId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nProductoPrecioId = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo registrar el precio.',
        @cCodigoRespuesta = 'PRECIO_NO_REGISTRADO',
        @nHttpRespuesta = 400;

    SET @cMoneda = UPPER(NULLIF(LTRIM(RTRIM(@cMoneda)), ''));
    IF @cMoneda IS NULL SET @cMoneda = 'PEN';

    IF @nUotIdContexto IS NULL
    BEGIN
        SET @cMensaje = N'Seleccione una UOT.';
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [org].[UOT]
        WHERE uot_id = @nUotIdContexto
          AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La UOT seleccionada no está disponible.';
        RETURN 1;
    END;

    IF @nUotPrecioId IS NOT NULL
       AND @nUotPrecioId <> @nUotIdContexto
    BEGIN
        SET @cMensaje = N'El precio debe pertenecer a la UOT seleccionada.';
        RETURN 1;
    END;

    SET @nUotPrecioId = @nUotIdContexto;

    IF [seg].[FN_Usuario_TienePermisoUOT]
       (@nUsuarioId, @nUotIdContexto, 'PRODUCTOS_PRECIO') = 0
    BEGIN
        SET @cMensaje = N'No tiene permiso para modificar precios en esta UOT.';
        RETURN 1;
    END;

    IF @nPrecio IS NULL OR @nPrecio <= 0
    BEGIN
        SET @cMensaje = N'Ingrese un precio válido.';
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [logistica].[Producto]
        WHERE producto_id = @nProductoId
          AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'El producto no está disponible.';
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [config].[CatalogoRecursoValor]
        WHERE catalogo = 'MONEDA'
          AND codigo = @cMoneda
          AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La moneda seleccionada no está disponible.';
        RETURN 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Serializa la numeración por producto/UOT. */
        DECLARE @nBloqueoPrecioId BIGINT;

        SELECT TOP (1)
            @nBloqueoPrecioId = producto_precio_id
        FROM [logistica].[ProductoPrecio] WITH (UPDLOCK, HOLDLOCK)
        WHERE producto_id = @nProductoId
          AND uot_id = @nUotPrecioId
        ORDER BY producto_precio_id DESC;

        UPDATE [logistica].[ProductoPrecio]
        SET
            estado = 0,
            fecha_hasta = COALESCE(fecha_hasta, SYSUTCDATETIME())
        WHERE producto_id = @nProductoId
          AND uot_id = @nUotPrecioId
          AND estado = 1
          AND fecha_hasta IS NULL;

        DECLARE @nVersion INT;

        SELECT @nVersion = ISNULL(MAX(version), 0) + 1
        FROM [logistica].[ProductoPrecio]
        WHERE producto_id = @nProductoId
          AND uot_id = @nUotPrecioId;

        INSERT INTO [logistica].[ProductoPrecio]
        (
            producto_id,
            uot_id,
            precio_venta,
            moneda,
            version,
            fecha_desde,
            estado,
            usuario_id
        )
        VALUES
        (
            @nProductoId,
            @nUotPrecioId,
            @nPrecio,
            @cMoneda,
            @nVersion,
            SYSUTCDATETIME(),
            1,
            @nUsuarioId
        );

        SET @nProductoPrecioId = CONVERT(BIGINT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Precio registrado correctamente.',
            @cCodigoRespuesta = 'PRECIO_REGISTRADO',
            @nHttpRespuesta = 201;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SELECT
            @nProductoPrecioId = NULL,
            @bResultado = 0,
            @cMensaje = N'No se pudo registrar el precio. Revise los datos e intente nuevamente.',
            @cCodigoRespuesta = 'PRECIO_NO_REGISTRADO',
            @nHttpRespuesta = 400;

        RETURN 1;
    END CATCH;
END;
GO
