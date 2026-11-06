/* DESCO / Seguridad / 2026-10-27
 Excepcion explicita por usuario para pruebas locales, desactivada por defecto.
 Conserva los controles de credenciales, estado, correo, sesion y el flujo OTP.
 Ejemplo: UPDATE seg.Usuario SET omitir_segundo_factor_pruebas=0 WHERE usuario_id=@UsuarioId;
*/
IF OBJECT_ID(N'[seg].[PA_Usuario_Upd_ResultadoCredencialLogin]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Upd_ResultadoCredencialLogin];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Upd_ResultadoCredencialLogin
' Descripción             : Actualiza el resultado de la validación de credenciales de inicio de sesión.
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
        @cPasoSiguiente VARCHAR(30),
        @bRequiereSegundoFactor BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Usuario_Upd_ResultadoCredencialLogin]
        @cJson = N'{}',
        @cPasoSiguiente = @cPasoSiguiente OUTPUT,
        @bRequiereSegundoFactor = @bRequiereSegundoFactor OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @cPasoSiguiente, @bRequiereSegundoFactor, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
IF OBJECT_ID(N'[seg].[PA_Usuario_Upd_ResultadoCredencialLogin]', N'P') IS NOT NULL DROP PROCEDURE [seg].[PA_Usuario_Upd_ResultadoCredencialLogin];
GO
CREATE PROCEDURE [seg].[PA_Usuario_Upd_ResultadoCredencialLogin]
(
    @cJson                   NVARCHAR(MAX),
    @cPasoSiguiente          VARCHAR(30) OUTPUT,
    @bRequiereSegundoFactor  BIT OUTPUT,
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
        @nUsuarioIdResuelto BIGINT,
        @cNombreUsuario VARCHAR(80),
        @bPasswordValida BIT,
        @cIp VARCHAR(64),
        @cUserAgent NVARCHAR(600),
        @cDispositivoHashHex VARCHAR(128),
        @binDispositivoHash VARBINARY(64),
        @nDispositivoUsuarioId BIGINT,
        @gCorrelacionId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nMaxIntentos SMALLINT,
        @nMinutosBloqueo SMALLINT,
        @nDiasDispositivoReconocido SMALLINT,
        @bDispositivoReconocidoVigente BIT = 0,
        @bDispositivoReconocidoExpirado BIT = 0,
        @bSegundoFactorObligatorio BIT = 0,
        @nIntentosActuales SMALLINT,
        @cEstadoCuenta VARCHAR(25),
        @dBloqueadoHasta DATETIME2(0),
        @bCorreoVerificado BIT = 0,
        @cResultadoIntento VARCHAR(35),
        @binIdentificadorHash VARBINARY(64),
        @cIdentificadorAuditoria NVARCHAR(200),
        @nAuditoriaId BIGINT;

    SET @cPasoSiguiente = NULL;
    SET @bRequiereSegundoFactor = 0;
    SET @bResultado = 0;
    SET @cMensaje = N'Credenciales invalidas.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @cNombreUsuario = NULLIF(LTRIM(RTRIM(nombreUsuario)), ''),
        @bPasswordValida = passwordValida,
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @cUserAgent = userAgent,
        @cDispositivoHashHex = NULLIF(LTRIM(RTRIM(dispositivoHashHex)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        nombreUsuario VARCHAR(80) '$.nombreUsuario',
        passwordValida BIT '$.passwordValida',
        ip VARCHAR(64) '$.ip',
        userAgent NVARCHAR(600) '$.userAgent',
        dispositivoHashHex VARCHAR(128) '$.dispositivoHashHex',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    IF @cNombreUsuario IS NULL OR @bPasswordValida IS NULL
    BEGIN
        GOTO __DESCO_Salida;
    END;

    IF @gCorrelacionId IS NULL SET @gCorrelacionId = NEWID();

    SET @binIdentificadorHash =
        HASHBYTES('SHA2_256', CONVERT(VARBINARY(8000), LOWER(@cNombreUsuario)));

    IF @cDispositivoHashHex IS NOT NULL
        SET @binDispositivoHash = TRY_CONVERT(VARBINARY(64), @cDispositivoHashHex, 2);

    SELECT TOP (1)
        @nMaxIntentos = PS.max_intentos_login,
        @nMinutosBloqueo = PS.minutos_bloqueo_login,
        @nDiasDispositivoReconocido = PS.dias_dispositivo_reconocido
    FROM [seg].[PoliticaSeguridad] PS
    WHERE PS.codigo = 'GENERAL'
      AND PS.estado = 1
      AND PS.fecha_hasta IS NULL
      AND PS.fecha_desde <= @dAhora
    ORDER BY PS.fecha_desde DESC;

    IF @nMaxIntentos IS NULL OR @nDiasDispositivoReconocido IS NULL
    BEGIN
        SET @cMensaje = N'No se pudo iniciar sesion. Intente nuevamente.';
        GOTO __DESCO_Salida;
    END;

    /*
       Se vuelve a resolver por nombre para que el usuarioId recibido no pueda
       asociarse arbitrariamente a otro nombre.
    */
    SELECT
        @nUsuarioIdResuelto = U.usuario_id,
        @nIntentosActuales = U.intentos_fallidos,
        @cEstadoCuenta = U.estado_cuenta,
        @dBloqueadoHasta = U.bloqueado_hasta
    FROM [seg].[Usuario] U
    INNER JOIN [org].[Empleado] E
        ON E.empleado_id = U.persona_id
    INNER JOIN [org].[Persona] P
        ON P.persona_id = U.persona_id
    WHERE U.nombre_usuario = @cNombreUsuario
      AND (@nUsuarioId IS NULL OR U.usuario_id = @nUsuarioId)
      AND U.estado = 1
      AND E.estado = 1
      AND P.estado = 1;

    IF @binDispositivoHash IS NOT NULL
       AND @nUsuarioIdResuelto IS NOT NULL
    BEGIN
        SELECT
            @nDispositivoUsuarioId = D.dispositivo_usuario_id,
            @bDispositivoReconocidoVigente =
                CASE
                    WHEN D.estado = 1
                     AND D.es_reconocido = 1
                     AND D.fecha_reconocimiento IS NOT NULL
                     AND DATEADD(DAY, @nDiasDispositivoReconocido, D.fecha_reconocimiento) > @dAhora
                        THEN 1
                    ELSE 0
                END,
            @bDispositivoReconocidoExpirado =
                CASE
                    WHEN D.estado = 1
                     AND D.es_reconocido = 1
                     AND D.fecha_reconocimiento IS NOT NULL
                     AND DATEADD(DAY, @nDiasDispositivoReconocido, D.fecha_reconocimiento) <= @dAhora
                        THEN 1
                    ELSE 0
                END
        FROM [seg].[DispositivoUsuario] D
        WHERE D.usuario_id = @nUsuarioIdResuelto
          AND D.identificador_logico_hash = @binDispositivoHash;
    END;

    SET @cIdentificadorAuditoria =
        COALESCE(CONVERT(NVARCHAR(200), @nUsuarioIdResuelto), N'NO_IDENTIFICADO');

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        /* ------------------------------------------------------------
           CONTRASENA INCORRECTA O CUENTA NO ENCONTRADA
           ------------------------------------------------------------ */
        IF ISNULL(@bPasswordValida, 0) = 0
           OR @nUsuarioIdResuelto IS NULL
        BEGIN
            SET @cResultadoIntento = 'CREDENCIALES_INVALIDAS';

            IF @nUsuarioIdResuelto IS NOT NULL
               AND @cEstadoCuenta NOT IN ('DESHABILITADA','RETIRADA')
            BEGIN
                UPDATE [seg].[Usuario]
                SET
                    intentos_fallidos =
                        CASE
                            WHEN intentos_fallidos + 1 > @nMaxIntentos
                                THEN @nMaxIntentos
                            ELSE intentos_fallidos + 1
                        END,
                    fecha_ultimo_intento_fallido = @dAhora,
                    estado_cuenta =
                        CASE
                            WHEN intentos_fallidos + 1 >= @nMaxIntentos
                                THEN 'BLOQUEADA'
                            ELSE estado_cuenta
                        END,
                    bloqueado_hasta =
                        CASE
                            WHEN intentos_fallidos + 1 >= @nMaxIntentos
                                THEN DATEADD(MINUTE, @nMinutosBloqueo, @dAhora)
                            ELSE bloqueado_hasta
                        END
                WHERE usuario_id = @nUsuarioIdResuelto;

                IF @nIntentosActuales + 1 >= @nMaxIntentos
                    SET @cResultadoIntento = 'CUENTA_BLOQUEADA';
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
                @nUsuarioIdResuelto,
                @binIdentificadorHash,
                @nDispositivoUsuarioId,
                @dAhora,
                @cResultadoIntento,
                @cIp,
                @cUserAgent,
                1
            );

            EXEC [auditoria].[PA_Auditoria_Ins_Evento]
                 @nUsuarioId = @nUsuarioIdResuelto,
                 @nDispositivoUsuarioId = @nDispositivoUsuarioId,
                 @cAccion = 'LOGIN_CREDENCIAL',
                 @cEsquemaEntidad = N'seg',
                 @cNombreEntidad = N'Usuario',
                 @cIdentificador = @cIdentificadorAuditoria,
                 @cMotivo = N'Intento de acceso no satisfactorio.',
                 @cIp = @cIp,
                 @cResultado = 'RECHAZADO',
                 @gCorrelacionId = @gCorrelacionId,
                 @cEndpoint = N'/api/auth/login',
                 @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            SET @cMensaje = N'Credenciales invalidas.';
            GOTO __DESCO_Salida;
        END;

        /* ------------------------------------------------------------
           PASSWORD CORRECTA: validar estado funcional
           ------------------------------------------------------------ */
        SELECT
            @cEstadoCuenta = U.estado_cuenta,
            @dBloqueadoHasta = U.bloqueado_hasta
        FROM [seg].[Usuario] U WITH (UPDLOCK, HOLDLOCK)
        WHERE U.usuario_id = @nUsuarioIdResuelto;

        IF @cEstadoCuenta IN ('DESHABILITADA','RETIRADA')
        BEGIN
            INSERT INTO [seg].[IntentoAutenticacion]
            (
                usuario_id, identificador_ingresado_hash,
                dispositivo_usuario_id, fecha_hora, resultado,
                ip, user_agent, estado
            )
            VALUES
            (
                @nUsuarioIdResuelto, @binIdentificadorHash,
                @nDispositivoUsuarioId, @dAhora, 'CUENTA_DESHABILITADA',
                @cIp, @cUserAgent, 1
            );

            EXEC [auditoria].[PA_Auditoria_Ins_Evento]
                 @nUsuarioId = @nUsuarioIdResuelto,
                 @nDispositivoUsuarioId = @nDispositivoUsuarioId,
                 @cAccion = 'LOGIN_CREDENCIAL',
                 @cEsquemaEntidad = N'seg',
                 @cNombreEntidad = N'Usuario',
                 @cIdentificador = @cIdentificadorAuditoria,
                 @cMotivo = N'La cuenta no esta habilitada para acceso.',
                 @cIp = @cIp,
                 @cResultado = 'RECHAZADO',
                 @gCorrelacionId = @gCorrelacionId,
                 @cEndpoint = N'/api/auth/login',
                 @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            SET @cMensaje = N'Credenciales invalidas.';
            GOTO __DESCO_Salida;
        END;

        IF @cEstadoCuenta = 'BLOQUEADA'
           AND @dBloqueadoHasta IS NOT NULL
           AND @dBloqueadoHasta > @dAhora
        BEGIN
            INSERT INTO [seg].[IntentoAutenticacion]
            (
                usuario_id, identificador_ingresado_hash,
                dispositivo_usuario_id, fecha_hora, resultado,
                ip, user_agent, estado
            )
            VALUES
            (
                @nUsuarioIdResuelto, @binIdentificadorHash,
                @nDispositivoUsuarioId, @dAhora, 'CUENTA_BLOQUEADA',
                @cIp, @cUserAgent, 1
            );

            EXEC [auditoria].[PA_Auditoria_Ins_Evento]
                 @nUsuarioId = @nUsuarioIdResuelto,
                 @nDispositivoUsuarioId = @nDispositivoUsuarioId,
                 @cAccion = 'LOGIN_CREDENCIAL',
                 @cEsquemaEntidad = N'seg',
                 @cNombreEntidad = N'Usuario',
                 @cIdentificador = @cIdentificadorAuditoria,
                 @cMotivo = N'Intento de acceso durante bloqueo temporal.',
                 @cIp = @cIp,
                 @cResultado = 'RECHAZADO',
                 @gCorrelacionId = @gCorrelacionId,
                 @cEndpoint = N'/api/auth/login',
                 @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            SET @cMensaje = N'No se pudo iniciar sesion. Intente nuevamente mas tarde.';
            GOTO __DESCO_Salida;
        END;

        SELECT
            @bCorreoVerificado =
                CASE WHEN EXISTS
                (
                    SELECT 1
                    FROM [seg].[UsuarioCorreoSeguridad] UCS
                    WHERE UCS.usuario_id = @nUsuarioIdResuelto
                      AND UCS.estado = 1
                      AND UCS.es_principal = 1
                      AND UCS.es_verificado = 1
                      AND UCS.fecha_hasta IS NULL
                ) THEN 1 ELSE 0 END;

        /*
           Si el bloqueo ya expiro, la cuenta vuelve al estado que corresponde
           segun la validacion real del correo.
        */
        UPDATE [seg].[Usuario]
        SET
            intentos_fallidos = 0,
            fecha_ultimo_intento_fallido = NULL,
            bloqueado_hasta = NULL,
            estado_cuenta =
                CASE
                    WHEN @bCorreoVerificado = 1 THEN 'ACTIVA'
                    ELSE 'PENDIENTE_VALIDACION'
                END
        WHERE usuario_id = @nUsuarioIdResuelto;

        IF @bCorreoVerificado = 0
        BEGIN
            INSERT INTO [seg].[IntentoAutenticacion]
            (
                usuario_id, identificador_ingresado_hash,
                dispositivo_usuario_id, fecha_hora, resultado,
                ip, user_agent, estado
            )
            VALUES
            (
                @nUsuarioIdResuelto, @binIdentificadorHash,
                @nDispositivoUsuarioId, @dAhora, 'CORREO_NO_VALIDADO',
                @cIp, @cUserAgent, 1
            );

            SET @cPasoSiguiente = 'VALIDAR_CORREO';
            SET @bResultado = 1;
            SET @cMensaje = N'Valide su correo de seguridad para continuar.';

            EXEC [auditoria].[PA_Auditoria_Ins_Evento]
                 @nUsuarioId = @nUsuarioIdResuelto,
                 @nDispositivoUsuarioId = @nDispositivoUsuarioId,
                 @cAccion = 'LOGIN_CREDENCIAL',
                 @cEsquemaEntidad = N'seg',
                 @cNombreEntidad = N'Usuario',
                 @cIdentificador = @cIdentificadorAuditoria,
                 @cMotivo = N'Credencial valida; correo de seguridad pendiente de validacion.',
                 @cIp = @cIp,
                 @cResultado = 'RECHAZADO',
                 @gCorrelacionId = @gCorrelacionId,
                 @cEndpoint = N'/api/auth/login',
                 @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            GOTO __DESCO_Salida;
        END;

        /*
           Política de acceso por dispositivo:
           - dispositivo nuevo/no reconocido/expirado => exige código;
           - dispositivo reconocido y vigente => omite el desafío;
           - el historial se conserva y solo se retira el reconocimiento.
        */
        IF ISNULL(@bDispositivoReconocidoExpirado, 0) = 1
           AND @nDispositivoUsuarioId IS NOT NULL
        BEGIN
            UPDATE [seg].[DispositivoUsuario]
            SET
                es_reconocido = 0,
                fecha_retiro_reconocimiento = COALESCE(fecha_retiro_reconocimiento, @dAhora)
            WHERE dispositivo_usuario_id = @nDispositivoUsuarioId
              AND usuario_id = @nUsuarioIdResuelto;

            SET @bDispositivoReconocidoVigente = 0;
        END;

        /*
           La marca del usuario y la de sus roles representan segundo factor
           obligatorio en CADA inicio de sesión. La confianza del dispositivo
           solo permite omitir el OTP cuando esa política obligatoria no aplica.
        */
        SET @bSegundoFactorObligatorio =
            CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM [seg].[Usuario] U
                    WHERE U.usuario_id = @nUsuarioIdResuelto
                      AND U.segundo_factor_habilitado = 1
                ) THEN 1
                WHEN EXISTS
                (
                    SELECT 1
                    FROM [seg].[UsuarioRol] UR
                    INNER JOIN [seg].[Rol] R
                        ON R.rol_id = UR.rol_id
                    WHERE UR.usuario_id = @nUsuarioIdResuelto
                      AND UR.estado = 1
                      AND UR.fecha_desde <= @dAhora
                      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta >= @dAhora)
                      AND R.estado = 1
                      AND R.requiere_segundo_factor = 1
                ) THEN 1
                ELSE 0
            END;

        SET @bRequiereSegundoFactor =
            CASE
                WHEN @bSegundoFactorObligatorio = 1 THEN 1
                WHEN ISNULL(@bDispositivoReconocidoVigente, 0) = 1 THEN 0
                ELSE 1
            END;

        /* Solo la cuenta explicitamente habilitada para pruebas omite OTP. */
        IF EXISTS (
            SELECT 1 FROM seg.Usuario
            WHERE usuario_id=@nUsuarioIdResuelto AND omitir_segundo_factor_pruebas=1
        ) SET @bRequiereSegundoFactor=0;

        IF @bRequiereSegundoFactor = 1
        BEGIN
            INSERT INTO [seg].[IntentoAutenticacion]
            (
                usuario_id, identificador_ingresado_hash,
                dispositivo_usuario_id, fecha_hora, resultado,
                ip, user_agent, estado
            )
            VALUES
            (
                @nUsuarioIdResuelto, @binIdentificadorHash,
                @nDispositivoUsuarioId, @dAhora, 'REQUIERE_SEGUNDO_FACTOR',
                @cIp, @cUserAgent, 1
            );

            SET @cPasoSiguiente = 'SEGUNDO_FACTOR';
            SET @bResultado = 1;
            SET @cMensaje = N'Complete la verificacion adicional de seguridad.';

            EXEC [auditoria].[PA_Auditoria_Ins_Evento]
                 @nUsuarioId = @nUsuarioIdResuelto,
                 @nDispositivoUsuarioId = @nDispositivoUsuarioId,
                 @cAccion = 'LOGIN_CREDENCIAL',
                 @cEsquemaEntidad = N'seg',
                 @cNombreEntidad = N'Usuario',
                 @cIdentificador = @cIdentificadorAuditoria,
                 @cMotivo = N'Credencial valida; se requiere segundo factor.',
                 @cIp = @cIp,
                 @cResultado = 'EXITOSO',
                 @gCorrelacionId = @gCorrelacionId,
                 @cEndpoint = N'/api/auth/login',
                 @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            GOTO __DESCO_Salida;
        END;

        SET @cPasoSiguiente = 'CREAR_SESION';
        SET @bResultado = 1;
        SET @cMensaje = N'Credenciales verificadas correctamente.';

        /*
           Evidencia de preautenticacion. PA_Sesion_Ins_Crear exige el mismo
           correlacionId para impedir que se cree una sesion sin haber pasado
           previamente por la verificacion Argon2 del backend.
        */
        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioIdResuelto,
             @nDispositivoUsuarioId = @nDispositivoUsuarioId,
             @cAccion = 'LOGIN_CREDENCIAL',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'Usuario',
             @cIdentificador = @cIdentificadorAuditoria,
             @cMotivo = N'Credencial valida; cuenta habilitada para crear sesion.',
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint = N'/api/auth/login',
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
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

        SET @cPasoSiguiente = NULL;
        SET @bRequiereSegundoFactor = 0;
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo iniciar sesion. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Upd_ResultadoCredencialLogin',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_ResultadoCredencialLogin',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_ResultadoCredencialLogin',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Upd_ResultadoCredencialLogin',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description',
 @value=N'Conserva MFA y permite excepcion temporal por cuenta mediante omitir_segundo_factor_pruebas, desactivada por defecto.',
 @level0type=N'SCHEMA',@level0name=N'seg',@level1type=N'PROCEDURE',@level1name=N'PA_Usuario_Upd_ResultadoCredencialLogin';
GO
