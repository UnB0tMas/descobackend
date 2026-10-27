IF OBJECT_ID(N'[seg].[PA_Seguridad_Upd_RevocarSesionesUsuario]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Seguridad_Upd_RevocarSesionesUsuario];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Seguridad_Upd_RevocarSesionesUsuario
' Descripción             : Revoca las sesiones activas de un usuario.
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
    DECLARE
        @nCantidadSesionesRevocadas INT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Seguridad_Upd_RevocarSesionesUsuario]
        @nUsuarioId = 0,
        @cMotivo = N'',
        @nSesionExcluirId = 0,
        @bIncrementarTokenVersion = 0,
        @nCantidadSesionesRevocadas = @nCantidadSesionesRevocadas OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nCantidadSesionesRevocadas, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Seguridad_Upd_RevocarSesionesUsuario]
(
    @nUsuarioId                   BIGINT,
    @cMotivo                      NVARCHAR(300),
    @nSesionExcluirId             BIGINT = NULL,
    @bIncrementarTokenVersion     BIT = 1,
    @nCantidadSesionesRevocadas   INT OUTPUT,
    @bResultado BIT=NULL OUTPUT,
    @cMensaje NVARCHAR(300)=NULL OUTPUT,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    SET @bResultado=0;
BEGIN TRY
BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

    /* DESCO_SEGURIDAD_2FA_DISPOSITIVO_V3_20260904 */
    SET NOCOUNT ON;

    DECLARE
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nDispositivoExcluirId BIGINT;

    DECLARE @DispositivosRevocados TABLE
    (
        dispositivo_usuario_id BIGINT PRIMARY KEY
    );

    SET @nCantidadSesionesRevocadas = 0;
    SET @cMotivo = COALESCE(NULLIF(LTRIM(RTRIM(@cMotivo)), ''), N'Revocacion de seguridad.');

    IF @nUsuarioId IS NULL
    BEGIN
        THROW 52220, N'No se pudo revocar las sesiones.', 1;
    END;

    /*
       Si existe una sesion excluida ("cerrar las demas"), se conserva solo
       el dispositivo de esa sesion actual. Todos los demas dispositivos
       reconocidos del usuario pierden la confianza, incluso si en ese momento
       no tienen una sesion activa.

       Si no existe sesion excluida (revocacion total por seguridad, cambio de
       password, deshabilitacion, etc.), se elimina la confianza de TODOS los
       dispositivos del usuario.
    */
    IF @nSesionExcluirId IS NOT NULL
    BEGIN
        SELECT @nDispositivoExcluirId = S.dispositivo_usuario_id
        FROM [seg].[SesionUsuario] S
        WHERE S.sesion_usuario_id = @nSesionExcluirId
          AND S.usuario_id = @nUsuarioId;
    END;

    INSERT INTO @DispositivosRevocados(dispositivo_usuario_id)
    SELECT D.dispositivo_usuario_id
    FROM [seg].[DispositivoUsuario] D
    WHERE D.usuario_id = @nUsuarioId
      AND D.estado = 1
      AND D.es_reconocido = 1
      AND (
            @nDispositivoExcluirId IS NULL
            OR D.dispositivo_usuario_id <> @nDispositivoExcluirId
          );

    UPDATE S
    SET
        S.fecha_revocacion = COALESCE(S.fecha_revocacion, @dAhora),
        S.motivo_revocacion = COALESCE(S.motivo_revocacion, @cMotivo),
        S.estado = 0
    FROM [seg].[SesionUsuario] S
    WHERE S.usuario_id = @nUsuarioId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND (@nSesionExcluirId IS NULL OR S.sesion_usuario_id <> @nSesionExcluirId);

    SET @nCantidadSesionesRevocadas = @@ROWCOUNT;

    UPDATE RT
    SET
        RT.fecha_revocacion = COALESCE(RT.fecha_revocacion, @dAhora),
        RT.motivo_revocacion = COALESCE(RT.motivo_revocacion, @cMotivo),
        RT.estado = 0
    FROM [seg].[RefreshTokenSesion] RT
    INNER JOIN [seg].[SesionUsuario] S
        ON S.sesion_usuario_id = RT.sesion_usuario_id
    WHERE S.usuario_id = @nUsuarioId
      AND (@nSesionExcluirId IS NULL OR S.sesion_usuario_id <> @nSesionExcluirId)
      AND RT.estado = 1;

    UPDATE D
    SET
        D.es_reconocido = 0,
        D.fecha_retiro_reconocimiento =
            COALESCE(D.fecha_retiro_reconocimiento, @dAhora)
    FROM [seg].[DispositivoUsuario] D
    INNER JOIN @DispositivosRevocados X
        ON X.dispositivo_usuario_id = D.dispositivo_usuario_id
    WHERE D.usuario_id = @nUsuarioId
      AND D.estado = 1
      AND D.es_reconocido = 1;

    IF @bIncrementarTokenVersion = 1
    BEGIN
        UPDATE [seg].[Usuario]
        SET token_version = token_version + 1
        WHERE usuario_id = @nUsuarioId;
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
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Seguridad_Upd_RevocarSesionesUsuario',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
    IF @__DbError = 0 AND XACT_STATE() = 1
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
    ELSE
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
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
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Seguridad_Upd_RevocarSesionesUsuario',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Seguridad_Upd_RevocarSesionesUsuario',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
