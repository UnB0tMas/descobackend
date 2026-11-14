-- DESCO / APAPPSS: vigencia comercial y liquidaciones pendientes.
-- Vencimiento automático: ACTIVA -> VENCIDA, sin cerrar el expediente financiero.
-- Todas las fechas comerciales se comparan en horario de Perú (UTC-05).
IF EXISTS (SELECT 1 FROM sys.check_constraints
           WHERE parent_object_id = OBJECT_ID(N'comercial.CampaniaVenta', N'U')
             AND name = N'CK_CampaniaVenta_EstadoProceso')
    ALTER TABLE comercial.CampaniaVenta DROP CONSTRAINT CK_CampaniaVenta_EstadoProceso;
GO
ALTER TABLE comercial.CampaniaVenta WITH CHECK
 ADD CONSTRAINT CK_CampaniaVenta_EstadoProceso
 CHECK (estado_proceso IN ('PLANIFICACION','ACTIVA','VENCIDA','CERRADA','CANCELADA'));
GO
IF OBJECT_ID(N'comercial.CampaniaVencimientoLog', N'U') IS NULL
BEGIN
    CREATE TABLE comercial.CampaniaVencimientoLog
    (
        campania_vencimiento_log_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_CampaniaVencimientoLog PRIMARY KEY,
        campania_venta_id BIGINT NOT NULL,
        estado_anterior VARCHAR(20) NOT NULL,
        estado_nuevo VARCHAR(20) NOT NULL,
        fecha_hora_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_CampaniaVencimientoLog_Fecha DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_CampaniaVencimientoLog_Campania
            FOREIGN KEY (campania_venta_id) REFERENCES comercial.CampaniaVenta (campania_venta_id)
    );
END;
GO
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaVenta_Upd_Vencer
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Vencidas TABLE
    (
        campania_venta_id BIGINT NOT NULL,
        estado_anterior VARCHAR(20) NOT NULL,
        estado_nuevo VARCHAR(20) NOT NULL,
        fecha_hora_utc DATETIME2(0) NOT NULL
    );
    -- La expiración NO invoca el cierre financiero y no altera liquidaciones ni pagos.
    BEGIN TRANSACTION;
    UPDATE C
       SET estado_proceso = 'VENCIDA'
    OUTPUT inserted.campania_venta_id, deleted.estado_proceso,
           inserted.estado_proceso, SYSUTCDATETIME()
      INTO @Vencidas
           (campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc)
      FROM comercial.CampaniaVenta C
     WHERE C.estado = 1
       AND C.estado_proceso = 'ACTIVA'
       AND C.fecha_fin < CONVERT(DATE, DATEADD(HOUR, -5, SYSUTCDATETIME()));
    INSERT INTO comercial.CampaniaVencimientoLog
        (campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc)
    SELECT campania_venta_id, estado_anterior, estado_nuevo, fecha_hora_utc
    FROM @Vencidas;
    COMMIT TRANSACTION;
    SELECT COUNT(*) AS vencidas FROM @Vencidas;
END;
GO

-- Proteger también los endpoints legacy de liquidaciones (no solo E5).
CREATE OR ALTER TRIGGER finanzas.TR_LiquidacionSocio_CampaniaHabilitada
ON finanzas.LiquidacionSocio
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1
        FROM inserted L
        INNER JOIN comercial.ParticipacionCampaniaSocio P
            ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
        INNER JOIN comercial.CampaniaVenta C
            ON C.campania_venta_id=P.campania_venta_id
        WHERE C.estado<>1
           OR C.estado_proceso NOT IN ('ACTIVA','VENCIDA','CERRADA')
           OR EXISTS (SELECT 1 FROM comercial.CierreCampaniaE5 X
                      WHERE X.campania_venta_id=C.campania_venta_id)
    )
        THROW 51701, N'La campaña no está habilitada para nuevas liquidaciones.', 1;
END;
GO

-- El endpoint existente conserva permisos e idempotencia; se valida el vencimiento al activar.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Activar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bModoGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@nId BIGINT,@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200),@dInicio DATE,@dFin DATE,@nAsociacion BIGINT;
    SELECT @bResultado=0,@cMensaje=N'No se pudo completar la acción.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_CONFIRMAR|CAMPANIAS_APROBAR',@cAmbito='CAMPANIA_ACTIVAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SELECT @nId=campaniaVentaId,@nUotSolicitada=uotId,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'')
FROM OPENJSON(@cJson,'$.campania')
WITH(campaniaVentaId BIGINT '$.campaniaVentaId',uotId BIGINT '$.uotId',motivo NVARCHAR(500) '$.motivo');
IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId;
EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,NULL,1,@nUot OUTPUT,@bModoGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
IF seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_CONFIRMAR')<>1
   AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_APROBAR')<>1
BEGIN SET @cMensaje=N'No tiene permiso para activar la campaña en esta UOT.'; GOTO Fallar; END;
IF @nId IS NULL BEGIN SET @cMensaje=N'Seleccione una campaña.';
GOTO Fallar;
END;
SELECT @dInicio=fecha_inicio,@dFin=fecha_fin,@nAsociacion=asociacion_id
FROM comercial.CampaniaVenta
WHERE campania_venta_id=@nId AND uot_id=@nUot AND estado=1 AND estado_proceso='PLANIFICACION';
IF @nAsociacion IS NULL BEGIN SET @cMensaje=N'La campaña no se encuentra en un estado válido para activarla.';
GOTO Fallar;
END;
IF @dInicio IS NULL OR @dFin IS NULL OR @dFin<@dInicio
   OR @dFin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))
BEGIN SET @cMensaje=N'La campaña ya venció o tiene fechas inválidas. Corrija la vigencia antes de activarla.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio WHERE campania_venta_id=@nId AND estado=1 AND estado_participacion='ACTIVO')
BEGIN SET @cMensaje=N'Incluya al menos un socio antes de activar la campaña.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.PrecioComercial WHERE campania_venta_id=@nId AND estado=1 AND CONVERT(DATE,fecha_vigencia_desde)<=COALESCE(@dFin,@dInicio) AND (fecha_vigencia_hasta IS NULL OR CONVERT(DATE,fecha_vigencia_hasta)>=@dInicio))
BEGIN SET @cMensaje=N'Registre al menos un precio vigente antes de activar la campaña.';
GOTO Fallar;
END;
IF NOT EXISTS
(
    SELECT 1
    FROM comercial.ParticipacionCampaniaSocio PCS
    INNER JOIN org.SocioAsociacion SA
        ON SA.socio_asociacion_id=PCS.socio_asociacion_id AND SA.estado=1
    INNER JOIN prod.PredioTitularidad PT
        ON PT.socio_id=SA.socio_id AND PT.estado=1
    INNER JOIN prod.Parcela P
        ON P.predio_id=PT.predio_id AND P.estado=1
    INNER JOIN prod.ParcelaCultivo PC
        ON PC.parcela_id=P.parcela_id AND PC.estado=1 AND PC.situacion_cultivo='ACTIVO'
    INNER JOIN prod.DisponibilidadProduccion DP
        ON DP.parcela_cultivo_id=PC.parcela_cultivo_id AND DP.estado=1
       AND DP.estado_estimacion IN('ESTIMADA','CONFIRMADA')
    WHERE PCS.campania_venta_id=@nId
      AND PCS.estado=1
      AND PCS.estado_participacion='ACTIVO'
      AND SA.asociacion_id=@nAsociacion
      AND PT.fecha_desde<=COALESCE(@dFin,@dInicio)
      AND (PT.fecha_hasta IS NULL OR PT.fecha_hasta>=@dInicio)
      AND (@dFin IS NULL OR DP.disponible_desde<=@dFin)
      AND (DP.disponible_hasta IS NULL OR DP.disponible_hasta>=@dInicio)
)
BEGIN SET @cMensaje=N'No hay producción disponible de los participantes para las fechas de la campaña.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
UPDATE comercial.CampaniaVenta SET estado_proceso='ACTIVA' WHERE campania_venta_id=@nId AND uot_id=@nUot;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'ACTIVA','comercial','CampaniaVenta',@cIdent,NULL,NULL,@cMotivo,'estado_proceso','PLANIFICACION','ACTIVA',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='CampaniaVenta',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CAMPANIA_ACTIVA',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Campaña activada.';
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Upd_Activar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- La operación de cierre mantiene todas sus validaciones y auditoría.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Cerrar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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

/* DESCO_JEFE_UOT_33_33_33_43_V1_20260826 */ SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bModoGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@nId BIGINT,@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200);
    SELECT @bResultado=0,@cMensaje=N'No se pudo completar la acción.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_CONFIRMAR|CAMPANIAS_APROBAR',@cAmbito='CAMPANIA_CERRAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SELECT @nId=campaniaVentaId,@nUotSolicitada=uotId,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'') FROM OPENJSON(@cJson,'$.campania') WITH(campaniaVentaId BIGINT '$.campaniaVentaId',uotId BIGINT '$.uotId',motivo NVARCHAR(500) '$.motivo');
IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId;
EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,NULL,1,@nUot OUTPUT,@bModoGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
IF seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_CONFIRMAR')<>1
   AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_APROBAR')<>1
BEGIN SET @cMensaje=N'No tiene permiso para cerrar la campaña en esta UOT.'; GOTO Fallar; END;
IF @nId IS NULL BEGIN SET @cMensaje=N'Seleccione una campaña.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId AND uot_id=@nUot AND estado=1 AND estado_proceso='ACTIVA') BEGIN SET @cMensaje=N'La campaña no se encuentra en un estado válido para esta acción.';
GOTO Fallar;
END;
IF EXISTS(SELECT 1 FROM comercial.OperativoVenta WHERE campania_venta_id=@nId AND estado=1 AND estado_proceso NOT IN('CERRADO','CANCELADO')) BEGIN SET @cMensaje=N'Cierre o cancele los operativos pendientes antes de cerrar la campaña.';
GOTO Fallar;
END;
IF EXISTS(SELECT 1 FROM comercial.IncidenciaOperativa I INNER JOIN comercial.OperativoVenta O ON O.operativo_venta_id=I.operativo_venta_id WHERE O.campania_venta_id=@nId AND I.estado=1 AND I.estado_incidencia IN('ABIERTA','EN_REVISION')) BEGIN SET @cMensaje=N'Resuelva las incidencias pendientes antes de cerrar la campaña.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
UPDATE comercial.CampaniaVenta SET estado_proceso='CERRADA',fecha_fin=COALESCE(fecha_fin,CONVERT(DATE,SYSUTCDATETIME())) WHERE campania_venta_id=@nId AND uot_id=@nUot;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'CERRADA','comercial','CampaniaVenta',@cIdent,NULL,NULL,@cMotivo,'estado_proceso','ACTIVA','CERRADA',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='CampaniaVenta',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CAMPANIA_CERRADA',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Campaña cerrada.';
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Cerrar',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Cerrar',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Cerrar',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Cerrar',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Upd_Cerrar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO

-- Lecturas con estado efectivo para evitar desfase al empezar el nuevo día.
-- Restricción por asociación APAPPSS en listado sin alterar columnas o paginación.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Sel_Listado]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nPagina INT,@nTamano INT,@nOffset BIGINT; EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@nPagina OUTPUT,@nTamano OUTPUT,@nOffset OUTPUT;
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@cEstado VARCHAR(20),@nAsoc BIGINT,@nComprador BIGINT,@dDesde DATE,@dHasta DATE;
        SELECT @nUotSolicitada=uotId,@cEstado=estadoProceso,@nAsoc=asociacionId,@nComprador=empresaCompradoraId,@dDesde=fechaDesde,@dHasta=fechaHasta FROM OPENJSON(@cJson,'$.filtros') WITH(uotId BIGINT '$.uotId',estadoProceso VARCHAR(20) '$.estadoProceso',asociacionId BIGINT '$.asociacionId',empresaCompradoraId BIGINT '$.empresaCompradoraId',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta');
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'CAMPANIAS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'CAMPANIAS_LISTAR',0,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        -- Sólo APAPPSS con convenio UOT real, activo y módulo especial explícito.
        IF @nUot IS NULL OR NOT EXISTS (
          SELECT 1 FROM org.ConvenioUOTOrganizacion CU
          JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
          JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1
          JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
          JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
          JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
          WHERE CU.uot_id=@nUot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
            AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
            AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
        BEGIN SET @cMensaje=N'No existe convenio APAPPSS vigente para la UOT seleccionada.'; GOTO Salida; END;
        SELECT C.campania_venta_id campaniaVentaId,C.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,C.asociacion_id asociacionId,EA.razon_social asociacion,C.empresa_compradora_id empresaCompradoraId,EC.razon_social empresaCompradora,C.codigo,C.nombre,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) THEN 'VENCIDA' ELSE C.estado_proceso END estadoProceso,C.observacion,C.estado,COUNT_BIG(*) OVER() totalRegistros
        FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id
        WHERE C.estado=1 AND C.uot_id=@nUot AND EA.ruc='20602771394' AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,C.uot_id,'CAMPANIAS_LISTAR')=1 AND (@cEstado IS NULL OR (CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) THEN 'VENCIDA' ELSE C.estado_proceso END)=@cEstado) AND (@nAsoc IS NULL OR C.asociacion_id=@nAsoc) AND (@nComprador IS NULL OR C.empresa_compradora_id=@nComprador) AND (@dDesde IS NULL OR C.fecha_inicio>=@dDesde) AND (@dHasta IS NULL OR C.fecha_inicio<=@dHasta)
        ORDER BY C.fecha_inicio DESC,C.campania_venta_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;
        SET @bResultado=1; SET @cMensaje=N'Campañas consultadas.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO

-- Restricción de detalle APAPPSS por UOT y convenio real, manteniendo respuesta original.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Sel_DetalleCompleto]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la campaña.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nId BIGINT=COALESCE(TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.campania.campaniaVentaId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.campaniaVentaId'))),@nUotSolicitada BIGINT=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.campania.uotId'),JSON_VALUE(@cJson,'$.uotId'))),@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
        IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId;
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'CAMPANIAS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'CAMPANIAS_VER',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        IF NOT EXISTS (SELECT 1 FROM comercial.CampaniaVenta CV
          JOIN org.Empresa E ON E.empresa_id=CV.asociacion_id AND E.ruc='20602771394' AND E.estado=1
          JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1
          JOIN org.ConvenioUOTOrganizacion CU ON CU.empresa_id=E.empresa_id AND CU.uot_id=CV.uot_id AND CU.estado=1
          JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
          JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
          JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
          WHERE CV.campania_venta_id=@nId AND CV.uot_id=@nUot AND CV.estado=1 AND CU.tipo_vinculo='ASOCIACION'
             AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
             AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
        BEGIN SET @cMensaje=N'La campaña no pertenece a un convenio APAPPSS vigente en esta UOT.'; GOTO Salida; END;
        IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId AND uot_id=@nUot AND estado=1) BEGIN SET @cMensaje=N'La campaña no está disponible en esta UOT.'; GOTO Salida; END;
        SELECT C.*,U.codigo uotCodigo,U.nombre uotNombre,EA.razon_social asociacion,EC.razon_social empresaCompradora,CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) THEN 'VENCIDA' ELSE C.estado_proceso END estadoProceso FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id WHERE C.campania_venta_id=@nId AND C.uot_id=@nUot;
        SELECT O.* FROM comercial.OperativoVenta O WHERE O.campania_venta_id=@nId ORDER BY O.operativo_venta_id;
        SET @bResultado=1; SET @cMensaje=N'Campaña consultada.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la campaña.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO

-- Finanzas: la caducidad comercial no cancela la deuda con socios.
CREATE OR ALTER PROCEDURE finanzas.PA_APAPPSS_E5_Ejecutar
 @cAccion VARCHAR(40), @cJson NVARCHAR(MAX), @cDatos NVARCHAR(MAX) OUTPUT,
 @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
 @cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='E5_ERROR',@nHttpRespuesta=400,
   @cMensaje=N'No se pudo completar la operación financiera.';
 IF ISJSON(@cJson)<>1 OR @cAccion NOT IN
 ('TABLERO','GASTOS','REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO','REPARTO','LIQUIDAR','APROBAR','OBSERVAR',
 'LIQUIDACIONES','LIQUIDACION','PAGAR','REVERSAR','REPORTE','EXPORTAR','CIERRE_VALIDAR','CERRAR','COBROS')
 BEGIN SET @cMensaje=N'Operación no reconocida.';RETURN;END;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @gasto BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.gastoId')),
  @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
  @liq BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.liquidacionId')),
  @pago BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.pagoId')),
  @uot BIGINT,@asociacion BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @ok BIT,@msg NVARCHAR(300),@perm VARCHAR(60),@fecha DATETIME2(0)=SYSUTCDATETIME(),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@hashAnterior VARBINARY(32),@resAnterior NVARCHAR(MAX),
  @mutacion BIT=0,@applock INT,@version INT,@id BIGINT,@cantidad INT,@centavos BIGINT,@baseCent BIGINT,@sobrante INT,
  @total DECIMAL(19,4),@moneda CHAR(3),@motivo NVARCHAR(800),@esperado BIGINT,
  @bruto DECIMAL(19,4),@efectivo DECIMAL(19,4),@ajuste DECIMAL(19,4),@cargos DECIMAL(19,4),
  @gastos DECIMAL(19,4),@descuentos DECIMAL(19,4),@bonos DECIMAL(19,4),@neto DECIMAL(19,4),
  @redondeo DECIMAL(19,4),@kilos DECIMAL(19,3),@pagado DECIMAL(19,4),@saldo DECIMAL(19,4),@importe DECIMAL(19,4),
  @fuentes NVARCHAR(MAX),@huella VARBINARY(32),@nuevoId BIGINT,@estado VARCHAR(30),
  @lockResource NVARCHAR(200),@balanceJson NVARCHAR(MAX),@excepcion BIT=0,@pendientes INT=0,@pagosPendientes INT=0,@cobrosPendientes DECIMAL(19,4)=0;
 IF @liq IS NOT NULL SELECT @part=L.participacion_campania_socio_id FROM finanzas.LiquidacionSocio L WHERE L.liquidacion_socio_id=@liq;
 IF @pago IS NOT NULL SELECT @liq=P.liquidacion_socio_id FROM finanzas.PagoSocio P WHERE P.pago_socio_id=@pago;
 IF @liq IS NOT NULL SELECT @part=L.participacion_campania_socio_id FROM finanzas.LiquidacionSocio L WHERE L.liquidacion_socio_id=@liq;
 IF @part IS NOT NULL SELECT @camp=P.campania_venta_id FROM comercial.ParticipacionCampaniaSocio P WHERE P.participacion_campania_socio_id=@part AND P.estado=1;
 IF @gasto IS NOT NULL SELECT @camp=G.campania_venta_id FROM finanzas.GastoCampania G WHERE G.gasto_campania_id=@gasto AND G.estado=1;
 SELECT @uot=C.uot_id,@asociacion=C.asociacion_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
 IF @uot IS NULL BEGIN SET @cMensaje=N'Seleccione una campaña vigente.';RETURN;END;
 SET @perm=CASE @cAccion WHEN 'TABLERO' THEN 'LIQUIDACIONES_LISTAR' WHEN 'GASTOS' THEN 'GASTOS_LISTAR'
 WHEN 'REPARTO' THEN 'GASTOS_VER' WHEN 'REPARTIR' THEN 'GASTOS_CREAR'
 WHEN 'APROBAR_REPARTO' THEN 'GASTOS_APROBAR' WHEN 'RECTIFICAR_REPARTO' THEN 'GASTOS_APROBAR' WHEN 'LIQUIDACIONES' THEN 'LIQUIDACIONES_LISTAR'
 WHEN 'LIQUIDACION' THEN 'LIQUIDACIONES_VER' WHEN 'LIQUIDAR' THEN 'LIQUIDACIONES_CREAR'
 WHEN 'APROBAR' THEN 'LIQUIDACIONES_APROBAR' WHEN 'OBSERVAR' THEN 'LIQUIDACIONES_EDITAR'
 WHEN 'PAGAR' THEN 'PAGOS_CONFIRMAR' WHEN 'REVERSAR' THEN 'PAGOS_RETIRAR'
 WHEN 'REPORTE' THEN 'REPORTES_VER' WHEN 'EXPORTAR' THEN 'REPORTES_EXPORTAR' WHEN 'COBROS' THEN 'COBROS_VER'
 WHEN 'CIERRE_VALIDAR' THEN 'CAMPANIAS_VER' ELSE 'CAMPANIAS_ADMINISTRAR' END;
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso=@perm,
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@ok OUTPUT,@cMensaje=@msg OUTPUT;
  IF ISNULL(@ok,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
   THROW 51600,N'No dispone del permiso territorial solicitado.',1;
  IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
     JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND M.estado=1
     JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
     WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,@fecha))
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,@fecha)))
   THROW 51601,N'El convenio APAPPSS no está habilitado para esta UOT.',1;
  SET @mutacion=CASE WHEN @cAccion IN('REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO','LIQUIDAR','APROBAR','OBSERVAR','PAGAR','REVERSAR','CERRAR') THEN 1 ELSE 0 END;
  IF @mutacion=1
  BEGIN
   IF @clave IS NULL THROW 51602,N'La operación necesita clave de idempotencia.',1;
   BEGIN TRANSACTION;
   SET @lockResource=CONCAT('APAPPSS_E5_CAMP_',@camp);
   EXEC @applock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
   IF @applock<0 THROW 51603,N'La campaña está siendo procesada. Vuelva a intentar.',1;
   SET @hash=HASHBYTES('SHA2_256',CONCAT(@cAccion,N'|',COALESCE(CONVERT(NVARCHAR(30),@gasto),N''),N'|',
     COALESCE(CONVERT(NVARCHAR(30),@part),N''),N'|',COALESCE(CONVERT(NVARCHAR(30),@liq),N''),N'|',
     COALESCE(CONVERT(NVARCHAR(30),@pago),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'{}')));
   SELECT @hashAnterior=S.huella,@resAnterior=S.respuesta FROM finanzas.SolicitudE5 S WITH(UPDLOCK,HOLDLOCK)
     WHERE S.usuario_id=@usuario AND S.clave=@clave;
   IF @hashAnterior IS NOT NULL
   BEGIN
     IF @hashAnterior<>@hash THROW 51604,N'La clave ya corresponde a una operación diferente.',1;
     SET @cDatos=@resAnterior;SET @bResultado=1;SET @cCodigoRespuesta='E5_REINTENTO';SET @cMensaje=N'Operación ya registrada.';
     SET @nHttpRespuesta=200;COMMIT TRANSACTION;RETURN;
   END;
   -- Las campañas sin activar o canceladas no generan movimientos financieros.
   -- Una campaña vencida/cerrada conserva las liquidaciones y pagos pendientes.
   IF NOT EXISTS (SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
                  WHERE C.campania_venta_id=@camp AND C.estado=1
                    AND C.estado_proceso IN ('ACTIVA','VENCIDA','CERRADA'))
     THROW 51670,N'Active la campaña antes de registrar movimientos financieros.',1;
   IF @cAccion IN ('REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO')
      AND NOT EXISTS (SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
                       WHERE C.campania_venta_id=@camp AND C.estado_proceso='ACTIVA'
                         AND CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) BETWEEN C.fecha_inicio AND C.fecha_fin)
     THROW 51671,N'Los gastos y repartos solo se modifican durante la vigencia de la campaña.',1;
   IF EXISTS(SELECT 1 FROM comercial.CierreCampaniaE5 WHERE campania_venta_id=@camp)
    THROW 51605,N'El cierre financiero definitivo solo admite consultas.',1;
  END;

  IF @cAccion IN('TABLERO','REPORTE','EXPORTAR')
  BEGIN
    SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.nombre,
     CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))
          THEN 'VENCIDA' ELSE C.estado_proceso END estado,
     CONVERT(BIT,CASE WHEN X.campania_venta_id IS NULL THEN 0 ELSE 1 END) cerrada,
     (SELECT COUNT(DISTINCT OS.participacion_campania_socio_id) FROM comercial.EntregaSocio E
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA') vendedores,
     (SELECT COALESCE(SUM(D.kilogramos),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) kilogramos,
     (SELECT COALESCE(SUM(D.kilogramos*D.precio_base),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) bruto,
     (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) ventaAjustada,
     (SELECT COALESCE(SUM(L.importe_neto),0) FROM finanzas.LiquidacionSocio L
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA') netoAprobado,
     (SELECT COALESCE(SUM(PG.importe),0) FROM finanzas.PagoSocio PG
      JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PG.liquidacion_socio_id
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') pagado,
     (SELECT COALESCE(SUM(G.importe),0) FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@camp AND G.estado=1 AND G.estado_proceso='APROBADO') gastoComun,
     (SELECT COALESCE(SUM(CI.importe),0) FROM comercial.CargoIndividualE4 CI
      JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=CI.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND CI.estado=1) cargos,
     (SELECT COALESCE(SUM(A.cantidad_asignada),0) FROM comercial.JabaAsignacion A
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND A.estado=1) jabasAsignadas,
     (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U
      JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=U.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND U.retorno_estado LIKE 'DEVUELTA%') jabasDevueltas,
     (SELECT COUNT_BIG(1) FROM comercial.JabaUnidadE4 U
      JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=U.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND U.retorno_estado='FALTANTE') jabasFaltantes,
     JSON_QUERY((SELECT P.participacion_campania_socio_id participacionId,
       SA.socio_asociacion_id socioId,
       CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socio,
       (SELECT COALESCE(SUM(D.kilogramos),0) FROM comercial.OperativoSocio OS
        JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
        JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
        WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND OS.estado=1) kilogramos,
       LS.liquidacion_socio_id liquidacionId,LS.version,LS.estado_proceso liquidacionEstado,
       LS.importe_neto neto,COALESCE(Q.pagado,0) pagado,
       CASE WHEN LS.importe_neto IS NULL THEN NULL ELSE LS.importe_neto-COALESCE(Q.pagado,0) END saldo
       FROM comercial.ParticipacionCampaniaSocio P
       JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
       JOIN org.Socio S ON S.socio_id=SA.socio_id
       JOIN org.Persona PE ON PE.persona_id=S.socio_id
       OUTER APPLY(SELECT TOP(1) L.liquidacion_socio_id,L.version,L.estado_proceso,L.importe_neto
         FROM finanzas.LiquidacionSocio L WHERE L.participacion_campania_socio_id=P.participacion_campania_socio_id
          AND L.estado=1 AND L.estado_proceso<>'ANULADA' ORDER BY L.version DESC) LS
       OUTER APPLY(SELECT SUM(PG.importe) pagado FROM finanzas.PagoSocio PG
         WHERE PG.liquidacion_socio_id=LS.liquidacion_socio_id AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') Q
       WHERE P.campania_venta_id=@camp AND P.estado=1 ORDER BY socio,P.participacion_campania_socio_id FOR JSON PATH)) socios,
     JSON_QUERY((SELECT D.variedad_palta_id variedadId,D.condicion_comercial_id condicionId,
        SUM(D.kilogramos) kilogramos,SUM(D.kilogramos*D.precio_base) bruto,SUM(D.importe) efectivo
       FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND D.estado=1
       GROUP BY D.variedad_palta_id,D.condicion_comercial_id FOR JSON PATH)) variedades,
     JSON_QUERY((SELECT R.reparto_id repartoId,G.concepto,R.version,R.importe,R.vendedores,R.estado
       FROM finanzas.GastoRepartoVersionE5 R JOIN finanzas.GastoCampania G ON G.gasto_campania_id=R.gasto_campania_id
       WHERE G.campania_venta_id=@camp ORDER BY G.gasto_campania_id,R.version FOR JSON PATH)) repartos
     FROM comercial.CampaniaVenta C LEFT JOIN comercial.CierreCampaniaE5 X ON X.campania_venta_id=C.campania_venta_id
     WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='GASTOS'
  BEGIN
    SET @cDatos=(SELECT @camp campaniaId,JSON_QUERY((SELECT G.gasto_campania_id gastoId,G.concepto,G.importe,G.moneda,G.estado_proceso estado,
      G.fecha, R.reparto_id repartoId,R.version,R.estado repartoEstado,R.vendedores
      FROM finanzas.GastoCampania G OUTER APPLY(SELECT TOP(1) * FROM finanzas.GastoRepartoVersionE5 R
        WHERE R.gasto_campania_id=G.gasto_campania_id ORDER BY R.version DESC) R
      WHERE G.campania_venta_id=@camp AND G.estado=1 ORDER BY G.fecha,G.gasto_campania_id FOR JSON PATH)) gastos
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='REPARTO'
  BEGIN
   SET @cDatos=(SELECT @gasto gastoId,JSON_QUERY((SELECT R.reparto_id repartoId,R.version,R.estado,R.importe,R.moneda,R.vendedores,R.observacion,
     JSON_QUERY((SELECT X.participacion_id participacionId,X.monto FROM finanzas.GastoRepartoLineaE5 X
       WHERE X.reparto_id=R.reparto_id ORDER BY X.participacion_id FOR JSON PATH)) socios
     FROM finanzas.GastoRepartoVersionE5 R WHERE R.gasto_campania_id=@gasto
     ORDER BY R.version DESC FOR JSON PATH)) repartos FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion IN('REPARTIR','APROBAR_REPARTO','RECTIFICAR_REPARTO')
  BEGIN
   SELECT @total=G.importe,@moneda=G.moneda,@estado=G.estado_proceso FROM finanzas.GastoCampania G WITH(UPDLOCK,HOLDLOCK)
     WHERE G.gasto_campania_id=@gasto AND G.estado=1;
   IF @total IS NULL OR @total<=0 OR @moneda<>'PEN' THROW 51610,N'El gasto debe estar vigente, positivo y en soles.',1;
   IF @cAccion='RECTIFICAR_REPARTO'
   BEGIN
    SET @motivo=JSON_VALUE(@cJson,'$.datos.motivo');
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51621,N'Indique el motivo de rectificación.',1;
    IF EXISTS(SELECT 1 FROM finanzas.LiquidacionDetalle LD
       JOIN finanzas.GastoProrrateoSocio GP ON GP.gasto_prorrateo_socio_id=LD.gasto_prorrateo_socio_id
       JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=LD.liquidacion_socio_id
       WHERE GP.gasto_campania_id=@gasto AND L.estado=1 AND L.estado_proceso='APROBADA')
      THROW 51622,N'Existe una liquidación aprobada. Debe regularizarla antes de rectificar el reparto.',1;
    IF @estado<>'APROBADO' THROW 51623,N'Solo es posible rectificar un reparto aprobado.',1;
    UPDATE finanzas.GastoRepartoVersionE5 SET estado='RECTIFICADO',observacion=@motivo
      WHERE gasto_campania_id=@gasto AND estado='APROBADO';
    UPDATE finanzas.GastoProrrateoSocio SET estado=0 WHERE gasto_campania_id=@gasto AND estado=1;
    UPDATE finanzas.GastoCampania SET estado_proceso='REGISTRADO' WHERE gasto_campania_id=@gasto;
    SET @estado='REGISTRADO';
   END;
   IF @cAccion IN('REPARTIR','RECTIFICAR_REPARTO')
   BEGIN
    IF @estado<>'REGISTRADO' THROW 51611,N'El gasto aprobado no admite reparto nuevo sin rectificación formal.',1;
    IF EXISTS(SELECT 1 FROM finanzas.GastoRepartoVersionE5 WHERE gasto_campania_id=@gasto AND estado='PROPUESTO')
       THROW 51612,N'Ya existe un reparto pendiente. Revíselo antes de confirmar.',1;
    DECLARE @vendedores TABLE(participacion_id BIGINT NOT NULL PRIMARY KEY,orden INT NOT NULL);
    INSERT @vendedores(participacion_id,orden)
    SELECT P.participacion_campania_socio_id,ROW_NUMBER() OVER(ORDER BY P.participacion_campania_socio_id)
    FROM comercial.ParticipacionCampaniaSocio P WHERE P.campania_venta_id=@camp AND P.estado=1
      AND EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
       JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
       JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
       WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id AND OS.estado=1);
    SET @cantidad=(SELECT COUNT(1) FROM @vendedores);
    IF @cantidad=0 THROW 51613,N'No hay vendedores con kilos confirmados para prorratear.',1;
    SET @centavos=CONVERT(BIGINT,ROUND(@total*100,0));
    IF @centavos<>@total*100 THROW 51614,N'El reparto exige un gasto con precisión de céntimos.',1;
    SET @baseCent=@centavos/@cantidad;SET @sobrante=CONVERT(INT,@centavos%@cantidad);
    SELECT @version=COALESCE(MAX(version),0)+1 FROM finanzas.GastoRepartoVersionE5 WHERE gasto_campania_id=@gasto;
    INSERT finanzas.GastoRepartoVersionE5(gasto_campania_id,version,importe,moneda,vendedores,estado,usuario_id)
      VALUES(@gasto,@version,@total,@moneda,@cantidad,'PROPUESTO',@usuario);
    SET @id=SCOPE_IDENTITY();
    INSERT finanzas.GastoRepartoLineaE5(reparto_id,participacion_id,monto)
     SELECT @id,participacion_id,CONVERT(DECIMAL(19,4),(@baseCent+CASE WHEN orden<=@sobrante THEN 1 ELSE 0 END)/100.0)
     FROM @vendedores;
    IF (SELECT SUM(monto) FROM finanzas.GastoRepartoLineaE5 WHERE reparto_id=@id)<>@total
     THROW 51615,N'La suma de cuotas no coincide con el gasto.',1;
   END
   ELSE
   BEGIN
    SELECT TOP(1) @id=reparto_id,@version=version,@cantidad=vendedores FROM finanzas.GastoRepartoVersionE5 WITH(UPDLOCK,HOLDLOCK)
       WHERE gasto_campania_id=@gasto AND estado='PROPUESTO' ORDER BY version DESC;
    IF @id IS NULL THROW 51616,N'No existe reparto pendiente de aprobación.',1;
    IF EXISTS(SELECT 1 FROM finanzas.GastoProrrateoSocio P WHERE P.gasto_campania_id=@gasto AND P.estado=1)
     THROW 51617,N'Existen cuotas registradas; la rectificación debe revisar primero sus liquidaciones.',1;
    IF EXISTS(SELECT 1 FROM finanzas.GastoRepartoLineaE5 L WHERE L.reparto_id=@id
      AND NOT EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
       JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
       JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
       WHERE OS.participacion_campania_socio_id=L.participacion_id))
      THROW 51618,N'Cambió la composición de vendedores. Registre un nuevo reparto.',1;
    IF (SELECT COUNT(DISTINCT OS.participacion_campania_socio_id) FROM comercial.OperativoSocio OS
      JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
      JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp)<>@cantidad
      THROW 51619,N'El número de vendedores cambió. Recalcule el prorrateo.',1;
    IF EXISTS(
      SELECT OS.participacion_campania_socio_id FROM comercial.OperativoSocio OS
      JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
      JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1 AND D.kilogramos>0
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp GROUP BY OS.participacion_campania_socio_id
      EXCEPT SELECT participacion_id FROM finanzas.GastoRepartoLineaE5 WHERE reparto_id=@id
    ) THROW 51625,N'Los vendedores actuales no coinciden con los del reparto.',1;
    INSERT finanzas.GastoProrrateoSocio(gasto_campania_id,participacion_campania_socio_id,importe_asignado,estado)
      SELECT @gasto,participacion_id,monto,1 FROM finanzas.GastoRepartoLineaE5 WHERE reparto_id=@id;
    UPDATE finanzas.GastoRepartoVersionE5 SET estado='APROBADO',aprobado_por=@usuario,aprobado=@fecha WHERE reparto_id=@id;
    UPDATE finanzas.GastoCampania SET estado_proceso='APROBADO' WHERE gasto_campania_id=@gasto AND estado_proceso='REGISTRADO';
    IF @@ROWCOUNT<>1 THROW 51620,N'El estado del gasto cambió.',1;
   END;
   SET @cDatos=(SELECT @id repartoId,@version version,@cantidad vendedores,@total importe,
     JSON_QUERY((SELECT participacion_id participacionId,monto FROM finanzas.GastoRepartoLineaE5
       WHERE reparto_id=@id ORDER BY participacion_id FOR JSON PATH)) socios FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='LIQUIDACIONES'
  BEGIN
   SET @cDatos=(SELECT @camp campaniaId,JSON_QUERY((SELECT L.liquidacion_socio_id liquidacionId,
     L.participacion_campania_socio_id participacionId,L.version,L.importe_neto neto,L.moneda,L.estado_proceso estado,
     COALESCE((SELECT SUM(P.importe) FROM finanzas.PagoSocio P WHERE P.liquidacion_socio_id=L.liquidacion_socio_id
       AND P.estado=1 AND P.estado_proceso='CONFIRMADO'),0) pagado
     FROM finanzas.LiquidacionSocio L JOIN comercial.ParticipacionCampaniaSocio P
       ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
     WHERE P.campania_venta_id=@camp AND L.estado=1 ORDER BY P.participacion_campania_socio_id,L.version DESC FOR JSON PATH)) liquidaciones
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion IN('LIQUIDAR','APROBAR','OBSERVAR','LIQUIDACION','PAGAR','REVERSAR')
  BEGIN
   -- El desglose se deriva de los detalles oficiales de entrega, no de cifras introducidas por Angular.
   IF @part IS NULL THROW 51630,N'Seleccione un socio inscrito en esta campaña.',1;
   SELECT @kilos=COALESCE(SUM(D.kilogramos),0),@bruto=COALESCE(SUM(D.kilogramos*D.precio_base),0),
     @efectivo=COALESCE(SUM(D.importe),0)
   FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
     AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
   JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
   WHERE OS.participacion_campania_socio_id=@part AND OS.estado=1;
   SET @ajuste=ROUND(@bruto-@efectivo,4);
   SELECT @cargos=COALESCE(SUM(CI.importe),0) FROM comercial.CargoIndividualE4 CI
    JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=CI.jaba_asignacion_id
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    WHERE OS.participacion_campania_socio_id=@part AND CI.estado=1 AND A.estado=1;
   SELECT @gastos=COALESCE(SUM(GP.importe_asignado),0) FROM finanzas.GastoProrrateoSocio GP
     JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id
       AND G.estado=1 AND G.estado_proceso='APROBADO'
     WHERE GP.participacion_campania_socio_id=@part AND GP.estado=1;
   SELECT @descuentos=COALESCE(SUM(CASE WHEN A.tipo_ajuste='DESCUENTO_PORCENTAJE'
        THEN ROUND(@bruto*COALESCE(A.porcentaje_ajuste,0)/100.0,4)
        WHEN A.tipo_ajuste='DESCUENTO_MONTO' THEN COALESCE(A.monto_ajuste,0) ELSE 0 END),0),
     @bonos=COALESCE(SUM(CASE WHEN A.tipo_ajuste='BONIFICACION' THEN COALESCE(A.monto_ajuste,0) ELSE 0 END),0)
     FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@part
       AND A.estado=1 AND A.estado_ajuste='VIGENTE';
   SET @neto=ROUND(@efectivo-@cargos-@gastos-@descuentos+@bonos,2);
   SET @redondeo=@neto-(@efectivo-@cargos-@gastos-@descuentos+@bonos);
   SET @fuentes=CONCAT(
    (SELECT D.entrega_detalle_id id,D.kilogramos kg,D.precio_base base,D.precio_aplicado efectivo,D.estado
     FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
     JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id
     WHERE OS.participacion_campania_socio_id=@part AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1
     ORDER BY D.entrega_detalle_id FOR JSON PATH),
    (SELECT CI.cargo_id id,CI.importe FROM comercial.CargoIndividualE4 CI
      JOIN comercial.JabaAsignacion JA ON JA.jaba_asignacion_id=CI.jaba_asignacion_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=JA.operativo_socio_id
      WHERE OS.participacion_campania_socio_id=@part AND CI.estado=1 ORDER BY CI.cargo_id FOR JSON PATH),
    (SELECT GP.gasto_prorrateo_socio_id id,GP.importe_asignado FROM finanzas.GastoProrrateoSocio GP
      JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id
      WHERE GP.participacion_campania_socio_id=@part AND GP.estado=1 AND G.estado=1 AND G.estado_proceso='APROBADO'
      ORDER BY GP.gasto_prorrateo_socio_id FOR JSON PATH),
    (SELECT A.ajuste_precio_socio_id id,A.tipo_ajuste,A.monto_ajuste,A.porcentaje_ajuste
      FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@part AND A.estado=1 AND A.estado_ajuste='VIGENTE'
      ORDER BY A.ajuste_precio_socio_id FOR JSON PATH));
   SET @huella=HASHBYTES('SHA2_256',@fuentes);
   IF @cAccion='LIQUIDAR'
   BEGIN
    IF EXISTS (SELECT 1 FROM finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK)
       WHERE L.participacion_campania_socio_id=@part AND L.estado=1
         AND L.estado_proceso='CALCULADA')
       THROW 51648,N'Ya existe una versión calculada pendiente de revisión.',1;
    IF @kilos<=0 THROW 51631,N'No hay kilos aceptados y confirmados.',1;
    IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
       JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
       WHERE OS.participacion_campania_socio_id=@part AND NOT EXISTS
       (SELECT 1 FROM comercial.JabaRetornoValidadoE4 V WHERE V.jaba_asignacion_id=A.jaba_asignacion_id))
       THROW 51632,N'Hay devoluciones de jabas sin validación física.',1;
    IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
       JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1
       WHERE OS.participacion_campania_socio_id=@part AND E.estado_proceso<>'CONFIRMADA')
       THROW 51633,N'Hay entregas pendientes de confirmación.',1;
    IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
      JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
      JOIN comercial.SancionSocioE4 S ON S.entrega_socio_id=E.entrega_socio_id AND S.estado=1 AND S.aplicada_detalle=0
      WHERE OS.participacion_campania_socio_id=@part)
      THROW 51634,N'Existen sanciones cuyo precio todavía no se aplicó al detalle.',1;
    SELECT @nuevoId=MAX(L.liquidacion_socio_id) FROM finanzas.LiquidacionSocio L
      WHERE L.participacion_campania_socio_id=@part AND L.estado=1 AND L.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA');
    IF @nuevoId IS NOT NULL
    BEGIN
      SET @motivo=JSON_VALUE(@cJson,'$.datos.motivoRectificacion');
      IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51635,N'Una liquidación aprobada exige rectificación motivada.',1;
      IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'LIQUIDACIONES_EDITAR')<>1
       THROW 51636,N'No dispone de autorización para rectificar liquidaciones.',1;
      IF EXISTS(SELECT 1 FROM finanzas.PagoSocio WHERE liquidacion_socio_id=@nuevoId AND estado=1 AND estado_proceso='CONFIRMADO')
       THROW 51637,N'La liquidación pagada requiere regularización formal antes de rectificar.',1;
      UPDATE finanzas.LiquidacionSocio SET estado_proceso='ANULADA' WHERE liquidacion_socio_id=@nuevoId;
      UPDATE finanzas.LiquidacionSnapshotE5 SET observacion=@motivo WHERE liquidacion_socio_id=@nuevoId;
    END;
    SELECT @version=COALESCE(MAX(version),0)+1 FROM finanzas.LiquidacionSocio WHERE participacion_campania_socio_id=@part;
    SET @moneda='PEN';
    INSERT finanzas.LiquidacionSocio(participacion_campania_socio_id,version,fecha_calculo,importe_bruto,
      total_ajustes,total_gastos,total_bonificaciones,importe_neto,moneda,estado_proceso,estado)
    VALUES(@part,@version,@fecha,@bruto,@ajuste+@descuentos+@cargos,@gastos,@bonos,@neto,@moneda,'CALCULADA',1);
    SET @liq=SCOPE_IDENTITY();
    INSERT finanzas.LiquidacionSnapshotE5(liquidacion_socio_id,campania_venta_id,peso_aceptado_kg,
      bruto_referencial,ajuste_precio,descuentos_adicionales,cargos,gastos,bonificaciones,venta_ajustada,
      neto,ajuste_redondeo,fuente_hash,moneda,creado_por)
    VALUES(@liq,@camp,@kilos,@bruto,@ajuste,@descuentos,@cargos,@gastos,@bonos,@efectivo,@neto,@redondeo,@huella,@moneda,@usuario);
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,'VENTA',D.entrega_detalle_id,NULL,NULL,N'Venta efectiva (precio histórico)',D.importe,1
     FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
       AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
     JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
     WHERE OS.participacion_campania_socio_id=@part;
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,'GASTO',NULL,GP.gasto_prorrateo_socio_id,NULL,G.concepto,-GP.importe_asignado,1
     FROM finanzas.GastoProrrateoSocio GP JOIN finanzas.GastoCampania G
       ON G.gasto_campania_id=GP.gasto_campania_id AND G.estado=1 AND G.estado_proceso='APROBADO'
     WHERE GP.participacion_campania_socio_id=@part AND GP.estado=1;
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,'OTRO',NULL,NULL,NULL,CONCAT(N'Cargo particular: ',C.motivo),-C.importe,1
     FROM comercial.CargoIndividualE4 C JOIN comercial.JabaAsignacion JA ON JA.jaba_asignacion_id=C.jaba_asignacion_id
     JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=JA.operativo_socio_id
     WHERE OS.participacion_campania_socio_id=@part AND C.estado=1;
    INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
      ajuste_precio_socio_id,concepto,importe,estado)
    SELECT @liq,CASE WHEN A.tipo_ajuste='BONIFICACION' THEN 'BONIFICACION' ELSE 'AJUSTE' END,
     NULL,NULL,A.ajuste_precio_socio_id,A.motivo,
     CASE WHEN A.tipo_ajuste='BONIFICACION' THEN COALESCE(A.monto_ajuste,0)
          WHEN A.tipo_ajuste='DESCUENTO_PORCENTAJE' THEN -ROUND(@bruto*COALESCE(A.porcentaje_ajuste,0)/100.0,4)
          ELSE -COALESCE(A.monto_ajuste,0) END,1
    FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@part
      AND A.estado=1 AND A.estado_ajuste='VIGENTE' AND A.tipo_ajuste IN('DESCUENTO_MONTO','DESCUENTO_PORCENTAJE','BONIFICACION');
    IF @redondeo<>0
      INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,
       ajuste_precio_socio_id,concepto,importe,estado)
      VALUES(@liq,'OTRO',NULL,NULL,NULL,N'Ajuste de redondeo monetario',@redondeo,1);

   END
   ELSE IF @cAccion='APROBAR'
   BEGIN
    SELECT @estado=L.estado_proceso,@esperado=CONVERT(BIGINT,L.version) FROM finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK)
      WHERE L.liquidacion_socio_id=@liq AND L.estado=1;
    IF @estado<>'CALCULADA' THROW 51638,N'La liquidación ya no está pendiente de aprobación.',1;
    IF NOT EXISTS(SELECT 1 FROM finanzas.LiquidacionSnapshotE5 WHERE liquidacion_socio_id=@liq AND fuente_hash=@huella)
     THROW 51639,N'Cambió el origen de los cálculos. Registre una nueva versión.',1;
    IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio WHERE participacion_campania_socio_id=@part AND version>@esperado AND estado=1 AND estado_proceso<>'ANULADA')
     THROW 51640,N'Existe una versión posterior.',1;
    UPDATE finanzas.LiquidacionSocio SET estado_proceso='APROBADA' WHERE liquidacion_socio_id=@liq;
    UPDATE finanzas.LiquidacionSnapshotE5 SET aprobado_por=@usuario,aprobado=@fecha WHERE liquidacion_socio_id=@liq;
   END
   ELSE IF @cAccion='OBSERVAR'
   BEGIN
    SET @motivo=JSON_VALUE(@cJson,'$.datos.motivo');
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51641,N'Indique el motivo de observación.',1;
    IF NOT EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio WHERE liquidacion_socio_id=@liq AND estado_proceso='CALCULADA')
     THROW 51642,N'Solo se pueden observar liquidaciones pendientes.',1;
    UPDATE finanzas.LiquidacionSocio SET estado_proceso='OBSERVADA' WHERE liquidacion_socio_id=@liq;
    UPDATE finanzas.LiquidacionSnapshotE5 SET observacion=@motivo WHERE liquidacion_socio_id=@liq;
   END
   ELSE IF @cAccion='PAGAR'
   BEGIN
    SET @importe=TRY_CONVERT(DECIMAL(19,4),JSON_VALUE(@cJson,'$.datos.importe'));
    DECLARE @medio VARCHAR(30)=JSON_VALUE(@cJson,'$.datos.medioPago'),@referencia VARCHAR(100)=JSON_VALUE(@cJson,'$.datos.referencia');
    SELECT @neto=L.importe_neto,@estado=L.estado_proceso FROM finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK)
      WHERE L.liquidacion_socio_id=@liq AND L.estado=1;
    SELECT @pagado=COALESCE(SUM(P.importe),0) FROM finanzas.PagoSocio P WITH(UPDLOCK,HOLDLOCK)
      WHERE P.liquidacion_socio_id=@liq AND P.estado=1 AND P.estado_proceso='CONFIRMADO';
    SET @saldo=@neto-@pagado;
    IF @estado<>'APROBADA' OR @neto<=0 OR @importe IS NULL OR @importe<0.01 OR @importe<>ROUND(@importe,2) OR @importe>@saldo
      THROW 51643,N'El importe supera el saldo disponible o la liquidación no está aprobada.',1;
    IF @medio IS NULL OR NULLIF(LTRIM(RTRIM(@medio)),'') IS NULL OR LEN(@medio)>30
      THROW 51644,N'Seleccione un medio de pago válido.',1;
    IF @medio IN('TRANSFERENCIA','DEPOSITO') AND NULLIF(LTRIM(RTRIM(@referencia)),'') IS NULL
      THROW 51645,N'El medio seleccionado requiere referencia de operación.',1;
    INSERT finanzas.PagoSocio(liquidacion_socio_id,fecha_hora,importe,medio_pago,numero_operacion,estado_proceso,
      estado,fecha_confirmacion,usuario_confirmacion_id)
    VALUES(@liq,@fecha,@importe,@medio,@referencia,'CONFIRMADO',1,@fecha,@usuario);
    SET @pago=SCOPE_IDENTITY();
    INSERT finanzas.EventoPagoE5(pago_socio_id,accion,importe,usuario_id) VALUES(@pago,'PAGAR',@importe,@usuario);
   END
   ELSE IF @cAccion='REVERSAR'
   BEGIN
    SET @motivo=JSON_VALUE(@cJson,'$.datos.motivo');
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51646,N'La reversión exige justificación.',1;
    SELECT @importe=importe FROM finanzas.PagoSocio WITH(UPDLOCK,HOLDLOCK)
      WHERE pago_socio_id=@pago AND liquidacion_socio_id=@liq AND estado=1 AND estado_proceso='CONFIRMADO';
    IF @importe IS NULL THROW 51647,N'El pago no está confirmado o ya fue revertido.',1;
    UPDATE finanzas.PagoSocio SET estado_proceso='ANULADO',fecha_anulacion=@fecha,
      usuario_anulacion_id=@usuario,motivo_anulacion=@motivo WHERE pago_socio_id=@pago;
    INSERT finanzas.EventoPagoE5(pago_socio_id,accion,importe,usuario_id,motivo)
      VALUES(@pago,'REVERSAR',@importe,@usuario,@motivo);
   END;
   SELECT @pagado=COALESCE(SUM(P.importe),0) FROM finanzas.PagoSocio P
    WHERE P.liquidacion_socio_id=@liq AND P.estado=1 AND P.estado_proceso='CONFIRMADO';
   SET @cDatos=(SELECT L.liquidacion_socio_id liquidacionId,L.participacion_campania_socio_id participacionId,
      L.version,L.estado_proceso estado,L.moneda,L.importe_neto neto,@pagado pagado,L.importe_neto-@pagado saldo,
      S.peso_aceptado_kg kilogramos,S.bruto_referencial bruto,S.ajuste_precio ajustePrecio,
      S.venta_ajustada ventaAjustada,S.cargos,S.gastos,S.descuentos_adicionales descuentos,
      S.bonificaciones,S.ajuste_redondeo redondeo,S.creado,S.aprobado,S.observacion,
      JSON_QUERY((SELECT D.liquidacion_detalle_id detalleId,D.tipo,D.concepto,D.importe,
       D.entrega_detalle_id entregaDetalleId,D.gasto_prorrateo_socio_id gastoLineaId,
       D.ajuste_precio_socio_id ajusteId FROM finanzas.LiquidacionDetalle D
       WHERE D.liquidacion_socio_id=L.liquidacion_socio_id AND D.estado=1 ORDER BY D.liquidacion_detalle_id FOR JSON PATH)) detalle,
      JSON_QUERY((SELECT P.pago_socio_id pagoId,P.importe,P.medio_pago medioPago,P.numero_operacion referencia,
        P.estado_proceso estado,P.fecha_hora fecha FROM finanzas.PagoSocio P
        WHERE P.liquidacion_socio_id=L.liquidacion_socio_id ORDER BY P.pago_socio_id FOR JSON PATH)) pagos
     FROM finanzas.LiquidacionSocio L LEFT JOIN finanzas.LiquidacionSnapshotE5 S ON S.liquidacion_socio_id=L.liquidacion_socio_id
     WHERE L.liquidacion_socio_id=@liq FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion='COBROS'
  BEGIN
   -- No confundir facturación con ingreso: solo suma cobros efectivamente confirmados.
   SET @cDatos=(SELECT @camp campaniaId,
      (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND D.estado=1 AND E.estado=1 AND E.estado_proceso='CONFIRMADA') ventaComprador,
      (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND D.estado=1 AND E.estado=1 AND E.estado_proceso='CONFIRMADA')
       -(SELECT COALESCE(SUM(importe),0) FROM finanzas.CobroComprador B
         WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO') saldoComprador,
      (SELECT COALESCE(SUM(importe),0) FROM finanzas.CobroComprador B
       WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO') cobrado,
      JSON_QUERY((SELECT B.cobro_comprador_id cobroId,B.importe,B.moneda,B.estado_proceso estado,
        B.fecha_hora fecha FROM finanzas.CobroComprador B
        WHERE B.campania_venta_id=@camp AND B.estado=1 ORDER BY B.cobro_comprador_id FOR JSON PATH)) movimientos
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END
  ELSE IF @cAccion IN('CIERRE_VALIDAR','CERRAR')
  BEGIN
   DECLARE @problemas TABLE(codigo VARCHAR(50) NOT NULL,detalle NVARCHAR(200) NOT NULL);
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
     JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
     WHERE O.campania_venta_id=@camp AND NOT EXISTS(SELECT 1 FROM comercial.JabaRetornoValidadoE4 V
       WHERE V.jaba_asignacion_id=A.jaba_asignacion_id))
     INSERT @problemas VALUES('JABAS',N'Existen jabas sin retorno validado');
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1
    WHERE O.campania_venta_id=@camp AND E.estado_proceso<>'CONFIRMADA')
    INSERT @problemas VALUES('ENTREGAS',N'Hay entregas sin confirmación');
   IF EXISTS(SELECT 1 FROM finanzas.GastoCampania G WHERE G.campania_venta_id=@camp AND G.estado=1 AND G.estado_proceso<>'APROBADO')
    INSERT @problemas VALUES('GASTOS',N'Hay gastos sin reparto y aprobación');
   IF EXISTS(SELECT 1 FROM finanzas.CobroComprador B WHERE B.campania_venta_id=@camp AND B.estado=1
       AND B.estado_proceso NOT IN('CONFIRMADO','ANULADO'))
      INSERT @problemas VALUES('COBROS_PENDIENTES',N'Existen cobros de comprador sin confirmar o anular');
   IF (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
      JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1)
      >(SELECT COALESCE(SUM(B.importe),0) FROM finanzas.CobroComprador B
        WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO')
      INSERT @problemas VALUES('SALDO_COMPRADOR',N'La venta registrada al comprador supera los cobros confirmados');

   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
    JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
    JOIN comercial.SancionSocioE4 S ON S.entrega_socio_id=E.entrega_socio_id AND S.estado=1 AND S.aplicada_detalle=0
    WHERE O.campania_venta_id=@camp)
    INSERT @problemas VALUES('SANCION',N'Hay sanciones sin precio efectivo');
   IF EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P WHERE P.campania_venta_id=@camp AND P.estado=1
     AND EXISTS(SELECT 1 FROM comercial.OperativoSocio OS JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id
       AND E.estado=1 AND E.estado_proceso='CONFIRMADA' WHERE OS.participacion_campania_socio_id=P.participacion_campania_socio_id)
     AND NOT EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L WHERE L.participacion_campania_socio_id=P.participacion_campania_socio_id
       AND L.estado=1 AND L.estado_proceso='APROBADA'))
     INSERT @problemas VALUES('LIQUIDACIONES',N'Existen vendedores sin liquidación aprobada');
   IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA'
        AND L.importe_neto>COALESCE((SELECT SUM(PG.importe) FROM finanzas.PagoSocio PG
           WHERE PG.liquidacion_socio_id=L.liquidacion_socio_id AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO'),0))
     INSERT @problemas VALUES('PAGOS',N'Quedan saldos por pagar a socios');
   IF EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio L
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA' AND L.importe_neto<0)
      INSERT @problemas VALUES('DEUDA',N'Existen saldos deudores que requieren regularización');
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O
      JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
      JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id AND A.estado=1
      JOIN comercial.IncidenciaFaltanteE4 I ON I.jaba_asignacion_id=A.jaba_asignacion_id AND I.estado='CONFIRMADA'
      WHERE O.campania_venta_id=@camp AND NOT EXISTS(SELECT 1 FROM comercial.CargoIndividualE4 CI
         WHERE CI.jaba_asignacion_id=A.jaba_asignacion_id AND CI.estado=1))
      INSERT @problemas VALUES('CARGOS',N'Hay faltantes confirmados sin cargo o regularización documentada');
   IF EXISTS(SELECT 1 FROM comercial.OperativoVenta O JOIN comercial.OperativoSocio OS ON OS.operativo_venta_id=O.operativo_venta_id
     JOIN comercial.JabaAsignacion A ON A.operativo_socio_id=OS.operativo_socio_id
     JOIN comercial.IncidenciaFaltanteE4 I ON I.jaba_asignacion_id=A.jaba_asignacion_id
     WHERE O.campania_venta_id=@camp AND I.estado<>'CONFIRMADA')
     INSERT @problemas VALUES('INCIDENCIAS',N'Existen incidencias de jabas sin confirmar');
   SET @pendientes=(SELECT COUNT(1) FROM @problemas);
   IF @cAccion='CERRAR'
   BEGIN
    SET @motivo=JSON_VALUE(@cJson,'$.datos.observacion');
    SET @excepcion=CASE WHEN JSON_VALUE(@cJson,'$.datos.excepcionAutorizada')='true' THEN 1 ELSE 0 END;
    IF NULLIF(LTRIM(RTRIM(@motivo)),N'') IS NULL THROW 51660,N'Indique observación de cierre.',1;
    IF @pendientes>0 AND (@excepcion=0 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_ADMINISTRAR')<>1
         OR NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivoExcepcion'))),N'') IS NULL)
       THROW 51661,N'Existen diferencias pendientes. Se requiere excepción autorizada y documentada.',1;
    IF EXISTS(SELECT 1 FROM comercial.CierreCampaniaE5 WHERE campania_venta_id=@camp)
       THROW 51662,N'La campaña ya está cerrada.',1;
    SET @cDatos=(SELECT @camp campaniaId,@fecha fecha,
       JSON_QUERY((SELECT codigo,detalle FROM @problemas FOR JSON PATH)) diferencias
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    SET @balanceJson=(SELECT @camp campaniaId,@fecha fecha,@usuario responsableId,
      (SELECT COALESCE(SUM(D.kilogramos),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) kilos,
      (SELECT COALESCE(SUM(D.kilogramos*D.precio_base),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) ventaBruta,
      (SELECT COALESCE(SUM(D.importe),0) FROM comercial.EntregaDetalle D
       JOIN comercial.EntregaSocio E ON E.entrega_socio_id=D.entrega_socio_id
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=@camp AND E.estado=1 AND E.estado_proceso='CONFIRMADA' AND D.estado=1) ventaEfectiva,
      (SELECT COALESCE(SUM(L.importe_neto),0) FROM finanzas.LiquidacionSocio L
       JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
       WHERE P.campania_venta_id=@camp AND L.estado=1 AND L.estado_proceso='APROBADA') netoAprobado,
      (SELECT COALESCE(SUM(PG.importe),0) FROM finanzas.PagoSocio PG
       JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PG.liquidacion_socio_id
       JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
       WHERE P.campania_venta_id=@camp AND PG.estado=1 AND PG.estado_proceso='CONFIRMADO') pagos,
      (SELECT COALESCE(SUM(B.importe),0) FROM finanzas.CobroComprador B
       WHERE B.campania_venta_id=@camp AND B.estado=1 AND B.estado_proceso='CONFIRMADO') cobros,
      (SELECT COALESCE(SUM(G.importe),0) FROM finanzas.GastoCampania G
       WHERE G.campania_venta_id=@camp AND G.estado=1 AND G.estado_proceso='APROBADO') gastos,
      JSON_QUERY((SELECT codigo,detalle FROM @problemas FOR JSON PATH)) diferencias
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    UPDATE comercial.CampaniaVenta SET estado_proceso='CERRADA'
      WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso='ACTIVA';
    IF @@ROWCOUNT<>1 THROW 51663,N'Solo una campaña activa puede cerrarse.',1;
    INSERT comercial.CierreCampaniaE5(campania_venta_id,usuario_id,observacion,excepcion_autorizada,motivo_excepcion,balance_final)
      VALUES(@camp,@usuario,@motivo,@excepcion,JSON_VALUE(@cJson,'$.datos.motivoExcepcion'),@balanceJson);
   END
   ELSE
   SET @cDatos=(SELECT @camp campaniaId,@pendientes pendientes,
      CONVERT(BIT,CASE WHEN @pendientes=0 THEN 1 ELSE 0 END) habilitado,
      JSON_QUERY((SELECT codigo,detalle FROM @problemas FOR JSON PATH)) diferencias
      FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  END;
  IF @mutacion=1
  BEGIN
   INSERT finanzas.SolicitudE5(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,@cAccion,@hash,COALESCE(@cDatos,N'{}'));
   DECLARE @auditId BIGINT,@transId BIGINT,@identificadorCampania NVARCHAR(200);
   SET @identificadorCampania=CONVERT(NVARCHAR(200),@camp);
   EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
     @usuario,@sesion,@dispositivo,@modulo,@cAccion,'finanzas','APAPPSS_E5',@identificadorCampania,
     NULL,NULL,NULL,'operacion',NULL,@cAccion,@ip,@corr,@sol,@endpoint,@auditId OUTPUT,@transId OUTPUT;
   COMMIT TRANSACTION;
  END;
  SELECT @bResultado=1,@cCodigoRespuesta='E5_OK',@nHttpRespuesta=200,@cMensaje=N'Operación completada.';
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SET @bResultado=0;SET @cDatos=NULL;
  SET @cCodigoRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51600 AND 51699 THEN 'E5_VALIDACION' ELSE 'E5_BD_ERROR' END;
  SET @nHttpRespuesta=CASE WHEN ERROR_NUMBER() IN(51600,51601,51636) THEN 403
      WHEN ERROR_NUMBER() BETWEEN 51600 AND 51699 THEN 409 ELSE 503 END;
  SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51600 AND 51699 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo completar la operación. Verifique los datos y vuelva a intentar.' END;
 END CATCH;
END;
GO
