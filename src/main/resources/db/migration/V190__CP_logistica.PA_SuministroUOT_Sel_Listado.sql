IF OBJECT_ID(N'[logistica].[PA_SuministroUOT_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroUOT_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroUOT_Sel_Listado
' Descripción             : Lista suministro por UOT.
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
    EXEC [logistica].[PA_SuministroUOT_Sel_Listado]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @nPagina = 0,
        @nTamano = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_SuministroUOT_Sel_Listado]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nUotId BIGINT = NULL,
    @nPagina INT = 1,
    @nTamano INT = 20,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudieron consultar los suministros.',
        @cCodigoRespuesta = 'SUMINISTROS_NO_LISTADOS',
        @nHttpRespuesta = 400;

    SET @nPagina = CASE WHEN ISNULL(@nPagina, 0) < 1 THEN 1 ELSE @nPagina END;
    SET @nTamano = CASE
        WHEN ISNULL(@nTamano, 0) < 1 THEN 20
        WHEN @nTamano > 500 THEN 500
        ELSE @nTamano
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
        @cCodigoPermiso = 'INVENTARIO_LISTAR',
        @bRequiereUot = 0,
        @nUotId = @nUotResuelta OUTPUT,
        @bModoGeneral = @bModoGeneral OUTPUT,
        @bResultado = @bOk OUTPUT,
        @cMensaje = @cMsg OUTPUT;

    IF ISNULL(@bOk, 0) = 0
    BEGIN
        SET @cMensaje = COALESCE(NULLIF(@cMsg, N''), @cMensaje);
        RETURN 1;
    END;

    SELECT
        S.suministro_id AS suministroId,
        S.uot_id AS uotId,
        U.codigo AS uotCodigo,
        U.nombre AS uotNombre,
        S.codigo,
        S.nombre,
        S.unidad_medida AS unidadMedida,
        S.estado,
        COALESCE(K.stock_actual, 0) AS stock,
        COALESCE(K.stock_actual, 0) AS stockActual,
        COALESCE(K.stock_reservado, 0) AS stockReservado,
        COALESCE(K.stock_disponible, 0) AS stockDisponible,
        S.stock_minimo AS stockMinimo,
        CONVERT(
            BIT,
            CASE
                WHEN COALESCE(K.stock_disponible, 0) <= S.stock_minimo THEN 1
                ELSE 0
            END
        ) AS requiereReposicion,
        COUNT_BIG(*) OVER() AS totalRegistros
    FROM [logistica].[Suministro] S
    INNER JOIN [org].[UOT] U
        ON U.uot_id = S.uot_id
    LEFT JOIN [logistica].[SuministroSaldo] K
        ON K.suministro_id = S.suministro_id
    WHERE
        S.estado = 1
        AND U.estado = 1
        AND
        (
            (@bModoGeneral = 0 AND S.uot_id = @nUotResuelta)
            OR
            (
                @bModoGeneral = 1
                AND (@nUotResuelta IS NULL OR S.uot_id = @nUotResuelta)
                AND [seg].[FN_Usuario_TienePermisoUOT](
                    @nUsuarioId,
                    S.uot_id,
                    'INVENTARIO_LISTAR'
                ) = 1
            )
        )
    ORDER BY U.nombre, S.nombre, S.suministro_id
    OFFSET (@nPagina - 1) * @nTamano ROWS
    FETCH NEXT @nTamano ROWS ONLY;

    SELECT
        @bResultado = 1,
        @cMensaje = N'Suministros consultados.',
        @cCodigoRespuesta = 'SUMINISTROS_LISTADOS',
        @nHttpRespuesta = 200;

    RETURN 0;
END;
GO
