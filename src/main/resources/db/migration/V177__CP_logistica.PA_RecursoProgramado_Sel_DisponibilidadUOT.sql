IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Sel_DisponibilidadUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Sel_DisponibilidadUOT];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Sel_DisponibilidadUOT
' Descripción             : Consulta la disponibilidad de recursos programados por UOT.
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
    EXEC [logistica].[PA_RecursoProgramado_Sel_DisponibilidadUOT]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_RecursoProgramado_Sel_DisponibilidadUOT]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nUotId BIGINT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudo consultar la disponibilidad.',
        @cCodigoRespuesta = 'DISPONIBILIDAD_NO_LISTADA',
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
        @cCodigoPermiso = 'RECURSOS_VER',
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

    SELECT
        B.bien_inventario_id AS bienInventarioId,
        B.uot_id AS uotId,
        U.codigo AS uotCodigo,
        U.nombre AS uotNombre,
        B.codigo_patrimonial AS codigoPatrimonial,
        B.nombre,
        B.estado_bien AS estadoBien,
        CONVERT(
            BIT,
            CASE
                WHEN B.estado_bien = 'DISPONIBLE'
                 AND NOT EXISTS
                 (
                     SELECT 1
                     FROM [logistica].[RecursoProgramado] R
                     WHERE R.bien_inventario_id = B.bien_inventario_id
                       AND R.estado = 1
                       AND R.estado_proceso IN ('PROGRAMADO', 'EN_EJECUCION')
                 )
                THEN 1
                ELSE 0
            END
        ) AS disponible
    FROM [logistica].[BienInventario] B
    INNER JOIN [org].[UOT] U
        ON U.uot_id = B.uot_id
       AND U.estado = 1
    WHERE B.uot_id = @nUotResuelta
      AND B.estado = 1
      AND B.estado_bien <> 'BAJA'
    ORDER BY B.nombre, B.bien_inventario_id;

    SELECT
        S.suministro_id AS suministroId,
        S.uot_id AS uotId,
        U.codigo AS uotCodigo,
        U.nombre AS uotNombre,
        S.codigo,
        S.nombre,
        S.unidad_medida AS unidadMedida,
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
        ) AS requiereReposicion
    FROM [logistica].[Suministro] S
    INNER JOIN [org].[UOT] U
        ON U.uot_id = S.uot_id
       AND U.estado = 1
    LEFT JOIN [logistica].[SuministroSaldo] K
        ON K.suministro_id = S.suministro_id
    WHERE S.uot_id = @nUotResuelta
      AND S.estado = 1
    ORDER BY S.nombre, S.suministro_id;

    SELECT
        @bResultado = 1,
        @cMensaje = N'Disponibilidad consultada.',
        @cCodigoRespuesta = 'DISPONIBILIDAD_LISTADA',
        @nHttpRespuesta = 200;

    RETURN 0;
END;
GO
