IF OBJECT_ID(N'[seg].[PA_Sesion_Ins_Crear]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Sesion_Ins_Crear];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Sesion_Ins_Crear
' Descripción             : Crea una sesión de usuario.
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
    EXEC [seg].[PA_Sesion_Ins_Crear]
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
CREATE PROCEDURE [seg].[PA_Sesion_Ins_Crear]
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

    BEGIN TRY

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @nUsuarioId BIGINT,
        @cDispositivoHashHex VARCHAR(128),
        @binDispositivoHash VARBINARY(64),
        @cRefreshTokenHashHex VARCHAR(128),
        @binRefreshTokenHash VARBINARY(64),
        @cNavegador NVARCHAR(120),
        @cSistemaOperativo NVARCHAR(120),
        @cUserAgent NVARCHAR(600),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nMinutosPreAutenticacion SMALLINT,
        @nDispositivoId BIGINT,
        @bInterno BIT,
        @cMensajeInterno NVARCHAR(300),
        @nOperacionIdempotenteId BIGINT,
        @bEsRepetida BIT,
        @cEstadoOperacion VARCHAR(20),
        @cIdentificadorResultado NVARCHAR(200),
        @cCodigoResultado VARCHAR(40),
        @bIdempotencia BIT,
        @cMensajeIdempotencia NVARCHAR(300),
        @bFinalizacionIdempotencia BIT,
        @cMensajeFinalizacion NVARCHAR(300);

    SET @nSesionUsuarioId = NULL;
    SET @gSesionPublicaId = NULL;
    SET @dExpiracionRenovacion = NULL;
    SET @bNuevoDispositivo = 0;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo iniciar la sesion.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
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
        dispositivoHashHex VARCHAR(128) '$.dispositivoHashHex',
        refreshTokenHashHex VARCHAR(128) '$.refreshTokenHashHex',
        navegador NVARCHAR(120) '$.navegador',
        sistemaOperativo NVARCHAR(120) '$.sistemaOperativo',
        userAgent NVARCHAR(600) '$.userAgent',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binDispositivoHash = TRY_CONVERT(VARBINARY(64), @cDispositivoHashHex, 2);
    SET @binRefreshTokenHash = TRY_CONVERT(VARBINARY(64), @cRefreshTokenHashHex, 2);

    IF @nUsuarioId IS NULL
       OR @binDispositivoHash IS NULL
       OR @binRefreshTokenHash IS NULL
       OR @gCorrelacionId IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT TOP (1)
        @nMinutosPreAutenticacion = PS.minutos_expiracion_segundo_factor
    FROM [seg].[PoliticaSeguridad] PS
    WHERE PS.codigo = 'GENERAL'
      AND PS.estado = 1
      AND PS.fecha_hasta IS NULL
      AND PS.fecha_desde <= @dAhora
    ORDER BY PS.fecha_desde DESC;

    IF @nMinutosPreAutenticacion IS NULL
    BEGIN
        SET @cMensaje = N'No se pudo iniciar la sesion. Intente nuevamente.';
        GOTO __DESCO_Salida;
    END;

    /*
       No se admite crear una sesion directamente. Debe existir, para el mismo
       usuario y correlacion, la evidencia reciente de Argon2 validado registrada
       por PA_Usuario_Upd_ResultadoCredencialLogin.
    */
    IF NOT EXISTS
    (
        SELECT 1
        FROM [auditoria].[AuditoriaEvento] A
        WHERE A.usuario_id = @nUsuarioId
          AND A.accion = 'LOGIN_CREDENCIAL'
          AND A.resultado = 'EXITOSO'
          AND A.correlacion_id = @gCorrelacionId
          AND A.endpoint = N'/api/auth/login'
          AND A.estado = 1
          AND A.fecha_hora >= DATEADD(MINUTE, -@nMinutosPreAutenticacion, @dAhora)
    )
    BEGIN
        SET @cMensaje = N'La verificacion de acceso ya no esta disponible. Inicie sesion nuevamente.';
        GOTO __DESCO_Salida;
    END;

    /*
       Una correlacion de login solo puede materializar una sesion. La utilidad
       generica de idempotencia evita doble click/reintentos concurrentes.
    */
    EXEC [auditoria].[PA_OperacionIdempotente_Ins_Iniciar]
         @nUsuarioId = @nUsuarioId,
         @gClaveIdempotencia = @gCorrelacionId,
         @cAmbito = 'LOGIN_CREAR_SESION',
         @nMinutosVigencia = @nMinutosPreAutenticacion,
         @nOperacionIdempotenteId = @nOperacionIdempotenteId OUTPUT,
         @bEsRepetida = @bEsRepetida OUTPUT,
         @cEstadoOperacion = @cEstadoOperacion OUTPUT,
         @cIdentificadorResultado = @cIdentificadorResultado OUTPUT,
         @cCodigoResultado = @cCodigoResultado OUTPUT,
         @bResultado = @bIdempotencia OUTPUT,
         @cMensaje = @cMensajeIdempotencia OUTPUT;

    IF @bEsRepetida = 1
    BEGIN
        IF @cEstadoOperacion = 'COMPLETADA'
           AND TRY_CONVERT(UNIQUEIDENTIFIER, @cIdentificadorResultado) IS NOT NULL
        BEGIN
            SET @gSesionPublicaId = TRY_CONVERT(UNIQUEIDENTIFIER, @cIdentificadorResultado);

            SELECT
                @nSesionUsuarioId = S.sesion_usuario_id,
                @dExpiracionRenovacion = S.fecha_expiracion_renovacion
            FROM [seg].[SesionUsuario] S
            WHERE S.sesion_publica_id = @gSesionPublicaId
              AND S.usuario_id = @nUsuarioId;

            IF @nSesionUsuarioId IS NOT NULL
            BEGIN
                SET @bResultado = 1;
                SET @cMensaje = N'La sesion ya fue iniciada.';
                GOTO __DESCO_Salida;
            END;
        END;

        SET @cMensaje = N'La solicitud de inicio de sesion ya fue procesada. Inicie el acceso nuevamente.';
        GOTO __DESCO_Salida;
    END;

    IF @bIdempotencia = 0 OR @nOperacionIdempotenteId IS NULL
    BEGIN
        SET @cMensaje = N'No se pudo iniciar la sesion. Intente nuevamente.';
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        EXEC [seg].[PA_Seguridad_Ins_CrearSesionInterna]
             @nUsuarioId = @nUsuarioId,
             @binDispositivoHash = @binDispositivoHash,
             @cNavegador = @cNavegador,
             @cSistemaOperativo = @cSistemaOperativo,
             @cUserAgent = @cUserAgent,
             @cIp = @cIp,
             @binRefreshTokenHash = @binRefreshTokenHash,
             @bSegundoFactorValidado = 0,
             @gCorrelacionId = @gCorrelacionId,
             @nSesionUsuarioId = @nSesionUsuarioId OUTPUT,
             @gSesionPublicaId = @gSesionPublicaId OUTPUT,
             @nDispositivoUsuarioId = @nDispositivoId OUTPUT,
             @dExpiracionRenovacion = @dExpiracionRenovacion OUTPUT,
             @bNuevoDispositivo = @bNuevoDispositivo OUTPUT,
             @bResultado = @bInterno OUTPUT,
             @cMensaje = @cMensajeInterno OUTPUT;

        IF @bInterno = 0
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

            EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
                 @nOperacionIdempotenteId = @nOperacionIdempotenteId,
                 @cEstadoOperacion = 'FALLIDA',
                 @cCodigoResultado = 'SESION_NO_CREADA',
                 @bResultado = @bFinalizacionIdempotencia OUTPUT,
                 @cMensaje = @cMensajeFinalizacion OUTPUT;

            SET @nSesionUsuarioId = NULL;
            SET @gSesionPublicaId = NULL;
            SET @dExpiracionRenovacion = NULL;
            SET @bNuevoDispositivo = 0;
            SET @cMensaje = @cMensajeInterno;
            GOTO __DESCO_Salida;
        END;

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId = @nOperacionIdempotenteId,
             @cEstadoOperacion = 'COMPLETADA',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'SesionUsuario',
             @cIdentificadorResultado = @gSesionPublicaId,
             @cCodigoResultado = 'SESION_CREADA',
             @bResultado = @bFinalizacionIdempotencia OUTPUT,
             @cMensaje = @cMensajeFinalizacion OUTPUT;
IF ISNULL(@bFinalizacionIdempotencia,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;

        IF @bFinalizacionIdempotencia = 0
        BEGIN
            THROW 52650, N'No se pudo consolidar el inicio de sesion.', 1;
        END;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Sesion iniciada correctamente.';
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

        IF @nOperacionIdempotenteId IS NOT NULL
        BEGIN
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
                 @nOperacionIdempotenteId = @nOperacionIdempotenteId,
                 @cEstadoOperacion = 'FALLIDA',
                 @cCodigoResultado = 'ERROR_SESION',
                 @bResultado = @bFinalizacionIdempotencia OUTPUT,
                 @cMensaje = @cMensajeFinalizacion OUTPUT;
        END;

        SET @nSesionUsuarioId = NULL;
        SET @gSesionPublicaId = NULL;
        SET @dExpiracionRenovacion = NULL;
        SET @bNuevoDispositivo = 0;
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo iniciar la sesion. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Sesion_Ins_Crear',
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
    @cProcedimiento = N'seg.PA_Sesion_Ins_Crear',
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
    @cProcedimiento = N'seg.PA_Sesion_Ins_Crear',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Sesion_Ins_Crear',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
