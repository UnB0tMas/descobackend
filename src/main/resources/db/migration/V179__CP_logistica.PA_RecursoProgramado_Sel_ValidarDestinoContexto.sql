IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Sel_ValidarDestinoContexto]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoContexto];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Sel_ValidarDestinoContexto
' Descripción             : Valida el contexto del destino de un recurso programado.
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
        @nUotDestino BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoContexto]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nCampaniaVentaId = 0,
        @nOperativoVentaId = 0,
        @nSalidaCampoId = 0,
        @nUotDestino = @nUotDestino OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUotDestino, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_RecursoProgramado_Sel_ValidarDestinoContexto]
    @nUsuarioId BIGINT,
    @nSesionUsuarioId BIGINT,
    @nCampaniaVentaId BIGINT = NULL,
    @nOperativoVentaId BIGINT = NULL,
    @nSalidaCampoId BIGINT = NULL,
    @nUotDestino BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60) = NULL OUTPUT,
    @nHttpRespuesta SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @nUotDestino = NULL,
        @bResultado = 0,
        @cMensaje = N'El destino seleccionado no está disponible.',
        @cCodigoRespuesta = 'DESTINO_NO_VALIDO',
        @nHttpRespuesta = 400;

    DECLARE @nCantidadDestinos TINYINT =
        (CASE WHEN @nCampaniaVentaId IS NULL THEN 0 ELSE 1 END)
        + (CASE WHEN @nOperativoVentaId IS NULL THEN 0 ELSE 1 END)
        + (CASE WHEN @nSalidaCampoId IS NULL THEN 0 ELSE 1 END);

    IF @nCantidadDestinos <> 1
    BEGIN
        SET @cMensaje = N'Seleccione un único destino.';
        RETURN 1;
    END;

    IF @nCampaniaVentaId IS NOT NULL
    BEGIN
        SELECT @nUotDestino = C.uot_id
        FROM [comercial].[CampaniaVenta] C
        WHERE C.campania_venta_id = @nCampaniaVentaId
          AND C.estado = 1
          AND C.estado_proceso IN ('PLANIFICACION', 'ACTIVA');
    END
    ELSE IF @nOperativoVentaId IS NOT NULL
    BEGIN
        SELECT @nUotDestino = C.uot_id
        FROM [comercial].[OperativoVenta] O
        INNER JOIN [comercial].[CampaniaVenta] C
            ON C.campania_venta_id = O.campania_venta_id
           AND C.estado = 1
           AND C.estado_proceso IN ('PLANIFICACION', 'ACTIVA')
        WHERE O.operativo_venta_id = @nOperativoVentaId
          AND O.estado = 1
          AND O.estado_proceso IN ('PLANIFICADO', 'EN_RECEPCION');
    END
    ELSE
    BEGIN
        SELECT @nUotDestino = S.uot_id
        FROM [campo].[SalidaCampo] S
        WHERE S.salida_campo_id = @nSalidaCampoId
          AND S.estado = 1
          AND S.estado_proceso IN ('BORRADOR', 'PROGRAMADA');
    END;

    IF @nUotDestino IS NULL
    BEGIN
        SET @cMensaje = N'El destino seleccionado ya no está disponible para programar recursos.';
        RETURN 1;
    END;

    DECLARE
        @nUotResuelta BIGINT = @nUotDestino,
        @bModoGeneral BIT,
        @bOk BIT,
        @cMsg NVARCHAR(300);

    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
        @nUsuarioId = @nUsuarioId,
        @nSesionUsuarioId = @nSesionUsuarioId,
        @nUotSolicitada = @nUotResuelta,
        @cCodigoPermiso = 'RECURSOS_CREAR',
        @bRequiereUot = 1,
        @nUotId = @nUotResuelta OUTPUT,
        @bModoGeneral = @bModoGeneral OUTPUT,
        @bResultado = @bOk OUTPUT,
        @cMensaje = @cMsg OUTPUT;

    IF ISNULL(@bOk, 0) = 0
    BEGIN
        SET @cMensaje = COALESCE(NULLIF(@cMsg, N''), @cMensaje);
        SET @nUotDestino = NULL;
        RETURN 1;
    END;

    SELECT
        @nUotDestino = @nUotResuelta,
        @bResultado = 1,
        @cMensaje = N'Destino validado.',
        @cCodigoRespuesta = 'DESTINO_VALIDO',
        @nHttpRespuesta = 200;

    RETURN 0;
END;
GO
