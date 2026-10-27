IF OBJECT_ID(N'[config].[PA_Dashboard_Sel_Configuracion]', N'P') IS NOT NULL
    DROP PROCEDURE [config].[PA_Dashboard_Sel_Configuracion];
GO

/******************************************************************************************************
' Nombre del PA           : config.PA_Dashboard_Sel_Configuracion
' Descripción             : Consulta la configuración del panel de control.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Configuración
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    -- El JSON mostrado es ilustrativo y debe ajustarse al contrato del PA.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [config].[PA_Dashboard_Sel_Configuracion]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [config].[PA_Dashboard_Sel_Configuracion]
(
    @cJson NVARCHAR(MAX),
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;

    BEGIN TRY

    SET NOCOUNT ON;

    DECLARE
        @nUsuario BIGINT,
        @nSesion BIGINT,
        @nDisp BIGINT,
        @nEmp BIGINT,
        @nModulo INT,
        @gCorr UNIQUEIDENTIFIER,
        @gSol UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEnd NVARCHAR(250),
        @bCtx BIT,
        @cMsg NVARCHAR(300);

    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la configuración del dashboard.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson=@cJson,
        @cCodigoPermiso='INICIO_ADMINISTRAR',
        @nUsuarioId=@nUsuario OUTPUT,
        @nSesionUsuarioId=@nSesion OUTPUT,
        @nDispositivoUsuarioId=@nDisp OUTPUT,
        @nEmpleadoId=@nEmp OUTPUT,
        @nModuloId=@nModulo OUTPUT,
        @gCorrelacionId=@gCorr OUTPUT,
        @gSolicitudId=@gSol OUTPUT,
        @cIp=@cIp OUTPUT,
        @cEndpoint=@cEnd OUTPUT,
        @bResultado=@bCtx OUTPUT,
        @cMensaje=@cMsg OUTPUT;

    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    SELECT
        E.dashboard_elemento_id dashboardElementoId,
        E.codigo,
        E.tipo,
        E.titulo,
        E.subtitulo,
        P.codigo permisoRequerido,
        M.codigo codigoModulo,
        M.nombre nombreModulo,
        E.unidad,
        E.tipo_grafico tipoGrafico,
        E.permite_fechas permiteFechas,
        E.ancho,
        E.orden,
        E.estado
    FROM [config].[DashboardElemento] E
    INNER JOIN [seg].[Permiso] P
        ON P.permiso_id=E.permiso_id
    INNER JOIN [seg].[Modulo] M
        ON M.modulo_id=P.modulo_id
    ORDER BY E.tipo,E.orden,E.titulo;

    SELECT
        R.rol_id rolId,
        R.codigo codigoRol,
        R.nombre nombreRol,
        E.codigo codigoElemento,
        RE.visible,
        RE.orden
    FROM [config].[DashboardRolElemento] RE
    INNER JOIN [seg].[Rol] R
        ON R.rol_id=RE.rol_id
    INNER JOIN [config].[DashboardElemento] E
        ON E.dashboard_elemento_id=RE.dashboard_elemento_id
    WHERE R.estado=1
    ORDER BY R.nombre,COALESCE(RE.orden,E.orden),E.titulo;

    SELECT
        U.usuario_id usuarioId,
        U.nombre_usuario nombreUsuario,
        E.codigo codigoElemento,
        UE.visible,
        UE.orden
    FROM [config].[DashboardUsuarioElemento] UE
    INNER JOIN [seg].[Usuario] U
        ON U.usuario_id=UE.usuario_id
    INNER JOIN [config].[DashboardElemento] E
        ON E.dashboard_elemento_id=UE.dashboard_elemento_id
    WHERE U.estado=1
    ORDER BY U.nombre_usuario,COALESCE(UE.orden,E.orden),E.titulo;

    SET @bResultado=1;
    SET @cMensaje=N'Configuración del dashboard consultada correctamente.';

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Dashboard_Sel_Configuracion',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'config.PA_Dashboard_Sel_Configuracion',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'config.PA_Dashboard_Sel_Configuracion',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
