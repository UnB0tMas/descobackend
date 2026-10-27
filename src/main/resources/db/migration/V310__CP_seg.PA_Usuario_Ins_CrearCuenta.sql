IF OBJECT_ID(N'[seg].[PA_Usuario_Ins_CrearCuenta]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Ins_CrearCuenta];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Ins_CrearCuenta
' Descripción             : Crea una cuenta de usuario.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Usuario_Ins_CrearCuenta]
        @cJson = N'{}',
        @nUsuarioId = @nUsuarioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUsuarioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Ins_CrearCuenta]
(
    @cJson       NVARCHAR(MAX),
    @nUsuarioId  BIGINT OUTPUT,
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
        @nUsuarioActorId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @nEmpleadoId BIGINT,
        @cNombreUsuario VARCHAR(80),
        @cPasswordHash VARCHAR(512),
        @cCorreoSeguridad NVARCHAR(320),
        @cCorreoNormalizado NVARCHAR(320),
        @bRequiereCambioPassword BIT = 1,
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @bAutorizado BIT,
        @nSesionActorId BIGINT,
        @nDispositivoActorId BIGINT,
        @nCorreoId BIGINT,
        @nAuditoriaId BIGINT,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @nUsuarioId = NULL;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo crear la cuenta. Intente nuevamente.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioActorId = usuarioActorId,
        @gSesionPublicaId = sesionPublicaId,
        @nEmpleadoId = empleadoId,
        @cNombreUsuario = LOWER(NULLIF(LTRIM(RTRIM(nombreUsuario)), '')),
        @cPasswordHash = NULLIF(LTRIM(RTRIM(passwordHash)), ''),
        @cCorreoSeguridad = NULLIF(LTRIM(RTRIM(correoSeguridad)), N''),
        @bRequiereCambioPassword = COALESCE(requiereCambioPassword, CONVERT(BIT,1)),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioActorId BIGINT '$.usuarioActorId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        empleadoId BIGINT '$.empleadoId',
        nombreUsuario VARCHAR(80) '$.nombreUsuario',
        passwordHash VARCHAR(512) '$.passwordHash',
        correoSeguridad NVARCHAR(320) '$.correoSeguridad',
        requiereCambioPassword BIT '$.requiereCambioPassword',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    IF @nUsuarioActorId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @nEmpleadoId IS NULL
       OR @cNombreUsuario IS NULL
       OR @cPasswordHash IS NULL
       OR @cCorreoSeguridad IS NULL
    BEGIN
        SET @cMensaje = N'Complete los datos requeridos para crear la cuenta.';
        GOTO __DESCO_Salida;
    END;

    IF LEN(@cNombreUsuario) < 3
    BEGIN
        SET @cMensaje = N'Ingrese un nombre de usuario valido.';
        GOTO __DESCO_Salida;
    END;

    /*
       Validacion minima del formato PHC. La fortaleza/parametros de Argon2id
       se validan en el backend, que es donde vive la libreria criptografica.
    */
    IF LEFT(@cPasswordHash, 10) <> '$argon2id$'
    BEGIN
        SET @cMensaje = N'No se pudo procesar la credencial de la cuenta.';
        GOTO __DESCO_Salida;
    END;

    IF @cCorreoSeguridad NOT LIKE N'%_@_%._%'
    BEGIN
        SET @cMensaje = N'Ingrese un correo de seguridad valido.';
        GOTO __DESCO_Salida;
    END;

    SET @cCorreoNormalizado = LOWER(LTRIM(RTRIM(@cCorreoSeguridad)));
    IF @gCorrelacionId IS NULL SET @gCorrelacionId = NEWID();

    EXEC [seg].[PA_Autorizacion_Sel_ValidarPermiso]
         @nUsuarioId = @nUsuarioActorId,
         @gSesionPublicaId = @gSesionPublicaId,
         @cCodigoPermiso = 'USUARIOS_CREAR',
         @bAutorizado = @bAutorizado OUTPUT;

    IF ISNULL(@bAutorizado, 0) = 0
    BEGIN
        SET @cMensaje = N'No cuenta con permiso para crear cuentas de usuario.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nSesionActorId = S.sesion_usuario_id,
        @nDispositivoActorId = S.dispositivo_usuario_id
    FROM [seg].[SesionUsuario] S
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.usuario_id = @nUsuarioActorId;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [org].[Empleado] E
        INNER JOIN [org].[Persona] P ON P.persona_id = E.empleado_id
        WHERE E.empleado_id = @nEmpleadoId
          AND E.estado = 1
          AND P.estado = 1
          AND E.fecha_cese IS NULL
    )
    BEGIN
        SET @cMensaje = N'El empleado seleccionado no esta disponible para crear una cuenta.';
        GOTO __DESCO_Salida;
    END;

    IF EXISTS
    (
        SELECT 1 FROM [seg].[Usuario] U
        WHERE U.persona_id = @nEmpleadoId
    )
    BEGIN
        SET @cMensaje = N'El empleado seleccionado ya tiene una cuenta registrada.';
        GOTO __DESCO_Salida;
    END;

    IF EXISTS
    (
        SELECT 1 FROM [seg].[Usuario] U
        WHERE LOWER(U.nombre_usuario) = @cNombreUsuario
    )
    BEGIN
        SET @cMensaje = N'El nombre de usuario ya se encuentra registrado.';
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        INSERT INTO [seg].[Usuario]
        (
            persona_id,
            nombre_usuario,
            password_hash,
            estado,
            fecha_creacion,
            estado_cuenta,
            intentos_fallidos,
            fecha_ultimo_intento_fallido,
            bloqueado_hasta,
            ultimo_acceso_correcto,
            fecha_cambio_password,
            requiere_cambio_password,
            segundo_factor_habilitado,
            token_version
        )
        VALUES
        (
            @nEmpleadoId,
            @cNombreUsuario,
            @cPasswordHash,
            1,
            @dAhora,
            'PENDIENTE_VALIDACION',
            0,
            NULL,
            NULL,
            NULL,
            @dAhora,
            @bRequiereCambioPassword,
            0,
            1
        );

        SET @nUsuarioId = CONVERT(BIGINT, SCOPE_IDENTITY());

        INSERT INTO [seg].[UsuarioCorreoSeguridad]
        (
            usuario_id,
            correo,
            correo_normalizado,
            es_principal,
            es_verificado,
            fecha_desde,
            creado_por_usuario_id,
            motivo_cambio,
            estado
        )
        VALUES
        (
            @nUsuarioId,
            @cCorreoSeguridad,
            @cCorreoNormalizado,
            1,
            0,
            @dAhora,
            @nUsuarioActorId,
            N'Correo inicial de seguridad.',
            1
        );

        SET @nCorreoId = CONVERT(BIGINT, SCOPE_IDENTITY());

        /*
           Se crea historial desde el primer hash para que las futuras politicas
           de no reutilizacion puedan consultar una sola fuente historica.
        */
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
            @cPasswordHash,
            @dAhora,
            @nUsuarioActorId,
            N'Credencial inicial de la cuenta.',
            1
        );

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioActorId,
             @nSesionUsuarioId = @nSesionActorId,
             @nDispositivoUsuarioId = @nDispositivoActorId,
             @cAccion = 'CREAR_CUENTA',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'Usuario',
             @cIdentificador = @nUsuarioId,
             @cDatosAnteriores = NULL,
             @cDatosPosteriores = NULL,
             @cMotivo = N'Cuenta de acceso creada para empleado.',
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint = N'/api/usuarios',
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Cuenta creada correctamente. Debe validar su correo de seguridad antes de ingresar.';
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
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo crear la cuenta. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Ins_CrearCuenta',
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
    @cProcedimiento = N'seg.PA_Usuario_Ins_CrearCuenta',
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
    @cProcedimiento = N'seg.PA_Usuario_Ins_CrearCuenta',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Ins_CrearCuenta',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
