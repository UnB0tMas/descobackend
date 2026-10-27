IF OBJECT_ID(N'[seg].[PA_UsuarioAdmin_Ins_CrearCuenta]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioAdmin_Ins_CrearCuenta];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_UsuarioAdmin_Ins_CrearCuenta
' Descripción             : Crea una cuenta de usuario desde la administración.
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
        @nUsuarioNuevoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_UsuarioAdmin_Ins_CrearCuenta]
        @cJson = N'{}',
        @nUsuarioNuevoId = @nUsuarioNuevoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUsuarioNuevoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_UsuarioAdmin_Ins_CrearCuenta]
(
    @cJson NVARCHAR(MAX),
    @nUsuarioNuevoId BIGINT OUTPUT,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
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

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
        @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),
        @nAud BIGINT,@nTrans BIGINT,@nEmpleado BIGINT,@cNombre VARCHAR(80),
        @cHash VARCHAR(512),@cCorreo NVARCHAR(320),@cCorreoN NVARCHAR(320),
        @bCambio BIT,@cIdent NVARCHAR(200),@cRolesJson NVARCHAR(MAX),
        @bDelegable BIT,@cMsgDelegacion NVARCHAR(300);

    SELECT @nUsuarioNuevoId=NULL,@bResultado=0,@cMensaje=N'No se pudo crear la cuenta.';

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
         @cJson=@cJson,@cCodigoPermiso='USUARIOS_CREAR',@cAmbito='USUARIO_CREAR',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
         @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
         @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
         @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
         @nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,
         @cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,
         @cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    IF @bRep=1
    BEGIN
        IF @cEstadoOp='COMPLETADA'
            SET @nUsuarioNuevoId=TRY_CONVERT(BIGINT,@cIdRes);

        SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
        SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA'
                           THEN N'La solicitud ya fue procesada correctamente.'
                           ELSE N'La solicitud ya se encuentra en proceso.' END;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nEmpleado=empleadoId,
        @cNombre=LOWER(NULLIF(LTRIM(RTRIM(nombreUsuario)),'')),
        @cHash=NULLIF(LTRIM(RTRIM(passwordHash)),''),
        @cCorreo=NULLIF(LTRIM(RTRIM(correoSeguridad)),N''),
        @bCambio=COALESCE(requiereCambioPassword,CONVERT(BIT,1))
    FROM OPENJSON(@cJson,'$.usuario')
    WITH
    (
        empleadoId BIGINT '$.empleadoId',
        nombreUsuario VARCHAR(80) '$.nombreUsuario',
        passwordHash VARCHAR(512) '$.passwordHash',
        correoSeguridad NVARCHAR(320) '$.correoSeguridad',
        requiereCambioPassword BIT '$.requiereCambioPassword'
    );

    SET @cCorreoN=LOWER(@cCorreo);
    SET @cRolesJson=JSON_QUERY(@cJson,'$.roles');

    IF NOT EXISTS
    (
        SELECT 1
        FROM [org].[Empleado] E
        INNER JOIN [org].[Persona] P ON P.persona_id=E.empleado_id
        WHERE E.empleado_id=@nEmpleado
          AND E.estado=1
          AND P.estado=1
    )
       OR @cNombre IS NULL
       OR LEN(@cNombre)<3
       OR @cHash IS NULL
       OR LEFT(@cHash,10)<>'$argon2id$'
       OR @cCorreo IS NULL
       OR @cCorreo NOT LIKE N'%_@_%._%'
    BEGIN
        SET @cMensaje=N'Complete correctamente los datos de la cuenta.';
        GOTO Fallar;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [seg].[Usuario]
        WHERE persona_id=@nEmpleado OR nombre_usuario=@cNombre
    )
    BEGIN
        SET @cMensaje=N'El empleado ya tiene una cuenta o el nombre de usuario no está disponible.';
        GOTO Fallar;
    END;

    EXEC [seg].[PA_Autorizacion_Sel_ValidarDelegacionRoles]
         @nUsuarioActorId=@nUsuario,
         @cRolesJson=@cRolesJson,
         @bRequerirAlMenosUno=1,
         @bResultado=@bDelegable OUTPUT,
         @cMensaje=@cMsgDelegacion OUTPUT;

    IF @bDelegable=0
    BEGIN
        SET @cMensaje=@cMsgDelegacion;
        GOTO Fallar;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        INSERT [seg].[Usuario]
        (
            persona_id,nombre_usuario,password_hash,estado,fecha_creacion,estado_cuenta,
            intentos_fallidos,requiere_cambio_password,segundo_factor_habilitado,token_version
        )
        VALUES
        (
            @nEmpleado,@cNombre,@cHash,1,SYSUTCDATETIME(),'PENDIENTE_VALIDACION',
            0,@bCambio,0,1
        );

        SET @nUsuarioNuevoId=SCOPE_IDENTITY();

        INSERT [seg].[UsuarioCorreoSeguridad]
        (
            usuario_id,correo,correo_normalizado,es_principal,es_verificado,
            fecha_verificacion,fecha_desde,fecha_hasta,creado_por_usuario_id,
            motivo_cambio,estado
        )
        VALUES
        (
            @nUsuarioNuevoId,@cCorreo,@cCorreoN,1,0,NULL,SYSUTCDATETIME(),NULL,
            @nUsuario,N'Correo inicial de seguridad.',1
        );

        INSERT [seg].[UsuarioRol]
        (
            usuario_id,rol_id,fecha_desde,fecha_hasta,estado,asignado_por_usuario_id
        )
        SELECT
            @nUsuarioNuevoId,
            J.rolId,
            SYSUTCDATETIME(),
            NULL,
            1,
            @nUsuario
        FROM
        (
            SELECT DISTINCT rolId
            FROM OPENJSON(@cRolesJson)
            WITH(rolId BIGINT '$.rolId')
        ) J;

        SET @cIdent=CONVERT(NVARCHAR(200),@nUsuarioNuevoId);

        EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
             @nUsuario,@nSesion,@nDisp,@nModulo,'CREAR','seg','Usuario',@cIdent,
             NULL,NULL,NULL,'estado_cuenta',NULL,'PENDIENTE_VALIDACION',
             @cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;

        /* Confirmar datos e idempotencia juntos. */

        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',
             @cEsquemaEntidad='seg',@cNombreEntidad='Usuario',
             @cIdentificadorResultado=@cIdent,@cCodigoResultado='USUARIO_CREADO',
             @bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado=1;
        SET @cMensaje=N'Cuenta creada correctamente. Debe validar su correo antes de ingresar.';
        GOTO __DESCO_Salida;
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
        SET @cMensaje=N'No se pudo crear la cuenta. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Ins_CrearCuenta',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0
        EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
             @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',
             @cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,
             @cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;

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
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Ins_CrearCuenta',
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

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Ins_CrearCuenta',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;
IF @bResultado = 0
    SELECT @nUsuarioNuevoId = NULL;

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
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Ins_CrearCuenta',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_UsuarioAdmin_Ins_CrearCuenta',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
