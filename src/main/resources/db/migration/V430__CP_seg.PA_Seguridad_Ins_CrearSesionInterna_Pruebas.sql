/* DESCO / Seguridad / 2026-10-27
 Excepcion explicita por usuario para pruebas locales, desactivada por defecto.
 Conserva los controles de credenciales, estado, correo, sesion y el flujo OTP.
 Ejemplo: UPDATE seg.Usuario SET omitir_segundo_factor_pruebas=0 WHERE usuario_id=@UsuarioId;
*/
IF OBJECT_ID(N'[seg].[PA_Seguridad_Ins_CrearSesionInterna]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Seguridad_Ins_CrearSesionInterna];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Seguridad_Ins_CrearSesionInterna
' Descripción             : Crea una sesión interna en el sistema de seguridad.
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
        @nSesionUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @nDispositivoUsuarioId BIGINT,
        @dExpiracionRenovacion DATETIME2(0),
        @bNuevoDispositivo BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Seguridad_Ins_CrearSesionInterna]
        @nUsuarioId = 0,
        @binDispositivoHash = 0x,
        @cNavegador = N'',
        @cSistemaOperativo = N'',
        @cUserAgent = N'',
        @cIp = '',
        @binRefreshTokenHash = 0x,
        @bSegundoFactorValidado = 0,
        @gCorrelacionId = '00000000-0000-0000-0000-000000000001',
        @nSesionUsuarioId = @nSesionUsuarioId OUTPUT,
        @gSesionPublicaId = @gSesionPublicaId OUTPUT,
        @nDispositivoUsuarioId = @nDispositivoUsuarioId OUTPUT,
        @dExpiracionRenovacion = @dExpiracionRenovacion OUTPUT,
        @bNuevoDispositivo = @bNuevoDispositivo OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nSesionUsuarioId, @gSesionPublicaId, @nDispositivoUsuarioId, @dExpiracionRenovacion, @bNuevoDispositivo, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
IF OBJECT_ID(N'[seg].[PA_Seguridad_Ins_CrearSesionInterna]', N'P') IS NOT NULL DROP PROCEDURE [seg].[PA_Seguridad_Ins_CrearSesionInterna];
GO
CREATE PROCEDURE [seg].[PA_Seguridad_Ins_CrearSesionInterna]
(
    @nUsuarioId                   BIGINT,
    @binDispositivoHash           VARBINARY(64),
    @cNavegador                   NVARCHAR(120) = NULL,
    @cSistemaOperativo            NVARCHAR(120) = NULL,
    @cUserAgent                   NVARCHAR(600) = NULL,
    @cIp                          VARCHAR(64) = NULL,
    @binRefreshTokenHash          VARBINARY(64),
    @bSegundoFactorValidado       BIT = 0,
    @gCorrelacionId               UNIQUEIDENTIFIER = NULL,
    @nSesionUsuarioId             BIGINT OUTPUT,
    @gSesionPublicaId             UNIQUEIDENTIFIER OUTPUT,
    @nDispositivoUsuarioId        BIGINT OUTPUT,
    @dExpiracionRenovacion        DATETIME2(0) OUTPUT,
    @bNuevoDispositivo            BIT OUTPUT,
    @bResultado                   BIT OUTPUT,
    @cMensaje                     NVARCHAR(300) OUTPUT,
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
BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

    /* DESCO_SEGURIDAD_2FA_DISPOSITIVO_V3_20260904 */
    SET NOCOUNT ON;

    DECLARE
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nDiasRefresh SMALLINT,
        @nDiasReconocido SMALLINT,
        @nTokenVersion INT,
        @cNombreUsuario VARCHAR(80),
        @binIdentificadorHash VARBINARY(64),
        @bRequiereSegundoFactor BIT = 0,
        @bDispositivoReconocidoVigente BIT = 0,
        @nAuditoriaId BIGINT,
        @bDispositivoExistia BIT = 0,
        @bDispositivoEstadoAnterior BIT = 0;

    SET @nSesionUsuarioId = NULL;
    SET @gSesionPublicaId = NULL;
    SET @nDispositivoUsuarioId = NULL;
    SET @dExpiracionRenovacion = NULL;
    SET @bNuevoDispositivo = 0;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo iniciar la sesion.';

    IF @nUsuarioId IS NULL
       OR @binDispositivoHash IS NULL
       OR @binRefreshTokenHash IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nTokenVersion = U.token_version,
        @cNombreUsuario = U.nombre_usuario,
        @bRequiereSegundoFactor =
            CASE
                WHEN U.segundo_factor_habilitado = 1 THEN 1
                WHEN EXISTS
                (
                    SELECT 1
                    FROM [seg].[UsuarioRol] UR
                    INNER JOIN [seg].[Rol] R
                        ON R.rol_id = UR.rol_id
                    WHERE UR.usuario_id = U.usuario_id
                      AND UR.estado = 1
                      AND UR.fecha_desde <= @dAhora
                      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta >= @dAhora)
                      AND R.estado = 1
                      AND R.requiere_segundo_factor = 1
                ) THEN 1
                ELSE 0
            END
    FROM [seg].[Usuario] U
    INNER JOIN [org].[Empleado] E
        ON E.empleado_id = U.persona_id
    INNER JOIN [org].[Persona] P
        ON P.persona_id = U.persona_id
    WHERE U.usuario_id = @nUsuarioId
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
      );

    IF @nTokenVersion IS NULL
    BEGIN
        SET @cMensaje = N'La cuenta no esta disponible para iniciar sesion.';
        GOTO __DESCO_Salida;
    END;

    SELECT TOP (1)
        @nDiasRefresh = PS.dias_refresh_token,
        @nDiasReconocido = PS.dias_dispositivo_reconocido
    FROM [seg].[PoliticaSeguridad] PS
    WHERE PS.codigo = 'GENERAL'
      AND PS.estado = 1
      AND PS.fecha_hasta IS NULL
      AND PS.fecha_desde <= @dAhora
    ORDER BY PS.fecha_desde DESC;

    IF @nDiasRefresh IS NULL OR @nDiasReconocido IS NULL
    BEGIN
        SET @cMensaje = N'La politica de seguridad no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    /*
       Resolver el dispositivo ANTES de exigir nuevamente 2FA.
       Este paso es imprescindible: el flujo anterior rechazaba la creacion
       de sesion por 2FA antes de consultar si el dispositivo ya era confiable.
    */
    SELECT
        @nDispositivoUsuarioId = D.dispositivo_usuario_id,
        @bDispositivoExistia = 1,
        @bDispositivoEstadoAnterior = D.estado,
        @bDispositivoReconocidoVigente =
            CASE
                WHEN D.estado = 1
                 AND D.es_reconocido = 1
                 AND D.fecha_reconocimiento IS NOT NULL
                 AND DATEADD(DAY, @nDiasReconocido, D.fecha_reconocimiento) > @dAhora
                    THEN 1
                ELSE 0
            END
    FROM [seg].[DispositivoUsuario] D WITH (UPDLOCK, HOLDLOCK)
    WHERE D.usuario_id = @nUsuarioId
      AND D.identificador_logico_hash = @binDispositivoHash;

    IF ISNULL(@bSegundoFactorValidado, 0) = 0
       AND NOT EXISTS (
           SELECT 1 FROM seg.Usuario
           WHERE usuario_id=@nUsuarioId AND omitir_segundo_factor_pruebas=1
       )
       AND
       (
           ISNULL(@bRequiereSegundoFactor, 0) = 1
           OR ISNULL(@bDispositivoReconocidoVigente, 0) = 0
       )
    BEGIN
        SET @cMensaje = N'Se requiere una verificacion adicional de seguridad.';
        GOTO __DESCO_Salida;
    END;

    IF @nDispositivoUsuarioId IS NULL
    BEGIN
        INSERT INTO [seg].[DispositivoUsuario]
        (
            usuario_id,
            identificador_logico_hash,
            navegador,
            sistema_operativo,
            user_agent,
            fecha_primera_deteccion,
            fecha_ultima_actividad,
            es_reconocido,
            fecha_reconocimiento,
            fecha_retiro_reconocimiento,
            ultima_ip,
            estado
        )
        VALUES
        (
            @nUsuarioId,
            @binDispositivoHash,
            NULLIF(LTRIM(RTRIM(@cNavegador)), ''),
            NULLIF(LTRIM(RTRIM(@cSistemaOperativo)), ''),
            @cUserAgent,
            @dAhora,
            @dAhora,
            CASE WHEN ISNULL(@bSegundoFactorValidado, 0) = 1 THEN 1 ELSE 0 END,
            CASE WHEN ISNULL(@bSegundoFactorValidado, 0) = 1 THEN @dAhora ELSE NULL END,
            NULL,
            NULLIF(LTRIM(RTRIM(@cIp)), ''),
            1
        );

        SET @nDispositivoUsuarioId = SCOPE_IDENTITY();
        SET @bNuevoDispositivo = 1;
    END
    ELSE
    BEGIN
        /*
           Si el reconocimiento expiro, se retira automaticamente.
        */
        UPDATE [seg].[DispositivoUsuario]
        SET
            navegador = COALESCE(NULLIF(LTRIM(RTRIM(@cNavegador)), ''), navegador),
            sistema_operativo = COALESCE(NULLIF(LTRIM(RTRIM(@cSistemaOperativo)), ''), sistema_operativo),
            user_agent = COALESCE(@cUserAgent, user_agent),
            fecha_ultima_actividad = @dAhora,
            ultima_ip = COALESCE(NULLIF(LTRIM(RTRIM(@cIp)), ''), ultima_ip),
            es_reconocido =
                CASE
                    WHEN ISNULL(@bSegundoFactorValidado, 0) = 1
                        THEN 1
                    WHEN es_reconocido = 1
                     AND fecha_reconocimiento IS NOT NULL
                     AND DATEADD(DAY, @nDiasReconocido, fecha_reconocimiento) <= @dAhora
                        THEN 0
                    ELSE es_reconocido
                END,
            fecha_reconocimiento =
                CASE
                    WHEN ISNULL(@bSegundoFactorValidado, 0) = 1
                        THEN @dAhora
                    ELSE fecha_reconocimiento
                END,
            fecha_retiro_reconocimiento =
                CASE
                    WHEN ISNULL(@bSegundoFactorValidado, 0) = 1
                        THEN NULL
                    WHEN es_reconocido = 1
                     AND fecha_reconocimiento IS NOT NULL
                     AND DATEADD(DAY, @nDiasReconocido, fecha_reconocimiento) <= @dAhora
                        THEN COALESCE(fecha_retiro_reconocimiento, @dAhora)
                    ELSE fecha_retiro_reconocimiento
                END,
            estado = 1
        WHERE dispositivo_usuario_id = @nDispositivoUsuarioId;

        /*
           El aviso NUEVO_DISPOSITIVO se reserva exclusivamente para una
           huella lógica que nunca estuvo registrada. Reactivar o renovar el
           reconocimiento de un dispositivo existente no genera ese correo.
        */
        SET @bNuevoDispositivo = 0;
    END;

    SET @gSesionPublicaId = NEWID();
    SET @dExpiracionRenovacion = DATEADD(DAY, @nDiasRefresh, @dAhora);

    INSERT INTO [seg].[SesionUsuario]
    (
        sesion_publica_id,
        usuario_id,
        dispositivo_usuario_id,
        token_version,
        fecha_creacion,
        fecha_ultima_actividad,
        fecha_expiracion_renovacion,
        ip_creacion,
        ip_ultima_actividad,
        estado
    )
    VALUES
    (
        @gSesionPublicaId,
        @nUsuarioId,
        @nDispositivoUsuarioId,
        @nTokenVersion,
        @dAhora,
        @dAhora,
        @dExpiracionRenovacion,
        NULLIF(LTRIM(RTRIM(@cIp)), ''),
        NULLIF(LTRIM(RTRIM(@cIp)), ''),
        1
    );

    SET @nSesionUsuarioId = SCOPE_IDENTITY();

    INSERT INTO [seg].[RefreshTokenSesion]
    (
        sesion_usuario_id,
        token_hash,
        fecha_emision,
        fecha_expiracion,
        estado
    )
    VALUES
    (
        @nSesionUsuarioId,
        @binRefreshTokenHash,
        @dAhora,
        @dExpiracionRenovacion,
        1
    );

    UPDATE [seg].[Usuario]
    SET
        ultimo_acceso_correcto = @dAhora,
        intentos_fallidos = 0,
        fecha_ultimo_intento_fallido = NULL,
        bloqueado_hasta = NULL,
        estado_cuenta = 'ACTIVA'
    WHERE usuario_id = @nUsuarioId;

    SET @binIdentificadorHash =
        HASHBYTES('SHA2_256', CONVERT(VARBINARY(8000), LOWER(LTRIM(RTRIM(@cNombreUsuario)))));

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
        @nDispositivoUsuarioId,
        @dAhora,
        'EXITOSO',
        NULLIF(LTRIM(RTRIM(@cIp)), ''),
        @cUserAgent,
        1
    );

    /*
       @bNuevoDispositivo informa al backend que la huella lógica se insertó
       por primera vez. El correo se registra y envía fuera de esta transacción,
       evitando dejar notificaciones PENDIENTES si el envío SMTP falla.
    */

    EXEC [auditoria].[PA_Auditoria_Ins_Evento]
         @nUsuarioId = @nUsuarioId,
         @nSesionUsuarioId = @nSesionUsuarioId,
         @nDispositivoUsuarioId = @nDispositivoUsuarioId,
         @cAccion = 'LOGIN',
         @cEsquemaEntidad = N'seg',
         @cNombreEntidad = N'Usuario',
         @cIdentificador = @nUsuarioId,
         @cMotivo = N'Inicio de sesion satisfactorio.',
         @cIp = @cIp,
         @cResultado = 'EXITOSO',
         @gCorrelacionId = @gCorrelacionId,
         @cEndpoint = N'/api/auth/login',
         @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

    SET @bResultado = 1;
    SET @cMensaje = N'Sesion iniciada correctamente.';

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
    @cProcedimiento = N'seg.PA_Seguridad_Ins_CrearSesionInterna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
    IF @__DbError = 0 AND @bResultado = 1 AND XACT_STATE() = 1
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
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Seguridad_Ins_CrearSesionInterna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
IF ISNULL(@bResultado,0) = 0 SELECT @nSesionUsuarioId=NULL, @gSesionPublicaId=NULL, @nDispositivoUsuarioId=NULL;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Seguridad_Ins_CrearSesionInterna',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description',
 @value=N'Conserva MFA y permite excepcion temporal por cuenta mediante omitir_segundo_factor_pruebas, desactivada por defecto.',
 @level0type=N'SCHEMA',@level0name=N'seg',@level1type=N'PROCEDURE',@level1name=N'PA_Seguridad_Ins_CrearSesionInterna';
GO
