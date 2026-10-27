IF OBJECT_ID(N'[seg].[PA_Usuario_Upd_ValidarSegundoFactor]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Upd_ValidarSegundoFactor];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Upd_ValidarSegundoFactor
' Descripción             : Valida el segundo factor de autenticación del usuario.
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
        @nSesionUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @dExpiracionRenovacion DATETIME2(0),
        @bNuevoDispositivo BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Usuario_Upd_ValidarSegundoFactor]
        @cJson = N'{}',
        @nSesionUsuarioId = @nSesionUsuarioId OUTPUT,
        @gSesionPublicaId = @gSesionPublicaId OUTPUT,
        @dExpiracionRenovacion = @dExpiracionRenovacion OUTPUT,
        @bNuevoDispositivo = @bNuevoDispositivo OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nSesionUsuarioId, @gSesionPublicaId, @dExpiracionRenovacion, @bNuevoDispositivo, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Upd_ValidarSegundoFactor]
(
    @cJson                   NVARCHAR(MAX),
    @nSesionUsuarioId        BIGINT OUTPUT,
    @gSesionPublicaId        UNIQUEIDENTIFIER OUTPUT,
    @dExpiracionRenovacion   DATETIME2(0) OUTPUT,
    @bNuevoDispositivo       BIT OUTPUT,
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
        @nUsuarioId BIGINT,
        @cCodigoHmacHex VARCHAR(128),
        @binCodigoHmac VARBINARY(64),
        @cDispositivoHashHex VARCHAR(128),
        @binDispositivoHash VARBINARY(64),
        @cRefreshTokenHashHex VARCHAR(128),
        @binRefreshTokenHash VARBINARY(64),
        @cNavegador NVARCHAR(120),
        @cSistemaOperativo NVARCHAR(120),
        @cUserAgent NVARCHAR(600),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @nCodigoId BIGINT,
        @nCorreoId BIGINT,
        @bCodigoValido BIT,
        @cMensajeCodigo NVARCHAR(300),
        @nDispositivoId BIGINT,
        @bSesionCreada BIT,
        @cMensajeSesion NVARCHAR(300),
        @binIdentificadorHash VARBINARY(64),
        @cNombreUsuario VARCHAR(80),
        @nAuditoriaId BIGINT;

    SET @nSesionUsuarioId = NULL;
    SET @gSesionPublicaId = NULL;
    SET @dExpiracionRenovacion = NULL;
    SET @bNuevoDispositivo = 0;
    SET @bResultado = 0;
    SET @cMensaje = N'El codigo ingresado no es valido o ha expirado.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @cCodigoHmacHex = NULLIF(LTRIM(RTRIM(codigoHmacHex)), ''),
        @cDispositivoHashHex = NULLIF(LTRIM(RTRIM(dispositivoHashHex)), ''),
        @cRefreshTokenHashHex = NULLIF(LTRIM(RTRIM(refreshTokenHashHex)), ''),
        @cNavegador = NULLIF(LTRIM(RTRIM(navegador)), ''),
        @cSistemaOperativo = NULLIF(LTRIM(RTRIM(sistemaOperativo)), ''),
        @cUserAgent = userAgent,
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        codigoHmacHex VARCHAR(128) '$.codigoHmacHex',
        dispositivoHashHex VARCHAR(128) '$.dispositivoHashHex',
        refreshTokenHashHex VARCHAR(128) '$.refreshTokenHashHex',
        navegador NVARCHAR(120) '$.navegador',
        sistemaOperativo NVARCHAR(120) '$.sistemaOperativo',
        userAgent NVARCHAR(600) '$.userAgent',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binCodigoHmac = TRY_CONVERT(VARBINARY(64), @cCodigoHmacHex, 2);
    SET @binDispositivoHash = TRY_CONVERT(VARBINARY(64), @cDispositivoHashHex, 2);
    SET @binRefreshTokenHash = TRY_CONVERT(VARBINARY(64), @cRefreshTokenHashHex, 2);

    IF @nUsuarioId IS NULL
       OR @binCodigoHmac IS NULL
       OR @binDispositivoHash IS NULL
       OR @binRefreshTokenHash IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @cNombreUsuario = U.nombre_usuario
    FROM [seg].[Usuario] U
    WHERE U.usuario_id = @nUsuarioId;

    SET @binIdentificadorHash =
        HASHBYTES('SHA2_256', CONVERT(VARBINARY(8000), LOWER(COALESCE(@cNombreUsuario, ''))));

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        EXEC [seg].[PA_Seguridad_Upd_ConsumirCodigoUnSoloUso]
             @nUsuarioId = @nUsuarioId,
             @cProposito = 'SEGUNDO_FACTOR',
             @binCodigoHmac = @binCodigoHmac,
             @cIp = @cIp,
             @gCorrelacionId = @gCorrelacionId,
             @nCodigoUnSoloUsoId = @nCodigoId OUTPUT,
             @nUsuarioCorreoSeguridadId = @nCorreoId OUTPUT,
             @bCodigoValido = @bCodigoValido OUTPUT,
             @cMensaje = @cMensajeCodigo OUTPUT;

        IF @bCodigoValido = 0
        BEGIN
            INSERT INTO [seg].[IntentoAutenticacion]
            (
                usuario_id,
                identificador_ingresado_hash,
                dispositivo_usuario_id,
                fecha_hora,
                resultado,
                ip,
                user_agent,
                estado
            )
            VALUES
            (
                @nUsuarioId,
                @binIdentificadorHash,
                NULL,
                SYSUTCDATETIME(),
                'SEGUNDO_FACTOR_INVALIDO',
                @cIp,
                @cUserAgent,
                1
            );

            EXEC [auditoria].[PA_Auditoria_Ins_Evento]
                 @nUsuarioId = @nUsuarioId,
                 @cAccion = 'SEGUNDO_FACTOR',
                 @cEsquemaEntidad = N'seg',
                 @cNombreEntidad = N'Usuario',
                 @cIdentificador = @nUsuarioId,
                 @cMotivo = N'Verificacion adicional no satisfactoria.',
                 @cIp = @cIp,
                 @cResultado = 'RECHAZADO',
                 @gCorrelacionId = @gCorrelacionId,
                 @cEndpoint = N'/api/auth/segundo-factor/validar',
                 @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            SET @cMensaje = N'El codigo ingresado no es valido o ha expirado.';
            GOTO __DESCO_Salida;
        END;

        INSERT INTO [seg].[IntentoAutenticacion]
        (
            usuario_id,
            identificador_ingresado_hash,
            dispositivo_usuario_id,
            fecha_hora,
            resultado,
            ip,
            user_agent,
            estado
        )
        VALUES
        (
            @nUsuarioId,
            @binIdentificadorHash,
            NULL,
            SYSUTCDATETIME(),
            'SEGUNDO_FACTOR_EXITOSO',
            @cIp,
            @cUserAgent,
            1
        );

        EXEC [seg].[PA_Seguridad_Ins_CrearSesionInterna]
             @nUsuarioId = @nUsuarioId,
             @binDispositivoHash = @binDispositivoHash,
             @cNavegador = @cNavegador,
             @cSistemaOperativo = @cSistemaOperativo,
             @cUserAgent = @cUserAgent,
             @cIp = @cIp,
             @binRefreshTokenHash = @binRefreshTokenHash,
             @bSegundoFactorValidado = 1,
             @gCorrelacionId = @gCorrelacionId,
             @nSesionUsuarioId = @nSesionUsuarioId OUTPUT,
             @gSesionPublicaId = @gSesionPublicaId OUTPUT,
             @nDispositivoUsuarioId = @nDispositivoId OUTPUT,
             @dExpiracionRenovacion = @dExpiracionRenovacion OUTPUT,
             @bNuevoDispositivo = @bNuevoDispositivo OUTPUT,
             @bResultado = @bSesionCreada OUTPUT,
             @cMensaje = @cMensajeSesion OUTPUT;

        IF @bSesionCreada = 0
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

            SET @nSesionUsuarioId = NULL;
            SET @gSesionPublicaId = NULL;
            SET @dExpiracionRenovacion = NULL;
            SET @bNuevoDispositivo = 0;
            SET @bResultado = 0;
            SET @cMensaje = @cMensajeSesion;
            GOTO __DESCO_Salida;
        END;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Verificacion completada. Sesion iniciada correctamente.';
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

        SET @nSesionUsuarioId = NULL;
        SET @gSesionPublicaId = NULL;
        SET @dExpiracionRenovacion = NULL;
        SET @bNuevoDispositivo = 0;
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo completar la verificacion. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Upd_ValidarSegundoFactor',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_ValidarSegundoFactor',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_ValidarSegundoFactor',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Upd_ValidarSegundoFactor',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
