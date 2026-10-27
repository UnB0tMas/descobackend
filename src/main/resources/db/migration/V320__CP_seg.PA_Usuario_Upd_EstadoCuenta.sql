IF OBJECT_ID(N'[seg].[PA_Usuario_Upd_EstadoCuenta]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Upd_EstadoCuenta];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Upd_EstadoCuenta
' Descripción             : Actualiza el estado de la cuenta de usuario.
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
    EXEC [seg].[PA_Usuario_Upd_EstadoCuenta]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Upd_EstadoCuenta]
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
    SET XACT_ABORT ON;

    DECLARE
        @nUsuarioActorId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @nUsuarioObjetivoId BIGINT,
        @cAccion VARCHAR(20),
        @cMotivo NVARCHAR(500),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @cPermiso VARCHAR(40),
        @bAutorizado BIT,
        @nSesionActorId BIGINT,
        @nDispositivoActorId BIGINT,
        @cEstadoAnterior VARCHAR(25),
        @cEstadoNuevo VARCHAR(25),
        @nSesionesRevocadas INT,
        @nAuditoriaId BIGINT,
        @nTransicionId BIGINT,
        @bCorreoVerificado BIT,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo actualizar la cuenta. Intente nuevamente.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioActorId = usuarioActorId,
        @gSesionPublicaId = sesionPublicaId,
        @nUsuarioObjetivoId = usuarioId,
        @cAccion = UPPER(NULLIF(LTRIM(RTRIM(accion)), '')),
        @cMotivo = NULLIF(LTRIM(RTRIM(motivo)), N''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioActorId BIGINT '$.usuarioActorId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        usuarioId BIGINT '$.usuarioId',
        accion VARCHAR(20) '$.accion',
        motivo NVARCHAR(500) '$.motivo',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    IF @nUsuarioActorId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @nUsuarioObjetivoId IS NULL
       OR @cAccion NOT IN ('DESHABILITAR','REACTIVAR')
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    IF @cAccion = 'DESHABILITAR' AND @cMotivo IS NULL
    BEGIN
        SET @cMensaje = N'Ingrese el motivo de la deshabilitacion.';
        GOTO __DESCO_Salida;
    END;

    IF @nUsuarioActorId = @nUsuarioObjetivoId
       AND @cAccion = 'DESHABILITAR'
    BEGIN
        SET @cMensaje = N'No puede deshabilitar su propia cuenta desde esta opcion.';
        GOTO __DESCO_Salida;
    END;

    SET @cPermiso = CASE WHEN @cAccion = 'DESHABILITAR'
                         THEN 'USUARIOS_RETIRAR'
                         ELSE 'USUARIOS_CONFIRMAR' END;

    EXEC [seg].[PA_Autorizacion_Sel_ValidarPermiso]
         @nUsuarioId = @nUsuarioActorId,
         @gSesionPublicaId = @gSesionPublicaId,
         @cCodigoPermiso = @cPermiso,
         @bAutorizado = @bAutorizado OUTPUT;

    IF ISNULL(@bAutorizado,0) = 0
    BEGIN
        SET @cMensaje = N'No cuenta con permiso para realizar esta accion.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nSesionActorId = S.sesion_usuario_id,
        @nDispositivoActorId = S.dispositivo_usuario_id
    FROM [seg].[SesionUsuario] S
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.usuario_id = @nUsuarioActorId;

    SELECT
        @cEstadoAnterior = U.estado_cuenta
    FROM [seg].[Usuario] U
    WHERE U.usuario_id = @nUsuarioObjetivoId
      AND U.estado = 1;

    IF @cEstadoAnterior IS NULL
    BEGIN
        SET @cMensaje = N'La cuenta seleccionada no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    IF @cAccion = 'DESHABILITAR'
       AND @cEstadoAnterior IN ('DESHABILITADA','RETIRADA')
    BEGIN
        SET @cMensaje = N'La cuenta seleccionada ya se encuentra deshabilitada.';
        GOTO __DESCO_Salida;
    END;

    IF @cAccion = 'REACTIVAR'
       AND @cEstadoAnterior = 'RETIRADA'
    BEGIN
        SET @cMensaje = N'La cuenta pertenece a un empleado retirado y no puede reactivarse desde esta opcion.';
        GOTO __DESCO_Salida;
    END;

    IF @cAccion = 'REACTIVAR'
       AND NOT EXISTS
       (
           SELECT 1
           FROM [seg].[Usuario] U
           INNER JOIN [org].[Empleado] E ON E.empleado_id = U.persona_id
           INNER JOIN [org].[Persona] P ON P.persona_id = U.persona_id
           WHERE U.usuario_id = @nUsuarioObjetivoId
             AND E.estado = 1
             AND E.fecha_cese IS NULL
             AND P.estado = 1
       )
    BEGIN
        SET @cMensaje = N'El empleado de la cuenta no se encuentra vigente.';
        GOTO __DESCO_Salida;
    END;

    SET @bCorreoVerificado =
        CASE WHEN EXISTS
        (
            SELECT 1
            FROM [seg].[UsuarioCorreoSeguridad] UCS
            WHERE UCS.usuario_id = @nUsuarioObjetivoId
              AND UCS.estado = 1
              AND UCS.es_principal = 1
              AND UCS.es_verificado = 1
              AND UCS.fecha_hasta IS NULL
        ) THEN 1 ELSE 0 END;

    SET @cEstadoNuevo =
        CASE
            WHEN @cAccion = 'DESHABILITAR' THEN 'DESHABILITADA'
            WHEN @bCorreoVerificado = 1 THEN 'ACTIVA'
            ELSE 'PENDIENTE_VALIDACION'
        END;

    IF @gCorrelacionId IS NULL SET @gCorrelacionId = NEWID();

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        IF @cAccion = 'DESHABILITAR'
        BEGIN
            EXEC [seg].[PA_Seguridad_Upd_RevocarSesionesUsuario]
                 @nUsuarioId = @nUsuarioObjetivoId,
                 @cMotivo = N'Cuenta deshabilitada.',
                 @nSesionExcluirId = NULL,
                 @bIncrementarTokenVersion = 1,
                 @nCantidadSesionesRevocadas = @nSesionesRevocadas OUTPUT;
        END;

        UPDATE [seg].[Usuario]
        SET
            estado_cuenta = @cEstadoNuevo,
            intentos_fallidos = 0,
            fecha_ultimo_intento_fallido = NULL,
            bloqueado_hasta = NULL
        WHERE usuario_id = @nUsuarioObjetivoId
          AND estado = 1;

        EXEC [auditoria].[PA_Auditoria_Ins_TransicionEstado]
             @nUsuarioId = @nUsuarioActorId,
             @nSesionUsuarioId = @nSesionActorId,
             @nDispositivoUsuarioId = @nDispositivoActorId,
             @nModuloId = NULL,
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'Usuario',
             @cIdentificador = @nUsuarioObjetivoId,
             @cCampoEstado = N'estado_cuenta',
             @cEstadoAnterior = @cEstadoAnterior,
             @cEstadoNuevo = @cEstadoNuevo,
             @cMotivo = @cMotivo,
             @gCorrelacionId = @gCorrelacionId,
             @nTransicionEstadoId = @nTransicionId OUTPUT;

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioActorId,
             @nSesionUsuarioId = @nSesionActorId,
             @nDispositivoUsuarioId = @nDispositivoActorId,
             @cAccion = @cAccion,
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'Usuario',
             @cIdentificador = @nUsuarioObjetivoId,
             @cMotivo = @cMotivo,
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint = N'/api/usuarios/estado',
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = CASE WHEN @cAccion = 'DESHABILITAR'
                             THEN N'Cuenta deshabilitada correctamente.'
                             ELSE N'Cuenta reactivada correctamente.' END;
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
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo actualizar la cuenta. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Upd_EstadoCuenta',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_EstadoCuenta',
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
    @cProcedimiento = N'seg.PA_Usuario_Upd_EstadoCuenta',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Upd_EstadoCuenta',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
