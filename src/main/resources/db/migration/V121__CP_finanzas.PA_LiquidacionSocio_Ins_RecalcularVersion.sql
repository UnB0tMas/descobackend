IF OBJECT_ID(N'[finanzas].[PA_LiquidacionSocio_Ins_RecalcularVersion]', N'P') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_LiquidacionSocio_Ins_RecalcularVersion];
GO

/******************************************************************************************************
' Nombre del PA           : finanzas.PA_LiquidacionSocio_Ins_RecalcularVersion
' Descripción             : Recalcula una versión de liquidación de socio.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Finanzas
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
        @nNuevaLiquidacionSocioId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [finanzas].[PA_LiquidacionSocio_Ins_RecalcularVersion]
        @cJson = N'{}',
        @nNuevaLiquidacionSocioId = @nNuevaLiquidacionSocioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nNuevaLiquidacionSocioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [finanzas].[PA_LiquidacionSocio_Ins_RecalcularVersion](@cJson NVARCHAR(MAX),@nNuevaLiquidacionSocioId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nAnterior BIGINT,@nPart BIGINT,@cEstadoAnt VARCHAR(20),@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200),@cJsonCalc NVARCHAR(MAX),@bCalc BIT,@cMsgCalc NVARCHAR(300);
SELECT @bResultado=0,@cMensaje=N'No se pudo recalcular la liquidación.';
EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='LIQUIDACIONES_EDITAR',@cAmbito='LIQUIDACION_RECALCULAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
IF @bRep=1 BEGIN SET @nNuevaLiquidacionSocioId=CASE WHEN @cEstadoOp='COMPLETADA' THEN TRY_CONVERT(BIGINT,@cIdRes) ELSE NULL END;
 SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
 SET @nNuevaLiquidacionSocioId=NULL;
SELECT @nAnterior=liquidacionSocioId,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'') FROM OPENJSON(@cJson,'$.liquidacion') WITH(liquidacionSocioId BIGINT '$.liquidacionSocioId',motivo NVARCHAR(500) '$.motivo');
SELECT @nPart=participacion_campania_socio_id,@cEstadoAnt=estado_proceso FROM finanzas.LiquidacionSocio WHERE liquidacion_socio_id=@nAnterior AND estado=1;
IF @nPart IS NULL OR @cMotivo IS NULL OR @cEstadoAnt IN('PAGADA_PARCIAL','PAGADA') BEGIN SET @cMensaje=N'La liquidación no está disponible para recalcular o falta indicar el motivo.';
GOTO Fallar;
END;
IF EXISTS(SELECT 1 FROM finanzas.PagoSocio WHERE liquidacion_socio_id=@nAnterior AND estado=1 AND estado_proceso='CONFIRMADO') BEGIN SET @cMensaje=N'La liquidación ya tiene pagos confirmados y debe corregirse mediante un movimiento compensatorio.';
GOTO Fallar;
END;
-- se ejecuta cálculo directamente para mantener una única lógica material dentro de este PA
DECLARE @nVersion INT,@nBruto DECIMAL(19,4),@nAjustes DECIMAL(19,4),@nGastos DECIMAL(19,4),@nBoni DECIMAL(19,4),@nNeto DECIMAL(19,4),@cMoneda CHAR(3);
BEGIN
    IF @__DbTranAbierta = 0
    BEGIN
        IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 1;
    END;
END;
DECLARE @__CampaniaLiquidacion BIGINT;
SELECT @__CampaniaLiquidacion=C.campania_venta_id FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
JOIN comercial.ParticipacionCampaniaSocio P ON P.campania_venta_id=C.campania_venta_id WHERE P.participacion_campania_socio_id=@nPart;
IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
 JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
 JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
 WHERE OS.participacion_campania_socio_id=@nPart AND OS.estado=1 AND D.precio_comercial_id IS NULL)
 THROW 51000,N'Complete los precios de las entregas antes de liquidar.',1;
IF (SELECT COUNT(DISTINCT P.moneda) FROM comercial.OperativoSocio OS
 JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
 JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
 JOIN comercial.PrecioComercial P ON P.precio_comercial_id=D.precio_comercial_id
 WHERE OS.participacion_campania_socio_id=@nPart AND OS.estado=1)>1
 THROW 51000,N'Las entregas de la liquidación deben utilizar la misma moneda.',1;
SELECT @nVersion=COALESCE(MAX(version),0)+1 FROM finanzas.LiquidacionSocio WHERE participacion_campania_socio_id=@nPart;
SELECT @nBruto=COALESCE(SUM(CONVERT(DECIMAL(19,4),ED.importe)),0),@cMoneda=COALESCE(MAX(PC.moneda),'PEN') FROM comercial.OperativoSocio OS INNER JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA' INNER JOIN comercial.EntregaDetalle ED ON ED.entrega_socio_id=E.entrega_socio_id AND ED.estado=1 LEFT JOIN comercial.PrecioComercial PC ON PC.precio_comercial_id=ED.precio_comercial_id WHERE OS.participacion_campania_socio_id=@nPart AND OS.estado=1;
IF EXISTS(SELECT 1 FROM finanzas.GastoProrrateoSocio GP JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id
 WHERE GP.participacion_campania_socio_id=@nPart AND GP.estado=1 AND G.estado=1 AND G.estado_proceso='APROBADO' AND G.moneda<>@cMoneda)
 THROW 51000,N'Los gastos y las entregas deben utilizar la misma moneda.',1;
SELECT @nGastos=COALESCE(SUM(GP.importe_asignado),0) FROM finanzas.GastoProrrateoSocio GP INNER JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id AND G.estado=1 AND G.estado_proceso='APROBADO' WHERE GP.participacion_campania_socio_id=@nPart AND GP.estado=1;
SELECT @nAjustes=COALESCE(SUM(CASE WHEN A.tipo_ajuste IN('DESCUENTO_MONTO','SANCION') THEN COALESCE(A.monto_ajuste,0) WHEN A.tipo_ajuste='DESCUENTO_PORCENTAJE' THEN @nBruto*COALESCE(A.porcentaje_ajuste,0)/100.0 ELSE 0 END),0),@nBoni=COALESCE(SUM(CASE WHEN A.tipo_ajuste='BONIFICACION' THEN COALESCE(A.monto_ajuste,0) ELSE 0 END),0) FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@nPart AND A.estado=1 AND A.estado_ajuste='VIGENTE';
SET @nNeto=@nBruto-@nGastos-@nAjustes+@nBoni;
IF @nBruto<=0 OR @nNeto<0 BEGIN SET @cMensaje=N'No hay información válida para recalcular la liquidación.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranAbierta = 0
    BEGIN
        IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
        ELSE SAVE TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 1;
    END;
END;
UPDATE finanzas.LiquidacionSocio SET estado_proceso='ANULADA' WHERE liquidacion_socio_id=@nAnterior;
INSERT finanzas.LiquidacionSocio(participacion_campania_socio_id,version,fecha_calculo,importe_bruto,total_ajustes,total_gastos,total_bonificaciones,importe_neto,moneda,estado_proceso,estado) VALUES(@nPart,@nVersion,SYSUTCDATETIME(),@nBruto,@nAjustes,@nGastos,@nBoni,@nNeto,@cMoneda,'CALCULADA',1);
SET @nNuevaLiquidacionSocioId=SCOPE_IDENTITY();
INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,ajuste_precio_socio_id,concepto,importe,estado) SELECT @nNuevaLiquidacionSocioId,'VENTA',ED.entrega_detalle_id,NULL,NULL,N'Venta confirmada',CONVERT(DECIMAL(19,4),ED.importe),1 FROM comercial.OperativoSocio OS INNER JOIN comercial.EntregaSocio E ON E.operativo_socio_id=OS.operativo_socio_id AND E.estado=1 AND E.estado_proceso='CONFIRMADA' INNER JOIN comercial.EntregaDetalle ED ON ED.entrega_socio_id=E.entrega_socio_id AND ED.estado=1 WHERE OS.participacion_campania_socio_id=@nPart AND OS.estado=1;
INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,ajuste_precio_socio_id,concepto,importe,estado) SELECT @nNuevaLiquidacionSocioId,'GASTO',NULL,GP.gasto_prorrateo_socio_id,NULL,G.concepto,-GP.importe_asignado,1 FROM finanzas.GastoProrrateoSocio GP INNER JOIN finanzas.GastoCampania G ON G.gasto_campania_id=GP.gasto_campania_id AND G.estado=1 AND G.estado_proceso='APROBADO' WHERE GP.participacion_campania_socio_id=@nPart AND GP.estado=1;
INSERT finanzas.LiquidacionDetalle(liquidacion_socio_id,tipo,entrega_detalle_id,gasto_prorrateo_socio_id,ajuste_precio_socio_id,concepto,importe,estado) SELECT @nNuevaLiquidacionSocioId,CASE WHEN A.tipo_ajuste='BONIFICACION' THEN 'BONIFICACION' ELSE 'AJUSTE' END,NULL,NULL,A.ajuste_precio_socio_id,A.motivo,CASE WHEN A.tipo_ajuste='BONIFICACION' THEN COALESCE(A.monto_ajuste,0) WHEN A.tipo_ajuste='DESCUENTO_PORCENTAJE' THEN -(@nBruto*COALESCE(A.porcentaje_ajuste,0)/100.0) ELSE -COALESCE(A.monto_ajuste,0) END,1 FROM comercial.AjustePrecioSocio A WHERE A.participacion_campania_socio_id=@nPart AND A.estado=1 AND A.estado_ajuste='VIGENTE';
SET @cIdent=CONVERT(NVARCHAR(200),@nNuevaLiquidacionSocioId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'RECALCULAR','finanzas','LiquidacionSocio',@cIdent,NULL,NULL,@cMotivo,'estado_proceso',NULL,'CALCULADA',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='finanzas',@cNombreEntidad='LiquidacionSocio',@cIdentificadorResultado=@cIdent,@cCodigoResultado='LIQUIDACION_RECALCULADA',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Nueva versión de liquidación calculada correctamente.';
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
SET @cMensaje=N'No se pudo recalcular la liquidación. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'finanzas.PA_LiquidacionSocio_Ins_RecalcularVersion',
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
    @cProcedimiento = N'finanzas.PA_LiquidacionSocio_Ins_RecalcularVersion',
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
    @cProcedimiento = N'finanzas.PA_LiquidacionSocio_Ins_RecalcularVersion',
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
    SELECT @nNuevaLiquidacionSocioId = NULL;

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
    @cProcedimiento = N'finanzas.PA_LiquidacionSocio_Ins_RecalcularVersion',
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
FROM config.FN_RespuestaUsuario(N'finanzas.PA_LiquidacionSocio_Ins_RecalcularVersion',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
