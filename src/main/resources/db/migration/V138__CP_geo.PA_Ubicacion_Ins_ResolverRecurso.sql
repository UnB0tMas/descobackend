IF OBJECT_ID(N'[geo].[PA_Ubicacion_Ins_ResolverRecurso]', N'P') IS NOT NULL
    DROP PROCEDURE [geo].[PA_Ubicacion_Ins_ResolverRecurso];
GO

/******************************************************************************************************
' Nombre del PA           : geo.PA_Ubicacion_Ins_ResolverRecurso
' Descripción             : Resuelve la ubicación geográfica de un recurso.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Geografía
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @nUbicacionId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [geo].[PA_Ubicacion_Ins_ResolverRecurso]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @cDistritoCodigo = '',
        @nCentroPobladoId = 0,
        @cReferencia = N'',
        @nUbicacionId = @nUbicacionId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUbicacionId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [geo].[PA_Ubicacion_Ins_ResolverRecurso]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nUotId BIGINT,
    @cDistritoCodigo CHAR(6),
    @nCentroPobladoId BIGINT = NULL,
    @cReferencia NVARCHAR(300) = NULL,
    @nUbicacionId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        @nUbicacionId = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo resolver la ubicación.',
        @cCodigoRespuesta = 'UBICACION_NO_RESUELTA',
        @nHttpRespuesta = 400;

    DECLARE
        @nUotResuelta BIGINT = @nUotId,
        @bModoGeneral BIT,
        @bOk BIT,
        @cMsg NVARCHAR(300);

    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
        @nUsuarioId = @nUsuarioId,
        @nSesionUsuarioId = @nSesionUsuarioId,
        @nUotSolicitada = @nUotResuelta,
        @cCodigoPermiso = 'ALMACENES_CREAR',
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

    SET @cDistritoCodigo = NULLIF(LTRIM(RTRIM(@cDistritoCodigo)), '');
    SET @cReferencia = NULLIF(LTRIM(RTRIM(@cReferencia)), N'');

    IF @cDistritoCodigo IS NULL
       OR LEN(@cDistritoCodigo) <> 6
       OR @cDistritoCodigo LIKE '%[^0-9]%'
       OR NOT EXISTS
       (
           SELECT 1
           FROM [geo].[Distrito]
           WHERE distrito_codigo = @cDistritoCodigo
             AND estado = 1
       )
    BEGIN
        SET @cMensaje = N'Seleccione un distrito válido.';
        RETURN 1;
    END;

    IF @nCentroPobladoId IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [geo].[CentroPoblado]
           WHERE centro_poblado_id = @nCentroPobladoId
             AND distrito_codigo = @cDistritoCodigo
             AND estado = 1
       )
    BEGIN
        SET @cMensaje = N'El centro poblado no corresponde al distrito seleccionado.';
        RETURN 1;
    END;

    SELECT TOP (1)
        @nUbicacionId = U.ubicacion_id
    FROM [geo].[Ubicacion] U
    WHERE U.estado = 1
      AND U.distrito_codigo = @cDistritoCodigo
      AND ISNULL(U.centro_poblado_id, 0) = ISNULL(@nCentroPobladoId, 0)
      AND ISNULL(U.referencia, N'') = ISNULL(@cReferencia, N'')
      AND U.posicion IS NULL
      AND U.altitud_m IS NULL
    ORDER BY U.ubicacion_id;

    IF @nUbicacionId IS NULL
    BEGIN
        BEGIN TRY
            INSERT INTO [geo].[Ubicacion]
            (
                distrito_codigo,
                centro_poblado_id,
                referencia,
                estado
            )
            VALUES
            (
                @cDistritoCodigo,
                @nCentroPobladoId,
                @cReferencia,
                1
            );

            SET @nUbicacionId = CONVERT(BIGINT, SCOPE_IDENTITY());
        END TRY
        BEGIN CATCH
            SET @nUbicacionId = NULL;
            SET @cMensaje = N'No se pudo registrar la ubicación del almacén.';
            RETURN 1;
        END CATCH;
    END;

    SELECT
        @bResultado = 1,
        @cMensaje = N'Ubicación validada.',
        @cCodigoRespuesta = 'UBICACION_RESUELTA',
        @nHttpRespuesta = 200;

    RETURN 0;
END;
GO
