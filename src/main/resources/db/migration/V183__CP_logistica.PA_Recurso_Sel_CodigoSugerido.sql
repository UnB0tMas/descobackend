IF OBJECT_ID(N'[logistica].[PA_Recurso_Sel_CodigoSugerido]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Recurso_Sel_CodigoSugerido];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Recurso_Sel_CodigoSugerido
' Descripción             : Obtiene el código sugerido para un recurso.
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
        @cCodigo VARCHAR(60),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_Recurso_Sel_CodigoSugerido]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @cTipo = '',
        @cCodigo = @cCodigo OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @cCodigo, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_Recurso_Sel_CodigoSugerido]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nUotId BIGINT,
    @cTipo VARCHAR(20),
    @cCodigo VARCHAR(60) OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @cCodigo = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo generar el código.',
        @cCodigoRespuesta = 'CODIGO_NO_GENERADO',
        @nHttpRespuesta = 400;

    SET @cTipo = UPPER(NULLIF(LTRIM(RTRIM(@cTipo)), ''));

    IF @cTipo NOT IN ('BIEN', 'PRODUCTO', 'ALMACEN', 'SUMINISTRO')
    BEGIN
        SET @cMensaje = N'El tipo de recurso no es válido.';
        RETURN 1;
    END;

    DECLARE
        @cPermiso VARCHAR(40) =
            CASE @cTipo
                WHEN 'BIEN' THEN 'INVENTARIO_CREAR'
                WHEN 'SUMINISTRO' THEN 'INVENTARIO_CREAR'
                WHEN 'PRODUCTO' THEN 'PRODUCTOS_CREAR'
                WHEN 'ALMACEN' THEN 'ALMACENES_CREAR'
            END,
        @nUotResuelta BIGINT = @nUotId,
        @bModoGeneral BIT,
        @bOk BIT,
        @cMsg NVARCHAR(300);

    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
        @nUsuarioId = @nUsuarioId,
        @nSesionUsuarioId = @nSesionUsuarioId,
        @nUotSolicitada = @nUotResuelta,
        @cCodigoPermiso = @cPermiso,
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

    DECLARE
        @cUot VARCHAR(12),
        @cPrefijo VARCHAR(3),
        @nSecuencia BIGINT,
        @bExiste BIT = 1;

    SELECT
        @cUot = LEFT(
            REPLACE(REPLACE(UPPER(U.codigo), ' ', ''), '-', ''),
            12
        )
    FROM [org].[UOT] U
    WHERE U.uot_id = @nUotResuelta
      AND U.estado = 1;

    IF NULLIF(@cUot, '') IS NULL
    BEGIN
        SET @cMensaje = N'La UOT seleccionada no está disponible.';
        RETURN 1;
    END;

    SET @cPrefijo =
        CASE @cTipo
            WHEN 'BIEN' THEN 'BIE'
            WHEN 'PRODUCTO' THEN 'PRO'
            WHEN 'ALMACEN' THEN 'ALM'
            WHEN 'SUMINISTRO' THEN 'SUM'
        END;

    WHILE @bExiste = 1
    BEGIN
        SELECT @nSecuencia = NEXT VALUE FOR [logistica].[SEQ_CodigoAutomatico];

        SET @cCodigo =
            CONCAT(
                @cPrefijo,
                '-',
                @cUot,
                '-',
                RIGHT(
                    REPLICATE('0', 10) + CONVERT(VARCHAR(20), @nSecuencia),
                    10
                )
            );

        SET @bExiste =
            CASE @cTipo
                WHEN 'BIEN' THEN
                    CASE WHEN EXISTS
                    (
                        SELECT 1
                        FROM [logistica].[BienInventario]
                        WHERE codigo_patrimonial = @cCodigo
                    ) THEN 1 ELSE 0 END
                WHEN 'PRODUCTO' THEN
                    CASE WHEN EXISTS
                    (
                        SELECT 1
                        FROM [logistica].[Producto]
                        WHERE codigo = @cCodigo
                    ) THEN 1 ELSE 0 END
                WHEN 'ALMACEN' THEN
                    CASE WHEN EXISTS
                    (
                        SELECT 1
                        FROM [logistica].[Almacen]
                        WHERE uot_propietaria_id = @nUotResuelta
                          AND codigo = @cCodigo
                    ) THEN 1 ELSE 0 END
                WHEN 'SUMINISTRO' THEN
                    CASE WHEN EXISTS
                    (
                        SELECT 1
                        FROM [logistica].[Suministro]
                        WHERE uot_id = @nUotResuelta
                          AND codigo = @cCodigo
                    ) THEN 1 ELSE 0 END
                ELSE 0
            END;
    END;

    SELECT
        @bResultado = 1,
        @cMensaje = N'Código sugerido generado.',
        @cCodigoRespuesta = 'CODIGO_SUGERIDO',
        @nHttpRespuesta = 200;

    RETURN 0;
END;
GO
