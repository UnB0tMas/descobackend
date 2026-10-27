IF OBJECT_ID(N'[logistica].[PA_Producto_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Producto_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Producto_Ins_Registro
' Descripción             : Registra producto.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_Producto_Ins_Registro]
        @nUsuarioId = 0,
        @nUotId = 0,
        @cCodigo = '',
        @cNombre = N'',
        @cDescripcion = N'',
        @cUnidad = '',
        @cCategoria = N'',
        @nProductoId = @nProductoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nProductoId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_Producto_Ins_Registro]
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @cCodigo VARCHAR(50),
    @cNombre NVARCHAR(180),
    @cDescripcion NVARCHAR(700) = NULL,
    @cUnidad VARCHAR(20),
    @cCategoria NVARCHAR(100) = NULL,
    @nProductoId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nProductoId = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo registrar el producto.';

    SET @cCodigo = UPPER(NULLIF(LTRIM(RTRIM(@cCodigo)), ''));
    SET @cNombre = NULLIF(LTRIM(RTRIM(@cNombre)), N'');
    SET @cDescripcion = NULLIF(LTRIM(RTRIM(@cDescripcion)), N'');
    SET @cUnidad = UPPER(NULLIF(LTRIM(RTRIM(@cUnidad)), ''));
    SET @cCategoria = UPPER(NULLIF(LTRIM(RTRIM(@cCategoria)), N''));

    IF @nUsuarioId IS NULL OR @nUotId IS NULL
    BEGIN
        SET @cMensaje = N'Seleccione una UOT válida.';
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [org].[UOT]
        WHERE uot_id = @nUotId
          AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La UOT seleccionada no está disponible.';
        RETURN 1;
    END;

    IF [seg].[FN_Usuario_TienePermisoUOT]
       (@nUsuarioId, @nUotId, 'PRODUCTOS_CREAR') = 0
    BEGIN
        SET @cMensaje = N'No tiene permiso para registrar productos en esta UOT.';
        RETURN 1;
    END;

    IF @cCodigo IS NULL OR @cNombre IS NULL OR @cUnidad IS NULL
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos del producto.';
        RETURN 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [config].[CatalogoRecursoValor]
        WHERE catalogo = 'UNIDAD_MEDIDA'
          AND codigo = @cUnidad
          AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'La unidad de medida seleccionada no está disponible.';
        RETURN 1;
    END;

    IF @cCategoria IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [config].[CatalogoRecursoValor]
           WHERE catalogo = 'CATEGORIA_PRODUCTO'
             AND CONVERT(NVARCHAR(100), codigo) = @cCategoria
             AND estado = 1
       )
    BEGIN
        SET @cMensaje = N'La categoría seleccionada no está disponible.';
        RETURN 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [logistica].[Producto]
        WHERE codigo = @cCodigo
    )
    BEGIN
        SET @cMensaje = N'El código del producto ya está registrado.';
        RETURN 1;
    END;

    BEGIN TRY
        INSERT INTO [logistica].[Producto]
        (
            codigo,
            nombre,
            descripcion,
            unidad_medida,
            categoria,
            estado
        )
        VALUES
        (
            @cCodigo,
            @cNombre,
            @cDescripcion,
            @cUnidad,
            @cCategoria,
            1
        );

        SET @nProductoId = CONVERT(BIGINT, SCOPE_IDENTITY());

        IF @nProductoId IS NULL
        BEGIN
            SET @cMensaje = N'No se pudo obtener el producto registrado.';
            RETURN 1;
        END;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Producto registrado correctamente.';

        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @nProductoId = NULL;
        SET @bResultado = 0;

        IF ERROR_NUMBER() IN (2601, 2627)
            SET @cMensaje = N'El código del producto ya está registrado.';
        ELSE
            SET @cMensaje = N'No se pudo registrar el producto. Revise los datos e intente nuevamente.';

        RETURN 1;
    END CATCH;
END;
GO
