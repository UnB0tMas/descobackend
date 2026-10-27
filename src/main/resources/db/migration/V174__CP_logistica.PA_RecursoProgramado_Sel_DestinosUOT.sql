IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Sel_DestinosUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Sel_DestinosUOT];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Sel_DestinosUOT
' Descripción             : Consulta destinos de recursos programados por UOT.
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
    EXEC [logistica].[PA_RecursoProgramado_Sel_DestinosUOT]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @cTipo = '',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_RecursoProgramado_Sel_DestinosUOT]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nUotId BIGINT = NULL,
    @cTipo VARCHAR(20) = NULL,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudieron consultar los destinos.',
        @cCodigoRespuesta = 'DESTINOS_NO_LISTADOS',
        @nHttpRespuesta = 400;

    SET @cTipo = UPPER(NULLIF(LTRIM(RTRIM(@cTipo)), ''));

    IF @cTipo IS NOT NULL
       AND @cTipo NOT IN ('CAMPANIA', 'OPERATIVO', 'SALIDA')
    BEGIN
        SET @cMensaje = N'El tipo de destino no es válido.';
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
        @cCodigoPermiso = 'RECURSOS_VER',
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

    ;WITH Destinos AS
    (
        SELECT
            CAST('CAMPANIA' AS VARCHAR(20)) AS tipo,
            C.campania_venta_id AS destinoId,
            C.uot_id AS uotId,
            U.codigo AS uotCodigo,
            U.nombre AS uotNombre,
            C.codigo AS codigo,
            C.nombre AS nombre,
            C.estado_proceso AS estadoProceso,
            CONVERT(DATETIME2(0), C.fecha_inicio) AS fechaReferencia,
            C.observacion AS descripcion
        FROM [comercial].[CampaniaVenta] C
        INNER JOIN [org].[UOT] U
            ON U.uot_id = C.uot_id
           AND U.estado = 1
        WHERE C.estado = 1
          AND C.estado_proceso IN ('PLANIFICACION', 'ACTIVA')

        UNION ALL

        SELECT
            CAST('OPERATIVO' AS VARCHAR(20)),
            O.operativo_venta_id,
            C.uot_id,
            U.codigo,
            U.nombre,
            O.codigo,
            CONCAT(C.nombre, N' · ', O.codigo),
            O.estado_proceso,
            O.fecha_inicio_programada,
            O.observacion
        FROM [comercial].[OperativoVenta] O
        INNER JOIN [comercial].[CampaniaVenta] C
            ON C.campania_venta_id = O.campania_venta_id
           AND C.estado = 1
           AND C.estado_proceso IN ('PLANIFICACION', 'ACTIVA')
        INNER JOIN [org].[UOT] U
            ON U.uot_id = C.uot_id
           AND U.estado = 1
        WHERE O.estado = 1
          AND O.estado_proceso IN ('PLANIFICADO', 'EN_RECEPCION')

        UNION ALL

        SELECT
            CAST('SALIDA' AS VARCHAR(20)),
            S.salida_campo_id,
            S.uot_id,
            U.codigo,
            U.nombre,
            CONCAT('SAL-', S.salida_campo_id),
            CONCAT(
                M.nombre,
                N' · ',
                CONVERT(VARCHAR(16), S.fecha_hora_programada, 120)
            ),
            S.estado_proceso,
            S.fecha_hora_programada,
            S.descripcion
        FROM [campo].[SalidaCampo] S
        INNER JOIN [campo].[MotivoSalida] M
            ON M.motivo_salida_id = S.motivo_salida_id
           AND M.estado = 1
        INNER JOIN [org].[UOT] U
            ON U.uot_id = S.uot_id
           AND U.estado = 1
        WHERE S.estado = 1
          AND S.uot_id IS NOT NULL
          AND S.estado_proceso IN ('BORRADOR', 'PROGRAMADA')
    )
    SELECT
        D.tipo,
        D.destinoId,
        D.uotId,
        D.uotCodigo,
        D.uotNombre,
        D.codigo,
        D.nombre,
        D.estadoProceso,
        D.fechaReferencia,
        D.descripcion
    FROM Destinos D
    WHERE
        (@cTipo IS NULL OR D.tipo = @cTipo)
        AND
        (
            (@bModoGeneral = 0 AND D.uotId = @nUotResuelta)
            OR
            (
                @bModoGeneral = 1
                AND (@nUotResuelta IS NULL OR D.uotId = @nUotResuelta)
                AND [seg].[FN_Usuario_TienePermisoUOT](
                    @nUsuarioId,
                    D.uotId,
                    'RECURSOS_VER'
                ) = 1
            )
        )
    ORDER BY D.uotNombre, D.tipo, D.fechaReferencia DESC, D.nombre;

    SELECT
        @bResultado = 1,
        @cMensaje = N'Destinos consultados.',
        @cCodigoRespuesta = 'DESTINOS_LISTADOS',
        @nHttpRespuesta = 200;

    RETURN 0;
END;
GO
