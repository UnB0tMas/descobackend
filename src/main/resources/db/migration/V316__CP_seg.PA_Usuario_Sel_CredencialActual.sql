IF OBJECT_ID(N'[seg].[PA_Usuario_Sel_CredencialActual]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Sel_CredencialActual];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Sel_CredencialActual
' Descripción             : Consulta la información de la credencial vigente del usuario.
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
        @cPasswordHash VARCHAR(512),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Usuario_Sel_CredencialActual]
        @cJson = N'{}',
        @cPasswordHash = @cPasswordHash OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @cPasswordHash, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Sel_CredencialActual]
(
    @cJson          NVARCHAR(MAX),
    @cPasswordHash  VARCHAR(512) OUTPUT,
    @bResultado     BIT OUTPUT,
    @cMensaje       NVARCHAR(300) OUTPUT,
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

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;

    DECLARE
        @nUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @cPasswordHash = NULL;
    SET @bResultado = 0;
    SET @cMensaje = N'La sesion no esta disponible.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1 GOTO __DESCO_Salida;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId'
    );

    IF @nUsuarioId IS NULL OR @gSesionPublicaId IS NULL GOTO __DESCO_Salida;

    SELECT
        @cPasswordHash = U.password_hash
    FROM [seg].[SesionUsuario] S
    INNER JOIN [seg].[Usuario] U ON U.usuario_id = S.usuario_id
    INNER JOIN [org].[Empleado] E ON E.empleado_id = U.persona_id
    INNER JOIN [org].[Persona] P ON P.persona_id = U.persona_id
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.usuario_id = @nUsuarioId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > @dAhora
      AND S.token_version = U.token_version
      AND U.estado = 1
      AND U.estado_cuenta = 'ACTIVA'
      AND E.estado = 1
      AND P.estado = 1;

    IF @cPasswordHash IS NULL GOTO __DESCO_Salida;

    SET @bResultado = 1;
    SET @cMensaje = N'Credencial disponible para validacion.';

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
    @cProcedimiento = N'seg.PA_Usuario_Sel_CredencialActual',
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
    @cProcedimiento = N'seg.PA_Usuario_Sel_CredencialActual',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Sel_CredencialActual',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
