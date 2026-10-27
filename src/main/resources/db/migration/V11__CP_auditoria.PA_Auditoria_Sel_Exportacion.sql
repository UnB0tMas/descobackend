IF OBJECT_ID(N'[auditoria].[PA_Auditoria_Sel_Exportacion]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_Auditoria_Sel_Exportacion];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_Auditoria_Sel_Exportacion
' Descripción             : Consulta los datos de auditoría preparados para exportación.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Auditoría
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [auditoria].[PA_Auditoria_Sel_Exportacion]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_Auditoria_Sel_Exportacion]
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
        @cMsg NVARCHAR(300),
        @dDesde DATETIME2(0),
        @dHasta DATETIME2(0),
        @nUsuarioFiltro BIGINT,
        @nModuloFiltro INT,
        @cAccion VARCHAR(40),
        @cEsq SYSNAME,
        @cEnt SYSNAME,
        @cResultado VARCHAR(20);

    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudo preparar la auditoría para exportación.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson=@cJson,
        @cCodigoPermiso='AUDITORIA_EXPORTAR',
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

    IF ISNULL(@bCtx,0)=0
    BEGIN
        SET @cMensaje=COALESCE(@cMsg,N'No cuenta con autorización para exportar la auditoría.');
        GOTO __DESCO_Salida;
    END;

    SELECT
        @dDesde=fechaDesde,
        @dHasta=fechaHasta,
        @nUsuarioFiltro=usuarioId,
        @nModuloFiltro=moduloId,
        @cAccion=UPPER(NULLIF(LTRIM(RTRIM(accion)),'')),
        @cEsq=NULLIF(LTRIM(RTRIM(esquemaEntidad)),N''),
        @cEnt=NULLIF(LTRIM(RTRIM(nombreEntidad)),N''),
        @cResultado=UPPER(NULLIF(LTRIM(RTRIM(resultado)),''))
    FROM OPENJSON(@cJson,'$.filtros')
    WITH
    (
        fechaDesde DATETIME2(0) '$.fechaDesde',
        fechaHasta DATETIME2(0) '$.fechaHasta',
        usuarioId BIGINT '$.usuarioId',
        moduloId INT '$.moduloId',
        accion VARCHAR(40) '$.accion',
        esquemaEntidad SYSNAME '$.esquemaEntidad',
        nombreEntidad SYSNAME '$.nombreEntidad',
        resultado VARCHAR(20) '$.resultado'
    );

    IF @dDesde IS NOT NULL AND @dHasta IS NOT NULL AND @dHasta<@dDesde
    BEGIN
        SET @cMensaje=N'El rango de fechas seleccionado no es válido.';
        GOTO __DESCO_Salida;
    END;

    IF @nUsuarioFiltro IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [seg].[Usuario]
           WHERE usuario_id=@nUsuarioFiltro
       )
    BEGIN
        SET @cMensaje=N'El usuario seleccionado no está disponible para la consulta.';
        GOTO __DESCO_Salida;
    END;

    IF @nModuloFiltro IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [seg].[Modulo]
           WHERE modulo_id=@nModuloFiltro
             AND estado=1
       )
    BEGIN
        SET @cMensaje=N'El módulo seleccionado no está disponible para la consulta.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        AE.auditoria_evento_id AS auditoriaEventoId,
        AE.fecha_hora AS fechaHoraUtc,
        AE.usuario_id AS usuarioId,
        U.nombre_usuario AS nombreUsuario,
        LTRIM(RTRIM(CONCAT(
            COALESCE(P.nombres,N''),N' ',
            COALESCE(P.apellido_paterno,N''),N' ',
            COALESCE(P.apellido_materno,N'')
        ))) AS nombrePersona,
        AE.modulo_id AS moduloId,
        M.codigo AS codigoModulo,
        M.nombre AS modulo,
        AE.accion,
        AE.esquema_entidad AS esquemaEntidad,
        AE.nombre_entidad AS nombreEntidad,
        AE.identificador,
        AE.motivo,
        AE.resultado,
        AE.endpoint,
        AE.ip,
        AE.sesion_usuario_id AS sesionUsuarioId,
        S.sesion_publica_id AS sesionPublicaId,
        AE.dispositivo_usuario_id AS dispositivoUsuarioId,
        D.navegador,
        D.sistema_operativo AS sistemaOperativo,
        D.es_reconocido AS dispositivoReconocido,
        AE.correlacion_id AS correlacionId,
        AE.solicitud_id AS solicitudId
    FROM [auditoria].[AuditoriaEvento] AE
    LEFT JOIN [seg].[Usuario] U
        ON U.usuario_id=AE.usuario_id
    LEFT JOIN [org].[Persona] P
        ON P.persona_id=U.persona_id
    LEFT JOIN [seg].[Modulo] M
        ON M.modulo_id=AE.modulo_id
    LEFT JOIN [seg].[SesionUsuario] S
        ON S.sesion_usuario_id=AE.sesion_usuario_id
    LEFT JOIN [seg].[DispositivoUsuario] D
        ON D.dispositivo_usuario_id=AE.dispositivo_usuario_id
    WHERE AE.estado=1
      AND (@dDesde IS NULL OR AE.fecha_hora>=@dDesde)
      AND (@dHasta IS NULL OR AE.fecha_hora<=@dHasta)
      AND (@nUsuarioFiltro IS NULL OR AE.usuario_id=@nUsuarioFiltro)
      AND (@nModuloFiltro IS NULL OR AE.modulo_id=@nModuloFiltro)
      AND (@cAccion IS NULL OR AE.accion=@cAccion)
      AND (@cEsq IS NULL OR AE.esquema_entidad=@cEsq)
      AND (@cEnt IS NULL OR AE.nombre_entidad=@cEnt)
      AND (@cResultado IS NULL OR AE.resultado=@cResultado)
    ORDER BY AE.fecha_hora DESC,AE.auditoria_evento_id DESC;

    SET @bResultado=1;
    SET @cMensaje=N'Información de auditoría preparada para exportación.';

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
    @cProcedimiento = N'auditoria.PA_Auditoria_Sel_Exportacion',
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
    @cProcedimiento = N'auditoria.PA_Auditoria_Sel_Exportacion',
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
FROM config.FN_RespuestaUsuario(N'auditoria.PA_Auditoria_Sel_Exportacion',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
