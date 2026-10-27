IF OBJECT_ID(N'[auditoria].[PA_Auditoria_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_Auditoria_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_Auditoria_Sel_Detalle
' Descripción             : Consulta el detalle de un evento de auditoría.
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
    EXEC [auditoria].[PA_Auditoria_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_Auditoria_Sel_Detalle](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS BEGIN
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el evento de auditoría.';
    EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='AUDITORIA_VER',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
DECLARE @nId BIGINT;
SELECT @nId=auditoriaEventoId FROM OPENJSON(@cJson,'$.auditoria') WITH(auditoriaEventoId BIGINT '$.auditoriaEventoId');
IF NOT EXISTS(SELECT 1 FROM auditoria.AuditoriaEvento WHERE auditoria_evento_id=@nId AND estado=1) BEGIN SET @cMensaje=N'El evento seleccionado no está disponible.';
GOTO __DESCO_Salida;
END;
SELECT AE.auditoria_evento_id auditoriaEventoId,AE.fecha_hora fechaHoraUtc,AE.accion,AE.esquema_entidad esquemaEntidad,AE.nombre_entidad nombreEntidad,AE.identificador,AE.datos_anteriores datosAnteriores,AE.datos_posteriores datosPosteriores,AE.motivo,AE.resultado,AE.endpoint,AE.ip,AE.correlacion_id correlacionId,AE.solicitud_id solicitudId,U.usuario_id usuarioId,U.nombre_usuario nombreUsuario,LTRIM(RTRIM(CONCAT(COALESCE(P.nombres,N''),N' ',COALESCE(P.apellido_paterno,N''),N' ',COALESCE(P.apellido_materno,N'')))) nombrePersona,M.codigo codigoModulo,M.nombre nombreModulo,S.sesion_publica_id sesionPublicaId,D.navegador,D.sistema_operativo sistemaOperativo,D.user_agent userAgent,D.es_reconocido dispositivoReconocido FROM auditoria.AuditoriaEvento AE LEFT JOIN seg.Usuario U ON U.usuario_id=AE.usuario_id LEFT JOIN org.Persona P ON P.persona_id=U.persona_id LEFT JOIN seg.Modulo M ON M.modulo_id=AE.modulo_id LEFT JOIN seg.SesionUsuario S ON S.sesion_usuario_id=AE.sesion_usuario_id LEFT JOIN seg.DispositivoUsuario D ON D.dispositivo_usuario_id=AE.dispositivo_usuario_id WHERE AE.auditoria_evento_id=@nId;
SELECT TE.transicion_estado_id transicionEstadoId,TE.campo_estado campoEstado,TE.estado_anterior estadoAnterior,TE.estado_nuevo estadoNuevo,TE.motivo,TE.fecha_hora fechaHoraUtc FROM auditoria.TransicionEstado TE INNER JOIN auditoria.AuditoriaEvento AE ON AE.auditoria_evento_id=@nId WHERE TE.estado=1 AND ((AE.correlacion_id IS NOT NULL AND TE.correlacion_id=AE.correlacion_id) OR (TE.esquema_entidad=AE.esquema_entidad AND TE.nombre_entidad=AE.nombre_entidad AND TE.identificador=AE.identificador AND ABS(DATEDIFF(SECOND,TE.fecha_hora,AE.fecha_hora))<=5)) ORDER BY TE.transicion_estado_id;
SET @bResultado=1;
SET @cMensaje=N'Evento consultado correctamente.';
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
    @cProcedimiento = N'auditoria.PA_Auditoria_Sel_Detalle',
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
    @cProcedimiento = N'auditoria.PA_Auditoria_Sel_Detalle',
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
FROM config.FN_RespuestaUsuario(N'auditoria.PA_Auditoria_Sel_Detalle',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
