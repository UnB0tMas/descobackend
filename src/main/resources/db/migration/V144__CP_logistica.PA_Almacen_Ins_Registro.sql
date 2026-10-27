IF OBJECT_ID(N'[logistica].[PA_Almacen_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Almacen_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Almacen_Ins_Registro
' Descripción             : Registra almacén.
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
        @nAlmacenId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_Almacen_Ins_Registro]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nUbicacionId = 0,
        @cCodigo = '',
        @cNombre = N'',
        @cDescripcion = N'',
        @nAlmacenId = @nAlmacenId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nAlmacenId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_Almacen_Ins_Registro]
    @nUsuarioId BIGINT,
    @nUotId BIGINT,
    @nUbicacionId BIGINT = NULL,
    @cCodigo VARCHAR(40),
    @cNombre NVARCHAR(160),
    @cDescripcion NVARCHAR(400) = NULL,
    @nAlmacenId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nAlmacenId = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo registrar el almacén.';

    SET @cCodigo = UPPER(NULLIF(LTRIM(RTRIM(@cCodigo)), ''));
    SET @cNombre = NULLIF(LTRIM(RTRIM(@cNombre)), N'');
    SET @cDescripcion = NULLIF(LTRIM(RTRIM(@cDescripcion)), N'');

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
       (@nUsuarioId, @nUotId, 'ALMACENES_CREAR') = 0
    BEGIN
        SET @cMensaje = N'No tiene permiso para registrar almacenes en esta UOT.';
        RETURN 1;
    END;

    IF @cCodigo IS NULL OR @cNombre IS NULL
    BEGIN
        SET @cMensaje = N'Complete correctamente los datos del almacén.';
        RETURN 1;
    END;

    IF @nUbicacionId IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [geo].[Ubicacion]
           WHERE ubicacion_id = @nUbicacionId
             AND estado = 1
       )
    BEGIN
        SET @cMensaje = N'La ubicación seleccionada no está disponible.';
        RETURN 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [logistica].[Almacen]
        WHERE uot_propietaria_id = @nUotId
          AND codigo = @cCodigo
    )
    BEGIN
        SET @cMensaje = N'El código de almacén ya está registrado en esta UOT.';
        RETURN 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO [logistica].[Almacen]
        (
            uot_propietaria_id,
            ubicacion_id,
            codigo,
            nombre,
            descripcion,
            estado
        )
        VALUES
        (
            @nUotId,
            @nUbicacionId,
            @cCodigo,
            @cNombre,
            @cDescripcion,
            1
        );

        SET @nAlmacenId = CONVERT(BIGINT, SCOPE_IDENTITY());

        INSERT INTO [logistica].[AlmacenUOT]
        (
            almacen_id,
            uot_id,
            tipo_acceso,
            permite_entrada,
            permite_salida,
            estado
        )
        VALUES
        (
            @nAlmacenId,
            @nUotId,
            'PROPIETARIO',
            1,
            1,
            1
        );

        COMMIT TRANSACTION;

        SELECT
            @bResultado = 1,
            @cMensaje = N'Almacén registrado correctamente.';

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @nAlmacenId = NULL;
        SET @bResultado = 0;

        IF ERROR_NUMBER() IN (2601, 2627)
            SET @cMensaje = N'El código de almacén ya está registrado en esta UOT.';
        ELSE
            SET @cMensaje = N'No se pudo registrar el almacén. Revise los datos e intente nuevamente.';

        RETURN 1;
    END CATCH;
END;
GO
