IF OBJECT_ID(N'[comercial].[PA_OperativoVenta_Upd_Cerrar]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_OperativoVenta_Upd_Cerrar];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_OperativoVenta_Upd_Cerrar
' Descripción             : Cierra un operativo de venta.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [comercial].[PA_OperativoVenta_Upd_Cerrar]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_OperativoVenta_Upd_Cerrar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nId BIGINT,@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200),@nNoParticiparon INT,@cPostParticipantes NVARCHAR(MAX);
    SELECT @bResultado=0,@cMensaje=N'No se pudo completar la acción.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson=@cJson,@cCodigoPermiso='OPERATIVOS_CONFIRMAR|OPERATIVOS_APROBAR',@cAmbito='OPERATIVO_CERRAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
 SELECT @nId=operativoVentaId,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'') FROM OPENJSON(@cJson,'$.operativo') WITH(operativoVentaId BIGINT '$.operativoVentaId',motivo NVARCHAR(500) '$.motivo');
IF NOT EXISTS(SELECT 1 FROM comercial.OperativoVenta WHERE operativo_venta_id=@nId AND estado=1 AND estado_proceso='EN_RECEPCION') BEGIN SET @cMensaje=N'El operativo no se encuentra en un estado válido para esta acción.';
GOTO Fallar;
END;
DECLARE @r INT,@a INT,@d INT,@p INT,@di INT;
EXEC comercial.PA_Jabas_Sel_SaldoInterno @nOperativoVentaId=@nId,@nOperativoSocioId=NULL,@nRecibidas=@r OUTPUT,@nAsignadas=@a OUTPUT,@nDevueltas=@d OUTPUT,@nPendientes=@p OUTPUT,@nDisponibles=@di OUTPUT;
IF @p>0 BEGIN SET @cMensaje=N'Registre las devoluciones pendientes de jabas antes de cerrar el operativo.';
GOTO Fallar;
END;
IF EXISTS(SELECT 1 FROM comercial.EntregaSocio E INNER JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id WHERE OS.operativo_venta_id=@nId AND E.estado=1 AND E.estado_proceso='REGISTRADA') BEGIN SET @cMensaje=N'Confirme o anule las entregas pendientes antes de cerrar el operativo.';
GOTO Fallar;
END;
IF EXISTS(SELECT 1 FROM comercial.IncidenciaOperativa WHERE operativo_venta_id=@nId AND estado=1 AND estado_incidencia IN('ABIERTA','EN_REVISION')) BEGIN SET @cMensaje=N'Resuelva las incidencias pendientes antes de cerrar el operativo.';
GOTO Fallar;
END;
 BEGIN TRY
BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
SELECT @nNoParticiparon=COUNT(*)
FROM comercial.OperativoSocio
WHERE operativo_venta_id=@nId AND estado=1 AND estado_participacion='PROGRAMADO';
IF @nNoParticiparon>0
BEGIN
    UPDATE comercial.OperativoSocio
    SET estado_participacion='NO_PARTICIPO'
    WHERE operativo_venta_id=@nId AND estado=1 AND estado_participacion='PROGRAMADO';

    SET @cIdent=CONCAT(N'OPERATIVO:',CONVERT(NVARCHAR(40),@nId));
    SET @cPostParticipantes=N'{"participantesMarcadosNoParticiparon":'+CONVERT(NVARCHAR(20),@nNoParticiparon)+N'}';
    EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
         @nUsuarioId=@nUsuario,@nSesionUsuarioId=@nSesion,@nDispositivoUsuarioId=@nDisp,@nModuloId=@nModulo,
         @cAccion='CIERRE_PARTICIPANTES',@cEsquemaEntidad='comercial',@cNombreEntidad='OperativoSocio',
         @cIdentificador=@cIdent,@cDatosAnteriores=NULL,@cDatosPosteriores=@cPostParticipantes,@cMotivo=@cMotivo,
         @cCampoEstado='estado_participacion',@cEstadoAnterior='PROGRAMADO',@cEstadoNuevo='NO_PARTICIPO',
         @cIp=@cIp,@gCorrelacionId=@gCorr,@gSolicitudId=@gSol,@cEndpoint=@cEnd,
         @nAuditoriaEventoId=@nAud OUTPUT,@nTransicionEstadoId=@nTrans OUTPUT;
END;
UPDATE comercial.OperativoVenta
SET estado_proceso='CERRADO',fecha_fin_real=COALESCE(fecha_fin_real,SYSUTCDATETIME())
WHERE operativo_venta_id=@nId;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'CERRADO','comercial','OperativoVenta',@cIdent,NULL,NULL,@cMotivo,'estado_proceso','EN_RECEPCION','CERRADO',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='OperativoVenta',@cIdentificadorResultado=@cIdent,@cCodigoResultado='OPERATIVO_CERRADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Operativo cerrado correctamente.';
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
SET @cMensaje=N'No se pudo completar la acción. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_OperativoVenta_Upd_Cerrar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
 
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
    @cProcedimiento = N'comercial.PA_OperativoVenta_Upd_Cerrar',
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
    @cProcedimiento = N'comercial.PA_OperativoVenta_Upd_Cerrar',
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
    @cProcedimiento = N'comercial.PA_OperativoVenta_Upd_Cerrar',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_OperativoVenta_Upd_Cerrar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
