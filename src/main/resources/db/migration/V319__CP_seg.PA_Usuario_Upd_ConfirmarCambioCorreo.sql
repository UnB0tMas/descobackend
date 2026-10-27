IF OBJECT_ID(N'[seg].[PA_Usuario_Upd_ConfirmarCambioCorreo]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Upd_ConfirmarCambioCorreo];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Upd_ConfirmarCambioCorreo
' Descripción             : Confirma el cambio de correo electrónico del usuario.
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
    EXEC [seg].[PA_Usuario_Upd_ConfirmarCambioCorreo]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Upd_ConfirmarCambioCorreo]
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
        @nDispositivoId BIGINT,
        @cCodigoHmacHex VARCHAR(128),
        @binCodigoHmac VARBINARY(64),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @nCodigoId BIGINT,
        @nCorreoNuevoId BIGINT,
        @nCorreoAnteriorId BIGINT,
        @cCorreoAnterior NVARCHAR(320),
        @cCorreoNuevo NVARCHAR(320),
        @bCodigoValido BIT,
        @cMensajeCodigo NVARCHAR(300),
        @nNotificacionId BIGINT,
        @nAuditoriaId BIGINT,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @bResultado = 0;
    SET @cMensaje = N'El codigo ingresado no es valido o ha expirado.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId,
        @cCodigoHmacHex = NULLIF(LTRIM(RTRIM(codigoHmacHex)), ''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        codigoHmacHex VARCHAR(128) '$.codigoHmacHex',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binCodigoHmac = TRY_CONVERT(VARBINARY(64), @cCodigoHmacHex, 2);

    IF @nUsuarioId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @binCodigoHmac IS NULL
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nSesionId = S.sesion_usuario_id,
        @nDispositivoId = S.dispositivo_usuario_id
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

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        EXEC [seg].[PA_Seguridad_Upd_ConsumirCodigoUnSoloUso]
             @nUsuarioId = @nUsuarioId,
             @cProposito = 'CAMBIO_CORREO',
             @binCodigoHmac = @binCodigoHmac,
             @cIp = @cIp,
             @gCorrelacionId = @gCorrelacionId,
             @nCodigoUnSoloUsoId = @nCodigoId OUTPUT,
             @nUsuarioCorreoSeguridadId = @nCorreoNuevoId OUTPUT,
             @bCodigoValido = @bCodigoValido OUTPUT,
             @cMensaje = @cMensajeCodigo OUTPUT;

        IF @bCodigoValido = 0
        BEGIN
            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            GOTO __DESCO_Salida;
        END;

        SELECT TOP (1)
            @nCorreoAnteriorId = UCS.usuario_correo_seguridad_id,
            @cCorreoAnterior = UCS.correo
        FROM [seg].[UsuarioCorreoSeguridad] UCS WITH (UPDLOCK, HOLDLOCK)
        WHERE UCS.usuario_id = @nUsuarioId
          AND UCS.estado = 1
          AND UCS.es_principal = 1
          AND UCS.fecha_hasta IS NULL
        ORDER BY UCS.fecha_desde DESC;

        SELECT
            @cCorreoNuevo = UCS.correo
        FROM [seg].[UsuarioCorreoSeguridad] UCS
        WHERE UCS.usuario_correo_seguridad_id = @nCorreoNuevoId
          AND UCS.usuario_id = @nUsuarioId
          AND UCS.estado = 1
          AND UCS.es_principal = 0;

        IF @cCorreoNuevo IS NULL
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
            SET @cMensaje = N'No se pudo confirmar el nuevo correo.';
            GOTO __DESCO_Salida;
        END;

        IF @nCorreoAnteriorId IS NOT NULL
        BEGIN
            UPDATE [seg].[UsuarioCorreoSeguridad]
            SET
                es_principal = 0,
                fecha_hasta = @dAhora,
                motivo_cambio = N'Reemplazado por nuevo correo validado.',
                estado = 0
            WHERE usuario_correo_seguridad_id = @nCorreoAnteriorId;
        END;

        UPDATE [seg].[UsuarioCorreoSeguridad]
        SET
            es_principal = 1,
            es_verificado = 1,
            fecha_verificacion = @dAhora,
            motivo_cambio = N'Correo confirmado por el usuario.'
        WHERE usuario_correo_seguridad_id = @nCorreoNuevoId
          AND usuario_id = @nUsuarioId
          AND estado = 1;

        IF @cCorreoAnterior IS NOT NULL
        BEGIN
            EXEC [seg].[PA_Seguridad_Ins_Notificacion]
                 @nUsuarioId = @nUsuarioId,
                 @cTipoNotificacion = 'CAMBIO_CORREO',
                 @cCorreoDestino = @cCorreoAnterior,
                 @cMetadata = NULL,
                 @gCorrelacionId = @gCorrelacionId,
                 @nNotificacionSeguridadId = @nNotificacionId OUTPUT;
        END;

        EXEC [seg].[PA_Seguridad_Ins_Notificacion]
             @nUsuarioId = @nUsuarioId,
             @cTipoNotificacion = 'CAMBIO_CORREO',
             @cCorreoDestino = @cCorreoNuevo,
             @cMetadata = NULL,
             @gCorrelacionId = @gCorrelacionId,
             @nNotificacionSeguridadId = @nNotificacionId OUTPUT;

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @nSesionUsuarioId = @nSesionId,
             @nDispositivoUsuarioId = @nDispositivoId,
             @cAccion = 'CAMBIAR_CORREO',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'UsuarioCorreoSeguridad',
             @cIdentificador = @nCorreoNuevoId,
             @cMotivo = N'Correo de seguridad actualizado.',
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint = N'/api/mi-cuenta/seguridad/correo/confirmar',
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Correo de seguridad actualizado correctamente.';
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
        SET @cMensaje = N'No se pudo confirmar el cambio de correo. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Upd_ConfirmarCambioCorreo',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_ConfirmarCambioCorreo',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_ConfirmarCambioCorreo',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Upd_ConfirmarCambioCorreo',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
