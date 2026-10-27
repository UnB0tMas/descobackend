IF OBJECT_ID(N'[logistica].[PA_SuministroMovimiento_Upd_Anular]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroMovimiento_Upd_Anular];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroMovimiento_Upd_Anular
' Descripción             : Anula movimiento de suministro.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
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
    EXEC [logistica].[PA_SuministroMovimiento_Upd_Anular]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_SuministroMovimiento_Upd_Anular]
(@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @vUsuario BIGINT,@vSesion BIGINT,@vDisp BIGINT,@vEmpleado BIGINT,@vModulo INT,
 @vCorr UNIQUEIDENTIFIER,@vSol UNIQUEIDENTIFIER,@vIp VARCHAR(64),@vEndpoint NVARCHAR(250),
 @vOperacion BIGINT,@vRepetida BIT=0,@vEstado VARCHAR(20),@vId NVARCHAR(200),@vCodigo VARCHAR(40),
 @vOk BIT,@vMsg NVARCHAR(300),@vAud BIGINT,@vTrans BIGINT,
 @vTranEntrada INT=@@TRANCOUNT,@vTranAbierta BIT=0,
 @vSave VARCHAR(32)=REPLACE(CONVERT(VARCHAR(36),NEWID()),'-','');
 SELECT @bResultado=0,@cMensaje=N'No se pudo completar la acción.';
 
 BEGIN TRY
  EXEC seg.PA_Operacion_Ins_IniciarIdempotente
   @cJson=@cJson,@cCodigoPermiso=N'INVENTARIO_EDITAR',@cAmbito=N'SUMINISTRO_ANULAR',
   @nUsuarioId=@vUsuario OUTPUT,@nSesionUsuarioId=@vSesion OUTPUT,@nDispositivoUsuarioId=@vDisp OUTPUT,
   @nEmpleadoId=@vEmpleado OUTPUT,@nModuloId=@vModulo OUTPUT,@gCorrelacionId=@vCorr OUTPUT,
   @gSolicitudId=@vSol OUTPUT,@cIp=@vIp OUTPUT,@cEndpoint=@vEndpoint OUTPUT,
   @nOperacionIdempotenteId=@vOperacion OUTPUT,@bEsRepetida=@vRepetida OUTPUT,
   @cEstadoOperacion=@vEstado OUTPUT,@cIdentificadorResultado=@vId OUTPUT,
   @cCodigoResultado=@vCodigo OUTPUT,@bResultado=@vOk OUTPUT,@cMensaje=@vMsg OUTPUT;
  IF ISNULL(@vOk,0)=0 AND ISNULL(@vRepetida,0)=0
  BEGIN SET @cMensaje=@vMsg; GOTO Salida; END;
  IF @vRepetida=1
  BEGIN
   
   SET @bResultado=CASE WHEN @vEstado='COMPLETADA' THEN 1 ELSE 0 END;
   SET @cMensaje=CASE WHEN @vEstado='COMPLETADA' THEN N'Movimiento anulado.' ELSE N'La acción está en proceso.' END;
   IF @vEstado='FALLIDA'
    SELECT @cMensaje=COALESCE(mensaje_resultado,N'La acción anterior no se completó.')
    FROM auditoria.OperacionIdempotente WHERE operacion_idempotente_id=@vOperacion;
   GOTO Salida;
  END;
  IF @vTranEntrada=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION @vSave;
  SET @vTranAbierta=1;

  DECLARE @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.movimiento.suministroMovimientoId')),
   @sum BIGINT,@cantidad DECIMAL(14,3),@tipo VARCHAR(20),@origen BIGINT,@recurso BIGINT,
   @motivo NVARCHAR(300)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.movimiento.motivo'))),N'');
  IF @motivo IS NULL THROW 51000,N'Indique el motivo de la anulación.',1;
  SELECT @sum=suministro_id,@cantidad=cantidad,@tipo=tipo_movimiento,@origen=movimiento_origen_id,@recurso=recurso_programado_id
  FROM logistica.SuministroMovimiento WITH(UPDLOCK,HOLDLOCK) WHERE suministro_movimiento_id=@id AND estado=1;
  IF @sum IS NULL OR @origen IS NOT NULL OR @recurso IS NOT NULL
   THROW 51100,N'DESCO_REVERSION_NO_VALIDA',1;
  IF EXISTS(SELECT 1 FROM logistica.SuministroMovimiento WITH(UPDLOCK,HOLDLOCK) WHERE movimiento_origen_id=@id)
   THROW 51000,N'El movimiento ya fue anulado.',1;
  INSERT logistica.SuministroMovimiento(suministro_id,movimiento_origen_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,observacion,estado)
  VALUES(@sum,@id,CASE WHEN @tipo IN('ENTRADA','DEVOLUCION','AJUSTE_ENTRADA') THEN 'AJUSTE_SALIDA' ELSE 'AJUSTE_ENTRADA' END,
   @cantidad,SYSUTCDATETIME(),@vUsuario,@motivo,1);
  SET @vId=CONVERT(NVARCHAR(200),@id);

  EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
   @nUsuarioId=@vUsuario,@nSesionUsuarioId=@vSesion,@nDispositivoUsuarioId=@vDisp,@nModuloId=@vModulo,
   @cAccion=N'SUMINISTRO_ANULAR',@cEsquemaEntidad=N'logistica',@cNombreEntidad=N'SuministroMovimiento',@cIdentificador=@vId,
   @cIp=@vIp,@gCorrelacionId=@vCorr,@gSolicitudId=@vSol,@cEndpoint=@vEndpoint,
   @nAuditoriaEventoId=@vAud OUTPUT,@nTransicionEstadoId=@vTrans OUTPUT;
  EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar
   @nOperacionIdempotenteId=@vOperacion,@cEstadoOperacion='COMPLETADA',
   @cEsquemaEntidad=N'logistica',@cNombreEntidad=N'SuministroMovimiento',@cIdentificadorResultado=@vId,
   @cCodigoResultado=N'SUMINISTRO_ANULAR',@bResultado=@vOk OUTPUT,@cMensaje=@vMsg OUTPUT;
  IF ISNULL(@vOk,0)=0 THROW 51003,N'DESCO_IDEMPOTENCIA_NO_CERRADA',1;
  IF @vTranEntrada=0 COMMIT TRANSACTION;
  SET @vTranAbierta=0;
  SELECT @bResultado=1,@cMensaje=N'Movimiento anulado.';
 END TRY
 BEGIN CATCH
  IF @vTranAbierta=1
  BEGIN
   IF @vTranEntrada=0 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
   ELSE IF @vTranEntrada>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION @vSave;
   SET @vTranAbierta=0;
  END;
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'logistica.PA_SuministroMovimiento_Upd_Anular',@cMensaje=@cMensaje OUTPUT,@cJson=@cJson;
 END CATCH;
Salida:
 IF @bResultado=0 AND @vOperacion IS NOT NULL AND ISNULL(@vRepetida,0)=0 AND XACT_STATE()<>-1
 BEGIN TRY
  EXEC auditoria.PA_OperacionIdempotente_Upd_MensajeFallido @vOperacion,@cMensaje;
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
 END CATCH;
 
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'logistica.PA_SuministroMovimiento_Upd_Anular',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
