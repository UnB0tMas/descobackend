IF OBJECT_ID(N'[seg].[PA_Dispositivo_Upd_Reconocimiento]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Dispositivo_Upd_Reconocimiento];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Dispositivo_Upd_Reconocimiento
' Descripción             : Actualiza el reconocimiento de un dispositivo.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Seguridad
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
    EXEC [seg].[PA_Dispositivo_Upd_Reconocimiento]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Dispositivo_Upd_Reconocimiento]
(
    @cJson       NVARCHAR(MAX),
    @bResultado  BIT OUTPUT,
    @cMensaje    NVARCHAR(300) OUTPUT,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @nUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @nSesionId BIGINT,
        @nDispositivoActualId BIGINT,
        @nDispositivoObjetivoId BIGINT,
        @cAccion VARCHAR(20),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @cAccionAuditoria VARCHAR(40),
        @cMotivoAuditoria NVARCHAR(500),
        @nAuditoriaId BIGINT;

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo actualizar el dispositivo.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId,
        @nDispositivoObjetivoId = dispositivoUsuarioId,
        @cAccion = UPPER(NULLIF(LTRIM(RTRIM(accion)), '')),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        dispositivoUsuarioId BIGINT '$.dispositivoUsuarioId',
        accion VARCHAR(20) '$.accion',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    IF @nUsuarioId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @nDispositivoObjetivoId IS NULL
       OR @cAccion NOT IN ('RECONOCER','QUITAR')
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nSesionId = S.sesion_usuario_id,
        @nDispositivoActualId = S.dispositivo_usuario_id
    FROM [seg].[SesionUsuario] S
    INNER JOIN [seg].[Usuario] U ON U.usuario_id = S.usuario_id
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.usuario_id = @nUsuarioId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > @dAhora
      AND S.token_version = U.token_version
      AND U.estado = 1
      AND U.estado_cuenta = 'ACTIVA';

    IF @nSesionId IS NULL
    BEGIN
        SET @cMensaje = N'La sesion no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [seg].[DispositivoUsuario]
        WHERE dispositivo_usuario_id = @nDispositivoObjetivoId
          AND usuario_id = @nUsuarioId
          AND estado = 1
    )
    BEGIN
        SET @cMensaje = N'El dispositivo seleccionado no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    IF @cAccion = 'RECONOCER'
       AND @nDispositivoActualId <> @nDispositivoObjetivoId
    BEGIN
        SET @cMensaje = N'Solo puede reconocer el dispositivo que esta utilizando actualmente.';
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        IF @cAccion = 'RECONOCER'
        BEGIN
            UPDATE [seg].[DispositivoUsuario]
            SET
                es_reconocido = 1,
                fecha_reconocimiento = @dAhora,
                fecha_retiro_reconocimiento = NULL
            WHERE dispositivo_usuario_id = @nDispositivoObjetivoId
              AND usuario_id = @nUsuarioId
              AND estado = 1;
        END
        ELSE
        BEGIN
            UPDATE [seg].[DispositivoUsuario]
            SET
                es_reconocido = 0,
                fecha_retiro_reconocimiento = @dAhora
            WHERE dispositivo_usuario_id = @nDispositivoObjetivoId
              AND usuario_id = @nUsuarioId
              AND estado = 1;
        END;

        IF @cAccion = 'RECONOCER'
        BEGIN
            SET @cAccionAuditoria = 'RECONOCER_DISPOSITIVO';
            SET @cMotivoAuditoria = N'Dispositivo marcado como reconocido por el usuario.';
        END
        ELSE
        BEGIN
            SET @cAccionAuditoria = 'QUITAR_RECONOCIMIENTO';
            SET @cMotivoAuditoria = N'Reconocimiento retirado por el usuario.';
        END;

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @nSesionUsuarioId = @nSesionId,
             @nDispositivoUsuarioId = @nDispositivoActualId,
             @cAccion = @cAccionAuditoria,
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'DispositivoUsuario',
             @cIdentificador = @nDispositivoObjetivoId,
             @cMotivo = @cMotivoAuditoria,
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint = N'/api/mi-cuenta/dispositivos/reconocimiento',
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje =
            CASE WHEN @cAccion = 'RECONOCER'
                 THEN N'Dispositivo reconocido correctamente.'
                 ELSE N'Reconocimiento retirado correctamente.' END;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE() <> 0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo actualizar el dispositivo. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Dispositivo_Upd_Reconocimiento',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

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
    @cProcedimiento = N'seg.PA_Dispositivo_Upd_Reconocimiento',
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
    @cProcedimiento = N'seg.PA_Dispositivo_Upd_Reconocimiento',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Dispositivo_Upd_Reconocimiento',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
