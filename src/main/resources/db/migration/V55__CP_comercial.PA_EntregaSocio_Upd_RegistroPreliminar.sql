IF OBJECT_ID(N'[comercial].[PA_EntregaSocio_Upd_RegistroPreliminar]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_EntregaSocio_Upd_RegistroPreliminar];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_EntregaSocio_Upd_RegistroPreliminar
' Descripción             : Actualiza los datos preliminares de una entrega de socio.
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
    EXEC [comercial].[PA_EntregaSocio_Upd_RegistroPreliminar]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_EntregaSocio_Upd_RegistroPreliminar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nId BIGINT,@nBruto DECIMAL(14,3),@nTara DECIMAL(14,3),@nRech DECIMAL(14,3),@cCalidad VARCHAR(20),@cTicket VARCHAR(80),@cObs NVARCHAR(400),@nAceptado DECIMAL(14,3),@nSuma DECIMAL(14,3),@nCamp BIGINT,@nOpVenta BIGINT,@dFecha DATETIME2(0),@cIdent NVARCHAR(200);
SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar la entrega.';
EXEC seg.PA_Operacion_Ins_IniciarIdempotente @cJson=@cJson,@cCodigoPermiso='ENTREGAS_EDITAR',@cAmbito='ENTREGA_EDITAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
 SELECT @nId=entregaSocioId,@nBruto=pesoBrutoKg,@nTara=COALESCE(taraKg,0),@nRech=COALESCE(pesoRechazadoKg,0),@cCalidad=UPPER(COALESCE(NULLIF(LTRIM(RTRIM(estadoControlCalidad)),''),'PENDIENTE')),@cTicket=NULLIF(LTRIM(RTRIM(ticketBalanza)),''),@cObs=NULLIF(LTRIM(RTRIM(observacion)),N'') FROM OPENJSON(@cJson,'$.entrega') WITH(entregaSocioId BIGINT '$.entregaSocioId',pesoBrutoKg DECIMAL(14,3) '$.pesoBrutoKg',taraKg DECIMAL(14,3) '$.taraKg',pesoRechazadoKg DECIMAL(14,3) '$.pesoRechazadoKg',estadoControlCalidad VARCHAR(20) '$.estadoControlCalidad',ticketBalanza VARCHAR(80) '$.ticketBalanza',observacion NVARCHAR(400) '$.observacion');
SELECT @dFecha=E.fecha_hora,@nOpVenta=OS.operativo_venta_id,@nCamp=O.campania_venta_id FROM comercial.EntregaSocio E INNER JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id INNER JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id WHERE E.entrega_socio_id=@nId AND E.estado=1 AND E.estado_proceso='REGISTRADA';
SET @nAceptado=@nBruto-@nTara-@nRech;
SELECT @nSuma=SUM(kilogramos) FROM OPENJSON(@cJson,'$.detalles') WITH(kilogramos DECIMAL(14,3) '$.kilogramos');
IF @nCamp IS NULL OR @nBruto<=0 OR @nTara<0 OR @nRech<0 OR @nAceptado<0 OR ABS(COALESCE(@nSuma,0)-@nAceptado)>0.001 BEGIN SET @cMensaje=N'Complete correctamente los pesos y la clasificación de la entrega.';
GOTO Fallar;
END;
IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.detalles') WITH(variedadPaltaId SMALLINT '$.variedadPaltaId',condicionComercialId BIGINT '$.condicionComercialId') D WHERE NOT EXISTS(SELECT 1 FROM comercial.PrecioComercial P WHERE P.campania_venta_id=@nCamp AND (P.operativo_venta_id=@nOpVenta OR P.operativo_venta_id IS NULL) AND P.variedad_palta_id=D.variedadPaltaId AND P.condicion_comercial_id=D.condicionComercialId AND P.estado=1 AND P.fecha_vigencia_desde<=@dFecha AND (P.fecha_vigencia_hasta IS NULL OR P.fecha_vigencia_hasta>=@dFecha))) BEGIN SET @cMensaje=N'Falta un precio vigente para una de las clasificaciones.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
UPDATE comercial.EntregaSocio SET peso_bruto_kg=@nBruto,tara_kg=@nTara,peso_rechazado_kg=@nRech,estado_control_calidad=@cCalidad,ticket_balanza=@cTicket,observacion=@cObs WHERE entrega_socio_id=@nId;
UPDATE comercial.EntregaDetalle SET estado=0 WHERE entrega_socio_id=@nId AND estado=1;
INSERT comercial.EntregaDetalle(entrega_socio_id,variedad_palta_id,condicion_comercial_id,precio_comercial_id,kilogramos,precio_base,precio_aplicado,estado) SELECT @nId,D.variedadPaltaId,D.condicionComercialId,P.precio_comercial_id,D.kilogramos,P.precio,P.precio,1 FROM OPENJSON(@cJson,'$.detalles') WITH(variedadPaltaId SMALLINT '$.variedadPaltaId',condicionComercialId BIGINT '$.condicionComercialId',kilogramos DECIMAL(14,3) '$.kilogramos') D CROSS APPLY(SELECT TOP(1) PC.precio_comercial_id,PC.precio FROM comercial.PrecioComercial PC WHERE PC.campania_venta_id=@nCamp AND (PC.operativo_venta_id=@nOpVenta OR PC.operativo_venta_id IS NULL) AND PC.variedad_palta_id=D.variedadPaltaId AND PC.condicion_comercial_id=D.condicionComercialId AND PC.estado=1 AND PC.fecha_vigencia_desde<=@dFecha AND (PC.fecha_vigencia_hasta IS NULL OR PC.fecha_vigencia_hasta>=@dFecha) ORDER BY CASE WHEN PC.operativo_venta_id=@nOpVenta THEN 0 ELSE 1 END,PC.version DESC) P;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','comercial','EntregaSocio',@cIdent,NULL,NULL,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='EntregaSocio',@cIdentificadorResultado=@cIdent,@cCodigoResultado='ENTREGA_ACTUALIZADA',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Entrega actualizada correctamente.';
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
SET @cMensaje=N'No se pudo actualizar la entrega. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_EntregaSocio_Upd_RegistroPreliminar',
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
    @cProcedimiento = N'comercial.PA_EntregaSocio_Upd_RegistroPreliminar',
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
    @cProcedimiento = N'comercial.PA_EntregaSocio_Upd_RegistroPreliminar',
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
    @cProcedimiento = N'comercial.PA_EntregaSocio_Upd_RegistroPreliminar',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_EntregaSocio_Upd_RegistroPreliminar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
