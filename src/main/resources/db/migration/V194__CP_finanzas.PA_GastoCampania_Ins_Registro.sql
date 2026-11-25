IF OBJECT_ID(N'[finanzas].[PA_GastoCampania_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_GastoCampania_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : finanzas.PA_GastoCampania_Ins_Registro
' Descripción            : Registra la información de gasto campania.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   PROCEDURE [finanzas].[PA_GastoCampania_Ins_Registro](@cJson NVARCHAR(MAX),@nGastoCampaniaId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nCamp BIGINT,@nOpVenta BIGINT,@nTipo SMALLINT,@nRegla SMALLINT,@dFecha DATE,@cConcepto NVARCHAR(250),@nImporte DECIMAL(19,4),@cMoneda CHAR(3),@cIdent NVARCHAR(200);
SELECT @bResultado=0,@cMensaje=N'No se pudo registrar el gasto.';
EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='GASTOS_CREAR',@cAmbito='GASTO_CREAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
IF @bRep=1 BEGIN SET @nGastoCampaniaId=CASE WHEN @cEstadoOp='COMPLETADA' THEN TRY_CONVERT(BIGINT,@cIdRes) ELSE NULL END;
 SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
 SET @nGastoCampaniaId=NULL;
SELECT @nCamp=campaniaVentaId,@nOpVenta=operativoVentaId,@nTipo=tipoGastoId,@nRegla=reglaProrrateoId,@dFecha=fecha,@cConcepto=NULLIF(LTRIM(RTRIM(concepto)),N''),@nImporte=importe,@cMoneda=UPPER(NULLIF(LTRIM(RTRIM(moneda)),'')) FROM OPENJSON(@cJson,'$.gasto') WITH(campaniaVentaId BIGINT '$.campaniaVentaId',operativoVentaId BIGINT '$.operativoVentaId',tipoGastoId SMALLINT '$.tipoGastoId',reglaProrrateoId SMALLINT '$.reglaProrrateoId',fecha DATE '$.fecha',concepto NVARCHAR(250) '$.concepto',importe DECIMAL(19,4) '$.importe',moneda CHAR(3) '$.moneda');
IF @nCamp IS NULL OR @nTipo IS NULL OR @nRegla IS NULL OR @dFecha IS NULL OR @cConcepto IS NULL OR @nImporte<=0 OR @cMoneda IS NULL BEGIN SET @cMensaje=N'Complete correctamente los datos del gasto.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@nCamp AND estado=1 AND estado_proceso IN('ACTIVA','CERRADA')) OR NOT EXISTS(SELECT 1 FROM finanzas.TipoGasto WHERE tipo_gasto_id=@nTipo AND estado=1) OR NOT EXISTS(SELECT 1 FROM finanzas.ReglaProrrateo WHERE regla_prorrateo_id=@nRegla AND estado=1) BEGIN SET @cMensaje=N'La campaña, tipo de gasto o regla seleccionada no está disponible.';
GOTO Fallar;
END;
DECLARE @__E5Lock INT,@__E5Camp BIGINT;
SELECT @__E5Camp=@nCamp;
IF EXISTS (SELECT 1 FROM finanzas.PagoSocio PG
 JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PG.liquidacion_socio_id
 JOIN comercial.ParticipacionCampaniaSocio PS ON PS.participacion_campania_socio_id=L.participacion_campania_socio_id
 WHERE PS.campania_venta_id=@__E5Camp AND PG.estado=1 AND PG.estado_proceso IN('CONFIRMADO','ANULADO'))
 THROW 51810,N'No se admiten cambios de gastos porque ya se realizó un pago a socios.',1;
IF NOT EXISTS(SELECT 1 FROM finanzas.ReglaProrrateo R WHERE R.regla_prorrateo_id=@nRegla
 AND (UPPER(R.codigo)='IGUAL' OR UPPER(R.codigo) LIKE 'DI-%'))
 BEGIN SET @cMensaje=N'En APAPPSS los gastos se distribuyen de forma igualitaria.';GOTO Fallar;END;
IF @nOpVenta IS NOT NULL AND NOT EXISTS(SELECT 1 FROM comercial.OperativoVenta WHERE operativo_venta_id=@nOpVenta AND campania_venta_id=@nCamp AND estado=1) BEGIN SET @cMensaje=N'El operativo seleccionado no corresponde a la campaña.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
DECLARE @__E5LockResource NVARCHAR(255)=CONCAT('APAPPSS_E5_CAMP_',@__E5Camp);
EXEC @__E5Lock=sys.sp_getapplock @Resource=@__E5LockResource,
 @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
IF @__E5Lock<0 THROW 51811,N'La campaña está siendo procesada.',1;
IF EXISTS (SELECT 1 FROM finanzas.PagoSocio PG
 JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PG.liquidacion_socio_id
 JOIN comercial.ParticipacionCampaniaSocio PS ON PS.participacion_campania_socio_id=L.participacion_campania_socio_id
 WHERE PS.campania_venta_id=@__E5Camp AND PG.estado=1 AND PG.estado_proceso IN('CONFIRMADO','ANULADO'))
 THROW 51810,N'No se admiten cambios de gastos porque ya se realizó un pago a socios.',1;

INSERT finanzas.GastoCampania(campania_venta_id,operativo_venta_id,tipo_gasto_id,regla_prorrateo_id,fecha,concepto,importe,moneda,estado_proceso,estado) VALUES(@nCamp,@nOpVenta,@nTipo,@nRegla,@dFecha,@cConcepto,@nImporte,@cMoneda,'REGISTRADO',1);
SET @nGastoCampaniaId=SCOPE_IDENTITY();
SET @cIdent=CONVERT(NVARCHAR(200),@nGastoCampaniaId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'REGISTRAR','finanzas','GastoCampania',@cIdent,NULL,NULL,NULL,'estado_proceso',NULL,'REGISTRADO',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='finanzas',@cNombreEntidad='GastoCampania',@cIdentificadorResultado=@cIdent,@cCodigoResultado='GASTO_REGISTRADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Gasto registrado correctamente.';
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
SET @cMensaje=N'No se pudo registrar el gasto. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_Registro',
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
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_Registro',
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
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_Registro',
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
    SELECT @nGastoCampaniaId = NULL;

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
    @cProcedimiento = N'finanzas.PA_GastoCampania_Ins_Registro',
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
FROM config.FN_RespuestaUsuario(N'finanzas.PA_GastoCampania_Ins_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
