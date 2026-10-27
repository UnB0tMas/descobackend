IF OBJECT_ID(N'[seg].[PA_UsuarioAdmin_Upd_EstadoCuenta]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioAdmin_Upd_EstadoCuenta];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_UsuarioAdmin_Upd_EstadoCuenta
' Descripción             : Actualiza el estado de una cuenta desde administración.
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
    EXEC [seg].[PA_UsuarioAdmin_Upd_EstadoCuenta]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_UsuarioAdmin_Upd_EstadoCuenta]
(
    @cJson NVARCHAR(MAX),
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
        @cAccion VARCHAR(20), @cPermiso VARCHAR(40), @nUsuarioObjetivo BIGINT,
        @cMotivo NVARCHAR(500), @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),
        @bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,
        @cAnterior VARCHAR(25),@cNuevo VARCHAR(25),@bCorreoVerificado BIT,@nRevocadas INT,@cIdent NVARCHAR(200);

    SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar el estado de la cuenta.';
    IF @cJson IS NULL OR ISJSON(@cJson)<>1 BEGIN SET @cMensaje=N'La solicitud no es válida.';
 GOTO __DESCO_Salida;
 END;

    SELECT @nUsuarioObjetivo=usuarioId,@cAccion=UPPER(NULLIF(LTRIM(RTRIM(accion)),'')),@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'')
    FROM OPENJSON(@cJson,'$.usuario') WITH(usuarioId BIGINT '$.usuarioId',accion VARCHAR(20) '$.accion',motivo NVARCHAR(500) '$.motivo');

    IF @nUsuarioObjetivo IS NULL OR @cAccion NOT IN('DESHABILITAR','REACTIVAR')
    BEGIN SET @cMensaje=N'Seleccione una cuenta y una acción válida.';
 GOTO __DESCO_Salida;
 END;
    IF @cAccion='DESHABILITAR' AND @cMotivo IS NULL
    BEGIN SET @cMensaje=N'Indique el motivo de la deshabilitación.';
 GOTO __DESCO_Salida;
 END;

    SET @cPermiso=CASE WHEN @cAccion='DESHABILITAR' THEN 'USUARIOS_RETIRAR' ELSE 'USUARIOS_CONFIRMAR' END;

    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
         @cJson=@cJson,@cCodigoPermiso=@cPermiso,@cAmbito='USUARIO_ESTADO',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,
         @nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,
         @cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,
         @cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,
         @bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;

    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
 SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
 GOTO __DESCO_Salida;
 END;

    IF @nUsuario=@nUsuarioObjetivo AND @cAccion='DESHABILITAR'
    BEGIN SET @cMensaje=N'No puede deshabilitar su propia cuenta desde esta opción.';
 GOTO Fallar;
 END;

    SELECT @cAnterior=U.estado_cuenta
    FROM seg.Usuario U WHERE U.usuario_id=@nUsuarioObjetivo AND U.estado=1;
    IF @cAnterior IS NULL BEGIN SET @cMensaje=N'La cuenta seleccionada no está disponible.';
 GOTO Fallar;
 END;
    IF @cAccion='DESHABILITAR' AND @cAnterior IN('DESHABILITADA','RETIRADA')
    BEGIN SET @cMensaje=N'La cuenta seleccionada ya se encuentra deshabilitada.';
 GOTO Fallar;
 END;
    IF @cAccion='REACTIVAR' AND @cAnterior='RETIRADA'
    BEGIN SET @cMensaje=N'La cuenta pertenece a un empleado retirado y no puede reactivarse desde esta opción.';
 GOTO Fallar;
 END;
    IF @cAccion='REACTIVAR' AND NOT EXISTS(
        SELECT 1 FROM seg.Usuario U INNER JOIN org.Empleado E ON E.empleado_id=U.persona_id INNER JOIN org.Persona P ON P.persona_id=U.persona_id
        WHERE U.usuario_id=@nUsuarioObjetivo AND E.estado=1 AND E.fecha_cese IS NULL AND P.estado=1)
    BEGIN SET @cMensaje=N'El empleado de la cuenta no se encuentra vigente.';
 GOTO Fallar;
 END;

    SET @bCorreoVerificado=CASE WHEN EXISTS(SELECT 1 FROM seg.UsuarioCorreoSeguridad C WHERE C.usuario_id=@nUsuarioObjetivo AND C.estado=1 AND C.es_principal=1 AND C.es_verificado=1 AND C.fecha_hasta IS NULL) THEN 1 ELSE 0 END;
    SET @cNuevo=CASE WHEN @cAccion='DESHABILITAR' THEN 'DESHABILITADA' WHEN @bCorreoVerificado=1 THEN 'ACTIVA' ELSE 'PENDIENTE_VALIDACION' END;

    BEGIN TRY
      BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
      IF @cAccion='DESHABILITAR'
        EXEC seg.PA_Seguridad_Upd_RevocarSesionesUsuario @nUsuarioId=@nUsuarioObjetivo,@cMotivo=N'Cuenta deshabilitada.',@nSesionExcluirId=NULL,@bIncrementarTokenVersion=1,@nCantidadSesionesRevocadas=@nRevocadas OUTPUT;

      UPDATE seg.Usuario SET estado_cuenta=@cNuevo,intentos_fallidos=0,fecha_ultimo_intento_fallido=NULL,bloqueado_hasta=NULL WHERE usuario_id=@nUsuarioObjetivo AND estado=1;
      SET @cIdent=CONVERT(NVARCHAR(200),@nUsuarioObjetivo);
      EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,@cAccion,'seg','Usuario',@cIdent,NULL,NULL,@cMotivo,'estado_cuenta',@cAnterior,@cNuevo,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
      /* Confirmar datos e idempotencia juntos. */
      EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='seg',@cNombreEntidad='Usuario',@cIdentificadorResultado=@cIdent,@cCodigoResultado='USUARIO_ESTADO_ACTUALIZADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
 SET @cMensaje=CASE WHEN @cAccion='DESHABILITAR' THEN N'Cuenta deshabilitada correctamente.' ELSE N'Cuenta reactivada correctamente.' END;
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
      SET @cMensaje=N'No se pudo actualizar la cuenta. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Upd_EstadoCuenta',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;

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
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Upd_EstadoCuenta',
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
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Upd_EstadoCuenta',
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
    @cProcedimiento = N'seg.PA_UsuarioAdmin_Upd_EstadoCuenta',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_UsuarioAdmin_Upd_EstadoCuenta',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
