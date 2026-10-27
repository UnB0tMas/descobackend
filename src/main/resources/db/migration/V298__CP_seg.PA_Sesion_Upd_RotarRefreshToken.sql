IF OBJECT_ID(N'[seg].[PA_Sesion_Upd_RotarRefreshToken]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Sesion_Upd_RotarRefreshToken];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Sesion_Upd_RotarRefreshToken
' Descripción             : Rota el token de actualización de una sesión.
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
        @nUsuarioId BIGINT,
        @nTokenVersion INT,
        @dExpiracionRenovacion DATETIME2(0),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Sesion_Upd_RotarRefreshToken]
        @cJson = N'{}',
        @nUsuarioId = @nUsuarioId OUTPUT,
        @nTokenVersion = @nTokenVersion OUTPUT,
        @dExpiracionRenovacion = @dExpiracionRenovacion OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUsuarioId, @nTokenVersion, @dExpiracionRenovacion, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Sesion_Upd_RotarRefreshToken]
(
    @cJson                   NVARCHAR(MAX),
    @nUsuarioId              BIGINT OUTPUT,
    @nTokenVersion           INT OUTPUT,
    @dExpiracionRenovacion   DATETIME2(0) OUTPUT,
    @bResultado              BIT OUTPUT,
    @cMensaje                NVARCHAR(300) OUTPUT,
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
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @cTokenActualHashHex VARCHAR(128),
        @binTokenActualHash VARBINARY(64),
        @cTokenNuevoHashHex VARCHAR(128),
        @binTokenNuevoHash VARBINARY(64),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nSesionId BIGINT,
        @nRefreshActualId BIGINT,
        @nRefreshNuevoId BIGINT,
        @bTokenActualActivo BIT,
        @nDispositivoId BIGINT,
        @nAuditoriaId BIGINT;

    SET @nUsuarioId = NULL;
    SET @nTokenVersion = NULL;
    SET @dExpiracionRenovacion = NULL;
    SET @bResultado = 0;
    SET @cMensaje = N'La sesion ya no esta disponible. Inicie sesion nuevamente.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT
        @gSesionPublicaId = sesionPublicaId,
        @cTokenActualHashHex = NULLIF(LTRIM(RTRIM(refreshTokenActualHashHex)), ''),
        @cTokenNuevoHashHex = NULLIF(LTRIM(RTRIM(refreshTokenNuevoHashHex)), ''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        refreshTokenActualHashHex VARCHAR(128) '$.refreshTokenActualHashHex',
        refreshTokenNuevoHashHex VARCHAR(128) '$.refreshTokenNuevoHashHex',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binTokenActualHash = TRY_CONVERT(VARBINARY(64), @cTokenActualHashHex, 2);
    SET @binTokenNuevoHash = TRY_CONVERT(VARBINARY(64), @cTokenNuevoHashHex, 2);

    IF @gSesionPublicaId IS NULL
       OR @binTokenActualHash IS NULL
       OR @binTokenNuevoHash IS NULL
       OR @binTokenActualHash = @binTokenNuevoHash
    BEGIN
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        SELECT
            @nSesionId = S.sesion_usuario_id,
            @nUsuarioId = S.usuario_id,
            @nTokenVersion = U.token_version,
            @dExpiracionRenovacion = S.fecha_expiracion_renovacion,
            @nDispositivoId = S.dispositivo_usuario_id
        FROM [seg].[SesionUsuario] S WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN [seg].[Usuario] U
            ON U.usuario_id = S.usuario_id
        INNER JOIN [org].[Empleado] E
            ON E.empleado_id = U.persona_id
        WHERE S.sesion_publica_id = @gSesionPublicaId
          AND S.estado = 1
          AND S.fecha_revocacion IS NULL
          AND S.fecha_expiracion_renovacion > @dAhora
          AND S.token_version = U.token_version
          AND U.estado = 1
          AND U.estado_cuenta = 'ACTIVA'
          AND (U.bloqueado_hasta IS NULL OR U.bloqueado_hasta <= @dAhora)
          AND E.estado = 1;

        IF @nSesionId IS NULL
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
            SET @nUsuarioId = NULL;
            SET @nTokenVersion = NULL;
            SET @dExpiracionRenovacion = NULL;
            GOTO __DESCO_Salida;
        END;

        SELECT
            @nRefreshActualId = RT.refresh_token_sesion_id,
            @bTokenActualActivo =
                CASE
                    WHEN RT.estado = 1
                     AND RT.fecha_uso IS NULL
                     AND RT.fecha_revocacion IS NULL
                     AND RT.fecha_expiracion > @dAhora
                    THEN 1 ELSE 0
                END
        FROM [seg].[RefreshTokenSesion] RT WITH (UPDLOCK, HOLDLOCK)
        WHERE RT.sesion_usuario_id = @nSesionId
          AND RT.token_hash = @binTokenActualHash;

        IF @nRefreshActualId IS NULL OR ISNULL(@bTokenActualActivo, 0) = 0
        BEGIN
            /*
               El token no corresponde o ya fue usado: se trata como posible
               replay y se revoca la sesion completa.
            */
            UPDATE [seg].[SesionUsuario]
            SET
                fecha_revocacion = COALESCE(fecha_revocacion, @dAhora),
                motivo_revocacion = COALESCE(motivo_revocacion, N'Reutilizacion o token de renovacion no valido.'),
                estado = 0
            WHERE sesion_usuario_id = @nSesionId;

            UPDATE [seg].[RefreshTokenSesion]
            SET
                fecha_revocacion = COALESCE(fecha_revocacion, @dAhora),
                motivo_revocacion = COALESCE(motivo_revocacion, N'Reutilizacion o token de renovacion no valido.'),
                estado = 0
            WHERE sesion_usuario_id = @nSesionId
              AND estado = 1;

            EXEC [auditoria].[PA_Auditoria_Ins_Evento]
                 @nUsuarioId = @nUsuarioId,
                 @nSesionUsuarioId = @nSesionId,
                 @nDispositivoUsuarioId = @nDispositivoId,
                 @cAccion = 'REFRESH_TOKEN_RECHAZADO',
                 @cEsquemaEntidad = N'seg',
                 @cNombreEntidad = N'SesionUsuario',
                 @cIdentificador = @gSesionPublicaId,
                 @cMotivo = N'Se revoco la sesion por un token de renovacion no valido o reutilizado.',
                 @cIp = @cIp,
                 @cResultado = 'RECHAZADO',
                 @gCorrelacionId = @gCorrelacionId,
                 @cEndpoint = N'/api/auth/refresh',
                 @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

            SET @nUsuarioId = NULL;
            SET @nTokenVersion = NULL;
            SET @dExpiracionRenovacion = NULL;
            SET @cMensaje = N'La sesion ya no esta disponible. Inicie sesion nuevamente.';
            GOTO __DESCO_Salida;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM [seg].[RefreshTokenSesion]
            WHERE token_hash = @binTokenNuevoHash
        )
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

            SET @nUsuarioId = NULL;
            SET @nTokenVersion = NULL;
            SET @dExpiracionRenovacion = NULL;
            SET @cMensaje = N'No se pudo renovar la sesion. Intente nuevamente.';
            GOTO __DESCO_Salida;
        END;

        INSERT INTO [seg].[RefreshTokenSesion]
        (
            sesion_usuario_id,
            token_hash,
            token_padre_id,
            fecha_emision,
            fecha_expiracion,
            estado
        )
        VALUES
        (
            @nSesionId,
            @binTokenNuevoHash,
            @nRefreshActualId,
            @dAhora,
            @dExpiracionRenovacion,
            1
        );

        SET @nRefreshNuevoId = SCOPE_IDENTITY();

        UPDATE [seg].[RefreshTokenSesion]
        SET
            fecha_uso = @dAhora,
            token_reemplazo_id = @nRefreshNuevoId,
            estado = 0
        WHERE refresh_token_sesion_id = @nRefreshActualId
          AND estado = 1
          AND fecha_uso IS NULL
          AND fecha_revocacion IS NULL;

        IF @@ROWCOUNT <> 1
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

            SET @nUsuarioId = NULL;
            SET @nTokenVersion = NULL;
            SET @dExpiracionRenovacion = NULL;
            SET @cMensaje = N'La sesion ya no esta disponible. Inicie sesion nuevamente.';
            GOTO __DESCO_Salida;
        END;

        UPDATE [seg].[SesionUsuario]
        SET
            fecha_ultima_actividad = @dAhora,
            ip_ultima_actividad = COALESCE(@cIp, ip_ultima_actividad)
        WHERE sesion_usuario_id = @nSesionId;

        IF @nDispositivoId IS NOT NULL
        BEGIN
            UPDATE [seg].[DispositivoUsuario]
            SET
                fecha_ultima_actividad = @dAhora,
                ultima_ip = COALESCE(@cIp, ultima_ip)
            WHERE dispositivo_usuario_id = @nDispositivoId;
        END;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Sesion renovada correctamente.';
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

        SET @nUsuarioId = NULL;
        SET @nTokenVersion = NULL;
        SET @dExpiracionRenovacion = NULL;
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo renovar la sesion. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Sesion_Upd_RotarRefreshToken',
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
    @cProcedimiento = N'seg.PA_Sesion_Upd_RotarRefreshToken',
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
    @cProcedimiento = N'seg.PA_Sesion_Upd_RotarRefreshToken',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Sesion_Upd_RotarRefreshToken',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
