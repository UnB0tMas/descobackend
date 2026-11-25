IF OBJECT_ID(N'[comercial].[PA_CampaniaVenta_Upd_Activar]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Activar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaVenta_Upd_Activar
' Descripción            : Gestiona campania venta: activar.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Activar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
-- Un socio participa cuando al menos uno de sus fundos tiene disponibilidad declarada
-- para la campaña. El expediente por planta no constituye por si solo disponibilidad.
IF NOT EXISTS
(
 SELECT 1
 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id
  AND SA.asociacion_id=@nAsociacion AND SA.estado=1
 JOIN prod.PredioTitularidad PT ON PT.socio_id=SA.socio_id AND PT.estado=1
  AND PT.fecha_desde<=@dFin AND (PT.fecha_hasta IS NULL OR PT.fecha_hasta>=@dInicio)
 JOIN prod.Predio PD0 ON PD0.predio_id=PT.predio_id AND PD0.estado=1
 JOIN prod.FundoProduccionE3 FP ON FP.predio_id=PT.predio_id AND FP.uot_id=@nUot
  AND FP.fecha_desde<=@dFin AND FP.fecha_hasta>=@dInicio
  AND FP.estado_produccion IN('DISPONIBLE','PARCIAL') AND FP.cantidad_disponible_kg>0
  AND NOT EXISTS(SELECT 1 FROM prod.FundoHabilitacion H0
    WHERE H0.predio_id=FP.predio_id AND H0.convenio_id=FP.convenio_id AND H0.habilitado=0)
 JOIN org.ConvenioUOTOrganizacion CUO ON CUO.convenio_uot_organizacion_id=FP.convenio_id
  AND CUO.empresa_id=@nAsociacion AND CUO.uot_id=@nUot AND CUO.estado=1
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
   AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
       WHERE P.predio_id=FP.predio_id AND P.convenio_id=FP.convenio_id
        AND P.uot_id=@nUot AND P.activo=1 AND P.estado_actual IN('SIN_EVALUAR','SANA','ENFERMA'))
)
AND NOT EXISTS
(
 -- Compatibilidad con declaraciones anteriores a la nueva ficha del fundo.
 SELECT 1 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id AND SA.estado=1
 JOIN prod.PredioTitularidad PT ON PT.socio_id=SA.socio_id AND PT.estado=1
 JOIN prod.Predio PD1 ON PD1.predio_id=PT.predio_id AND PD1.estado=1
 JOIN prod.Parcela P ON P.predio_id=PT.predio_id AND P.estado=1
 JOIN prod.ParcelaCultivo PC ON PC.parcela_id=P.parcela_id
  AND PC.estado=1 AND PC.situacion_cultivo='ACTIVO'
 JOIN prod.DisponibilidadProduccion DP ON DP.parcela_cultivo_id=PC.parcela_cultivo_id
  AND DP.estado=1 AND DP.estado_estimacion IN('ESTIMADA','CONFIRMADA')
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
  AND SA.asociacion_id=@nAsociacion
  AND PT.fecha_desde<=@dFin AND (PT.fecha_hasta IS NULL OR PT.fecha_hasta>=@dInicio)
  AND DP.cantidad_estimada_kg>0
  AND DP.disponible_desde<=@dFin AND (DP.disponible_hasta IS NULL OR DP.disponible_hasta>=@dInicio)
  AND NOT EXISTS(SELECT 1 FROM prod.FundoHabilitacion H0
    JOIN org.ConvenioUOTOrganizacion C0 ON C0.convenio_uot_organizacion_id=H0.convenio_id
      AND C0.empresa_id=@nAsociacion AND C0.uot_id=@nUot
    WHERE H0.predio_id=PT.predio_id AND H0.habilitado=0)
)
AND NOT EXISTS
(
 -- También acepta un fundo habilitado explícitamente con plantas activas, sin declarar kilos.
 SELECT 1 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id
  AND SA.asociacion_id=@nAsociacion AND SA.estado=1
 JOIN prod.PredioTitularidad T ON T.socio_id=SA.socio_id AND T.estado=1
  AND T.fecha_desde<=@dFin AND (T.fecha_hasta IS NULL OR T.fecha_hasta>=@dInicio)
 JOIN prod.Predio PD ON PD.predio_id=T.predio_id AND PD.estado=1
 JOIN prod.FundoHabilitacion H ON H.predio_id=PD.predio_id AND H.uot_id=@nUot AND H.habilitado=1
 JOIN prod.PredioAmbito A ON A.predio_id=PD.predio_id AND A.uot_id=@nUot
  AND A.convenio_uot_organizacion_id=H.convenio_id AND A.estado=1
 JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=H.convenio_id
  AND C.uot_id=@nUot AND C.empresa_id=@nAsociacion AND C.estado=1
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
 AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
  WHERE P.predio_id=PD.predio_id AND P.convenio_id=H.convenio_id AND P.uot_id=@nUot
   AND P.activo=1 AND P.estado_actual NOT IN('MUERTA','ELIMINADA'))
)
BEGIN
 SET @cMensaje=N'No hay producción disponible de los participantes para las fechas de la campaña.';
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
