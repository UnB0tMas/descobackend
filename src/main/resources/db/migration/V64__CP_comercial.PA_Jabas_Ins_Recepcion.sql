IF OBJECT_ID(N'[comercial].[PA_Jabas_Ins_Recepcion]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Jabas_Ins_Recepcion];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Jabas_Ins_Recepcion
' Descripción             : Registra la recepción de jabas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo de referencia: reemplazar valores e identificadores por datos válidos.
    -- El JSON debe incluir el contexto y los campos exigidos por este PA.
    DECLARE
        @nJabaMovimientoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [comercial].[PA_Jabas_Ins_Recepcion]
        @cJson = N'{}',
        @nJabaMovimientoId = @nJabaMovimientoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nJabaMovimientoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Jabas_Ins_Recepcion](@cJson NVARCHAR(MAX),@nJabaMovimientoId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS BEGIN
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nOpVenta BIGINT,@nCantidad INT,@cReferencia VARCHAR(80),@cObs NVARCHAR(300),@cEstado VARCHAR(20),@cIdent NVARCHAR(200),@nTotal INT;
SELECT @bResultado=0,@cMensaje=N'No se pudo registrar la recepción de jabas.';
EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='JABAS_EDITAR',@cAmbito='JABAS_RECEPCION',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
IF @bRep=1 BEGIN SET @nJabaMovimientoId=CASE WHEN @cEstadoOp='COMPLETADA' THEN TRY_CONVERT(BIGINT,@cIdRes) ELSE NULL END;
 SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
 SET @nJabaMovimientoId=NULL;
SELECT @nOpVenta=operativoVentaId,@nCantidad=cantidad,@cReferencia=NULLIF(LTRIM(RTRIM(referencia)),''),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N'') FROM OPENJSON(@cJson,'$.jabas') WITH(operativoVentaId BIGINT '$.operativoVentaId',cantidad INT '$.cantidad',referencia VARCHAR(80) '$.referencia',observacion NVARCHAR(300) '$.observacion');
SELECT @cEstado=estado_proceso FROM comercial.OperativoVenta WHERE operativo_venta_id=@nOpVenta AND estado=1;
IF @cEstado NOT IN('PLANIFICADO','EN_RECEPCION') OR @nCantidad IS NULL OR @nCantidad<=0 BEGIN SET @cMensaje=N'El operativo o la cantidad de jabas no es válida.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.OperativoVenta O INNER JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id WHERE O.operativo_venta_id=@nOpVenta AND C.estado=1 AND C.estado_proceso='ACTIVA') BEGIN SET @cMensaje=N'La campaña debe estar activa para recibir jabas.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
INSERT comercial.JabaMovimiento(operativo_venta_id,operativo_socio_id,jaba_asignacion_id,jaba_devolucion_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,motivo,referencia,estado) VALUES(@nOpVenta,NULL,NULL,NULL,'RECEPCION',@nCantidad,SYSUTCDATETIME(),@nUsuario,@cObs,@cReferencia,1);
SET @nJabaMovimientoId=SCOPE_IDENTITY();
SELECT @nTotal=COALESCE(SUM(CASE WHEN tipo_movimiento IN('RECEPCION','AJUSTE_ENTRADA') THEN cantidad WHEN tipo_movimiento='AJUSTE_SALIDA' THEN -cantidad ELSE 0 END),0) FROM comercial.JabaMovimiento WHERE operativo_venta_id=@nOpVenta AND estado=1;
UPDATE comercial.OperativoVenta SET cantidad_jabas_recibidas=@nTotal,estado_proceso='EN_RECEPCION',fecha_inicio_real=COALESCE(fecha_inicio_real,SYSUTCDATETIME()) WHERE operativo_venta_id=@nOpVenta;
SET @cIdent=CONVERT(NVARCHAR(200),@nJabaMovimientoId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'RECIBIR','comercial','JabaMovimiento',@cIdent,NULL,NULL,@cObs,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
IF @cEstado='PLANIFICADO' BEGIN DECLARE @cIdentOperativo NVARCHAR(200);
 SET @cIdentOperativo=CONVERT(NVARCHAR(200),@nOpVenta);
 EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'INICIAR','comercial','OperativoVenta',@cIdentOperativo,NULL,NULL,N'Inicio automático al registrar la primera recepción de jabas.','estado_proceso','PLANIFICADO','EN_RECEPCION',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
 END;
/* Confirmar datos e idempotencia juntos. */EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='JabaMovimiento',@cIdentificadorResultado=@cIdent,@cCodigoResultado='JABAS_RECIBIDAS',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Recepción de jabas registrada correctamente.';
GOTO __DESCO_Salida;
 END TRY BEGIN CATCH
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
SET @cMensaje=N'No se pudo registrar la recepción de jabas. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_Jabas_Ins_Recepcion',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar: IF @nOp IS NOT NULL AND @bResultado=0 EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
 
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
    @cProcedimiento = N'comercial.PA_Jabas_Ins_Recepcion',
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
    @cProcedimiento = N'comercial.PA_Jabas_Ins_Recepcion',
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
    SELECT @nJabaMovimientoId = NULL;

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
    @cProcedimiento = N'comercial.PA_Jabas_Ins_Recepcion',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_Jabas_Ins_Recepcion',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
