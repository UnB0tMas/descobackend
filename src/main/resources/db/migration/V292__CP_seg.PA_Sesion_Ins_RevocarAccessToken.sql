IF OBJECT_ID(N'[seg].[PA_Sesion_Ins_RevocarAccessToken]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Sesion_Ins_RevocarAccessToken];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Sesion_Ins_RevocarAccessToken
' Descripción             : Registra la revocación de un token de acceso.
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
    EXEC [seg].[PA_Sesion_Ins_RevocarAccessToken]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Sesion_Ins_RevocarAccessToken]
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
        @nDispositivoUsuarioId BIGINT,
        @cJtiHashHex VARCHAR(128),
        @binJtiHash VARBINARY(64),
        @dExpiracionToken DATETIME2(0),
        @cMotivo NVARCHAR(300),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @nTokenAccesoRevocadoId BIGINT,
        @nAuditoriaEventoId BIGINT,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo revocar el acceso.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId,
        @cJtiHashHex = NULLIF(LTRIM(RTRIM(jtiHashHex)), ''),
        @dExpiracionToken = fechaExpiracionTokenUtc,
        @cMotivo = NULLIF(LTRIM(RTRIM(motivo)), ''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        jtiHashHex VARCHAR(128) '$.jtiHashHex',
        fechaExpiracionTokenUtc DATETIME2(0) '$.fechaExpiracionTokenUtc',
        motivo NVARCHAR(300) '$.motivo',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binJtiHash = TRY_CONVERT(VARBINARY(64), @cJtiHashHex, 2);

    IF @nUsuarioId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @binJtiHash IS NULL
       OR @dExpiracionToken IS NULL
       OR @dExpiracionToken <= @dAhora
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    /*
       Solo una sesion autentica y vigente puede revocar uno de sus access tokens.
       La validacion criptografica del JWT se realiza previamente en el backend.
    */
    SELECT
        @nSesionId = S.sesion_usuario_id,
        @nDispositivoUsuarioId = S.dispositivo_usuario_id
    FROM [seg].[SesionUsuario] S
    INNER JOIN [seg].[Usuario] U
            ON U.usuario_id = S.usuario_id
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

        SELECT
            @nTokenAccesoRevocadoId = TAR.token_acceso_revocado_id
        FROM [seg].[TokenAccesoRevocado] TAR WITH (UPDLOCK, HOLDLOCK)
        WHERE TAR.jti_hash = @binJtiHash;

        IF @nTokenAccesoRevocadoId IS NULL
        BEGIN
            INSERT INTO [seg].[TokenAccesoRevocado]
            (
                sesion_usuario_id,
                jti_hash,
                fecha_revocacion,
                fecha_expiracion_token,
                motivo,
                estado
            )
            VALUES
            (
                @nSesionId,
                @binJtiHash,
                @dAhora,
                @dExpiracionToken,
                COALESCE(@cMotivo, N'Revocacion puntual de token de acceso.'),
                1
            );

            SET @nTokenAccesoRevocadoId = CONVERT(BIGINT, SCOPE_IDENTITY());
        END;

        /*
           Se audita el acto de revocacion, no el JTI ni su hash.
           PA_Auditoria_Ins_Evento bloquea adicionalmente payloads sensibles.
        */
        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @nSesionUsuarioId = @nSesionId,
             @nDispositivoUsuarioId = @nDispositivoUsuarioId,
             @cAccion = 'REVOCAR_ACCESS_TOKEN',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'TokenAccesoRevocado',
             @cIdentificador = @nTokenAccesoRevocadoId,
             @cMotivo = @cMotivo,
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint = N'/api/auth/logout-token',
             @nAuditoriaEventoId = @nAuditoriaEventoId OUTPUT;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Acceso revocado correctamente.';
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE() <> 0
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
        SET @cMensaje = N'No se pudo revocar el acceso. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Sesion_Ins_RevocarAccessToken',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
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
    @cProcedimiento = N'seg.PA_Sesion_Ins_RevocarAccessToken',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
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
    @cProcedimiento = N'seg.PA_Sesion_Ins_RevocarAccessToken',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Sesion_Ins_RevocarAccessToken',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
