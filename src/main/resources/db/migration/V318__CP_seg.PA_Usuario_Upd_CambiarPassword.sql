IF OBJECT_ID(N'[seg].[PA_Usuario_Upd_CambiarPassword]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Upd_CambiarPassword];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Upd_CambiarPassword
' Descripción             : Actualiza la contraseña del usuario.
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
    EXEC [seg].[PA_Usuario_Upd_CambiarPassword]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Upd_CambiarPassword]
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
        @nSesionUsuarioId BIGINT,
        @nDispositivoId BIGINT,
        @cNuevoPasswordHash VARCHAR(512),
        @cHashAnterior VARCHAR(512),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nSesionesRevocadas INT,
        @nNotificacionId BIGINT,
        @nAuditoriaId BIGINT,
        @cCorreoDestino NVARCHAR(320);

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo actualizar la contrasena.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId,
        @cNuevoPasswordHash = NULLIF(LTRIM(RTRIM(nuevoPasswordHash)), ''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        nuevoPasswordHash VARCHAR(512) '$.nuevoPasswordHash',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    IF @nUsuarioId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @cNuevoPasswordHash IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nSesionUsuarioId = S.sesion_usuario_id,
        @nDispositivoId = S.dispositivo_usuario_id,
        @cHashAnterior = U.password_hash
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

    IF @nSesionUsuarioId IS NULL
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

        IF NOT EXISTS
        (
            SELECT 1
            FROM [seg].[HistorialPassword]
            WHERE usuario_id = @nUsuarioId
              AND estado = 1
              AND fecha_hasta IS NULL
        )
        AND @cHashAnterior IS NOT NULL
        BEGIN
            INSERT INTO [seg].[HistorialPassword]
            (
                usuario_id, password_hash, fecha_desde, fecha_hasta,
                cambiado_por_usuario_id, motivo, estado
            )
            SELECT
                U.usuario_id,
                U.password_hash,
                COALESCE(U.fecha_cambio_password, U.fecha_creacion),
                @dAhora,
                @nUsuarioId,
                N'Version anterior al cambio de contrasena.',
                0
            FROM [seg].[Usuario] U
            WHERE U.usuario_id = @nUsuarioId;
        END
        ELSE
        BEGIN
            UPDATE [seg].[HistorialPassword]
            SET fecha_hasta = COALESCE(fecha_hasta, @dAhora),
                estado = 0
            WHERE usuario_id = @nUsuarioId
              AND estado = 1
              AND fecha_hasta IS NULL;
        END;

        INSERT INTO [seg].[HistorialPassword]
        (
            usuario_id,
            password_hash,
            fecha_desde,
            cambiado_por_usuario_id,
            motivo,
            estado
        )
        VALUES
        (
            @nUsuarioId,
            @cNuevoPasswordHash,
            @dAhora,
            @nUsuarioId,
            N'Cambio de contrasena por el usuario.',
            1
        );

        UPDATE [seg].[Usuario]
        SET
            password_hash = @cNuevoPasswordHash,
            fecha_cambio_password = @dAhora,
            requiere_cambio_password = 0
        WHERE usuario_id = @nUsuarioId;

        EXEC [seg].[PA_Seguridad_Upd_RevocarSesionesUsuario]
             @nUsuarioId = @nUsuarioId,
             @cMotivo = N'Cambio de contrasena.',
             @nSesionExcluirId = NULL,
             @bIncrementarTokenVersion = 1,
             @nCantidadSesionesRevocadas = @nSesionesRevocadas OUTPUT;

        SELECT TOP (1)
            @cCorreoDestino = UCS.correo
        FROM [seg].[UsuarioCorreoSeguridad] UCS
        WHERE UCS.usuario_id = @nUsuarioId
          AND UCS.estado = 1
          AND UCS.es_principal = 1
          AND UCS.es_verificado = 1
          AND UCS.fecha_hasta IS NULL
        ORDER BY UCS.fecha_desde DESC;

        IF @cCorreoDestino IS NOT NULL
        BEGIN
            EXEC [seg].[PA_Seguridad_Ins_Notificacion]
                 @nUsuarioId = @nUsuarioId,
                 @cTipoNotificacion = 'CAMBIO_PASSWORD',
                 @cCorreoDestino = @cCorreoDestino,
                 @cMetadata = NULL,
                 @gCorrelacionId = @gCorrelacionId,
                 @nNotificacionSeguridadId = @nNotificacionId OUTPUT;
        END;

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @nSesionUsuarioId = @nSesionUsuarioId,
             @nDispositivoUsuarioId = @nDispositivoId,
             @cAccion = 'CAMBIAR_PASSWORD',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'Usuario',
             @cIdentificador = @nUsuarioId,
             @cMotivo = N'Contrasena cambiada por el usuario.',
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint = N'/api/mi-cuenta/seguridad/cambiar-password',
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Contrasena actualizada correctamente. Inicie sesion nuevamente.';
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
        SET @cMensaje = N'No se pudo actualizar la contrasena. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Upd_CambiarPassword',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_CambiarPassword',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_CambiarPassword',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Upd_CambiarPassword',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
