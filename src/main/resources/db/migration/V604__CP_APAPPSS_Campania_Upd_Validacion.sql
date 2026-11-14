-- Se conserva el PA original, su idempotencia, auditoría y lógica de actualización.
-- Se corrige autorización territorial, comprador y fechas.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Registro](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bModoGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@nId BIGINT,@nComprador BIGINT,@cNombre NVARCHAR(180),@dInicio DATE,@dFin DATE,@cObs NVARCHAR(400),@cAnt NVARCHAR(MAX),@cPost NVARCHAR(MAX),@cIdent NVARCHAR(200);
    SELECT @bResultado=0,@cMensaje=N'No se pudo actualizar la campaña.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',@cAmbito='CAMPANIA_EDITAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SELECT @nId=campaniaVentaId,@nUotSolicitada=uotId,@nComprador=empresaCompradoraId,@cNombre=NULLIF(LTRIM(RTRIM(nombre)),N''),@dInicio=fechaInicio,@dFin=fechaFin,@cObs=NULLIF(LTRIM(RTRIM(observacion)),N'') FROM OPENJSON(@cJson,'$.campania') WITH(campaniaVentaId BIGINT '$.campaniaVentaId',uotId BIGINT '$.uotId',empresaCompradoraId BIGINT '$.empresaCompradoraId',nombre NVARCHAR(180) '$.nombre',fechaInicio DATE '$.fechaInicio',fechaFin DATE '$.fechaFin',observacion NVARCHAR(400) '$.observacion');
IF @nId IS NULL OR @nComprador IS NULL OR @cNombre IS NULL OR @dInicio IS NULL OR @dFin IS NULL
   OR @dInicio<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) OR @dFin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) OR @dFin<@dInicio
 BEGIN SET @cMensaje=N'Las fechas de la campaña deben ser futuras o de hoy y estar ordenadas.';
GOTO Fallar;
END;
-- Usar el ámbito de la campaña; nunca un id de UOT arbitrario del cliente ni el origen legacy de la asociación.
SELECT @nUot=C.uot_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@nId AND C.estado=1 AND C.estado_proceso='PLANIFICACION';
IF @nUot IS NULL OR (@nUotSolicitada IS NOT NULL AND @nUotSolicitada<>@nUot) BEGIN SET @cMensaje=N'Solo puede editar una campaña en planificación de su UOT.';
GOTO Fallar;
END;
IF seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_EDITAR')<>1 BEGIN SET @cMensaje=N'No tiene acceso a editar esta campaña.';
GOTO Fallar;
END;
IF NOT EXISTS (SELECT 1 FROM comercial.CampaniaVenta CV
  JOIN org.Empresa AE ON AE.empresa_id=CV.asociacion_id AND AE.ruc='20602771394' AND AE.estado=1
  JOIN org.ConvenioUOTOrganizacion CU ON CU.uot_id=CV.uot_id AND CU.empresa_id=AE.empresa_id AND CU.estado=1
  JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
  JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
  WHERE CV.campania_venta_id=@nId AND CU.tipo_vinculo='ASOCIACION'
    AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
    AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
BEGIN SET @cMensaje=N'La UOT no tiene el convenio APAPPSS vigente.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.CompradorAPAPPSS B
   JOIN org.Empresa E ON E.empresa_id=B.empresa_id AND E.estado=1
   WHERE B.uot_id=@nUot AND B.empresa_id=@nComprador AND B.tipo='EMPRESA' AND B.estado=1)
BEGIN SET @cMensaje=N'El comprador debe estar registrado para APAPPSS.';
GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
SELECT @cAnt=(SELECT campania_venta_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
UPDATE comercial.CampaniaVenta SET empresa_compradora_id=@nComprador,nombre=@cNombre,fecha_inicio=@dInicio,fecha_fin=@dFin,observacion=@cObs WHERE campania_venta_id=@nId;
SELECT @cPost=(SELECT campania_venta_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'EDITAR','comercial','CampaniaVenta',@cIdent,@cAnt,@cPost,NULL,NULL,NULL,NULL,@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='CampaniaVenta',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CAMPANIA_ACTUALIZADA',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
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
SET @cMensaje=N'Campaña actualizada.';
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
SET @cMensaje=N'No se pudo actualizar la campaña. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Registro',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Registro',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Registro',
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
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Registro',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Upd_Registro',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
