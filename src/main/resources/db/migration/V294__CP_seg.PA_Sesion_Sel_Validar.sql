IF OBJECT_ID(N'[seg].[PA_Sesion_Sel_Validar]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Sesion_Sel_Validar];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Sesion_Sel_Validar
' Descripción             : Valida una sesión de usuario.
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
    EXEC [seg].[PA_Sesion_Sel_Validar]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Sesion_Sel_Validar]
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

    DECLARE
        @nUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @nTokenVersion INT,
        @cJtiHashHex VARCHAR(128),
        @binJtiHash VARBINARY(64),
        @cIp VARCHAR(64),
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nSesionId BIGINT,
        @nDispositivoId BIGINT,
        @dUltimaActividad DATETIME2(0);

    SET @bResultado = 0;
    SET @cMensaje = N'La sesion no esta disponible.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId,
        @nTokenVersion = tokenVersion,
        @cJtiHashHex = NULLIF(LTRIM(RTRIM(jtiHashHex)), ''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), '')
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        tokenVersion INT '$.tokenVersion',
        jtiHashHex VARCHAR(128) '$.jtiHashHex',
        ip VARCHAR(64) '$.ip'
    );

    IF @cJtiHashHex IS NOT NULL
        SET @binJtiHash = TRY_CONVERT(VARBINARY(64), @cJtiHashHex, 2);

    IF @nUsuarioId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @nTokenVersion IS NULL
       OR (@cJtiHashHex IS NOT NULL AND @binJtiHash IS NULL)
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nSesionId = S.sesion_usuario_id,
        @nDispositivoId = S.dispositivo_usuario_id,
        @dUltimaActividad = S.fecha_ultima_actividad
    FROM [seg].[SesionUsuario] S
    INNER JOIN [seg].[Usuario] U ON U.usuario_id = S.usuario_id
    INNER JOIN [org].[Empleado] E ON E.empleado_id = U.persona_id
    INNER JOIN [org].[Persona] P ON P.persona_id = U.persona_id
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.usuario_id = @nUsuarioId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > @dAhora
      AND S.token_version = @nTokenVersion
      AND U.token_version = @nTokenVersion
      AND U.estado = 1
      AND U.estado_cuenta = 'ACTIVA'
      AND (U.bloqueado_hasta IS NULL OR U.bloqueado_hasta <= @dAhora)
      AND E.estado = 1
      AND P.estado = 1
      AND EXISTS
      (
          SELECT 1
          FROM [seg].[UsuarioCorreoSeguridad] UCS
          WHERE UCS.usuario_id = U.usuario_id
            AND UCS.estado = 1
            AND UCS.es_principal = 1
            AND UCS.es_verificado = 1
            AND UCS.fecha_hasta IS NULL
      )
      AND
      (
          @binJtiHash IS NULL
          OR NOT EXISTS
          (
              SELECT 1
              FROM [seg].[TokenAccesoRevocado] TAR
              WHERE TAR.jti_hash = @binJtiHash
                AND TAR.estado = 1
                AND TAR.fecha_expiracion_token > @dAhora
          )
      );

    IF @nSesionId IS NULL
    BEGIN
        GOTO __DESCO_Salida;
    END;

    /*
       Evita escribir en cada request: solo refresca actividad cada 5 minutos.
    */
    IF @dUltimaActividad IS NULL
       OR DATEADD(MINUTE, 5, @dUltimaActividad) <= @dAhora
    BEGIN
        UPDATE [seg].[SesionUsuario]
        SET
            fecha_ultima_actividad = @dAhora,
            ip_ultima_actividad = COALESCE(@cIp, ip_ultima_actividad)
        WHERE sesion_usuario_id = @nSesionId
          AND estado = 1;

        IF @nDispositivoId IS NOT NULL
        BEGIN
            UPDATE [seg].[DispositivoUsuario]
            SET
                fecha_ultima_actividad = @dAhora,
                ultima_ip = COALESCE(@cIp, ultima_ip)
            WHERE dispositivo_usuario_id = @nDispositivoId
              AND estado = 1;
        END;
    END;

    SET @bResultado = 1;
    SET @cMensaje = N'Sesion valida.';

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
    @cProcedimiento = N'seg.PA_Sesion_Sel_Validar',
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
    @cProcedimiento = N'seg.PA_Sesion_Sel_Validar',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Sesion_Sel_Validar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
