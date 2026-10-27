IF OBJECT_ID(N'[logistica].[PA_RecursoProgramado_Ins_Asignar]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_RecursoProgramado_Ins_Asignar];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_RecursoProgramado_Ins_Asignar
' Descripción             : Registra la asignación de un recurso programado.
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
    EXEC [logistica].[PA_RecursoProgramado_Ins_Asignar]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_RecursoProgramado_Ins_Asignar]
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
   @cJson=@cJson,@cCodigoPermiso=N'RECURSOS_CREAR',@cAmbito=N'RECURSO_ASIGNAR',
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
   SET @cMensaje=CASE WHEN @vEstado='COMPLETADA' THEN N'Recurso entregado.' ELSE N'La acción está en proceso.' END;
   IF @vEstado='FALLIDA'
    SELECT @cMensaje=COALESCE(mensaje_resultado,N'La acción anterior no se completó.')
    FROM auditoria.OperacionIdempotente WHERE operacion_idempotente_id=@vOperacion;
   GOTO Salida;
  END;
  IF @vTranEntrada=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION @vSave;
  SET @vTranAbierta=1;

  DECLARE @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.recurso.recursoProgramadoId')),
   @bien BIGINT,@sum BIGINT,@cantidad DECIMAL(14,3),@camp BIGINT,@op BIGINT,@salida BIGINT,@valido BIT,@msg NVARCHAR(300);
  SELECT @bien=bien_inventario_id,@sum=suministro_id,@cantidad=cantidad_programada,
   @camp=campania_venta_id,@op=operativo_venta_id,@salida=salida_campo_id
  FROM logistica.RecursoProgramado WITH(UPDLOCK,HOLDLOCK)
  WHERE recurso_programado_id=@id AND estado=1 AND estado_proceso='PROGRAMADO';
  IF @cantidad IS NULL THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
  EXEC logistica.PA_RecursoProgramado_Sel_ValidarDestinoInterno @camp,@op,@salida,'ASIGNAR',@valido OUTPUT,@msg OUTPUT;
  IF ISNULL(@valido,0)=0 THROW 51000,@msg,1;
  IF @bien IS NOT NULL
  BEGIN
   UPDATE logistica.BienInventario SET estado_bien='ASIGNADO'
   WHERE bien_inventario_id=@bien AND estado=1 AND estado_bien='DISPONIBLE';
   IF @@ROWCOUNT<>1 THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
  END;
  -- Se libera primero la reserva dentro de esta misma transacción.
  UPDATE logistica.RecursoProgramado SET estado_proceso='EN_EJECUCION' WHERE recurso_programado_id=@id AND estado_proceso='PROGRAMADO';
  IF @@ROWCOUNT<>1 THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
  INSERT logistica.RecursoMovimiento(recurso_programado_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,observacion,estado)
  VALUES(@id,CASE WHEN @bien IS NOT NULL THEN 'ASIGNACION' ELSE 'ENTREGA' END,@cantidad,SYSUTCDATETIME(),@vUsuario,N'Recurso entregado.',1);
  SET @vId=CONVERT(NVARCHAR(200),@id);

  EXEC auditoria.PA_Operacion_Ins_RegistrarCambio
   @nUsuarioId=@vUsuario,@nSesionUsuarioId=@vSesion,@nDispositivoUsuarioId=@vDisp,@nModuloId=@vModulo,
   @cAccion=N'RECURSO_ASIGNAR',@cEsquemaEntidad=N'logistica',@cNombreEntidad=N'RecursoProgramado',@cIdentificador=@vId,
   @cIp=@vIp,@gCorrelacionId=@vCorr,@gSolicitudId=@vSol,@cEndpoint=@vEndpoint,
   @nAuditoriaEventoId=@vAud OUTPUT,@nTransicionEstadoId=@vTrans OUTPUT;
  EXEC auditoria.PA_OperacionIdempotente_Upd_Finalizar
   @nOperacionIdempotenteId=@vOperacion,@cEstadoOperacion='COMPLETADA',
   @cEsquemaEntidad=N'logistica',@cNombreEntidad=N'RecursoProgramado',@cIdentificadorResultado=@vId,
   @cCodigoResultado=N'RECURSO_ASIGNAR',@bResultado=@vOk OUTPUT,@cMensaje=@vMsg OUTPUT;
  IF ISNULL(@vOk,0)=0 THROW 51003,N'DESCO_IDEMPOTENCIA_NO_CERRADA',1;
  IF @vTranEntrada=0 COMMIT TRANSACTION;
  SET @vTranAbierta=0;
  SELECT @bResultado=1,@cMensaje=N'Recurso entregado.';
 END TRY
 BEGIN CATCH
  IF @vTranAbierta=1
  BEGIN
   IF @vTranEntrada=0 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
   ELSE IF @vTranEntrada>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION @vSave;
   SET @vTranAbierta=0;
  END;
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'logistica.PA_RecursoProgramado_Ins_Asignar',@cMensaje=@cMensaje OUTPUT,@cJson=@cJson;
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
FROM config.FN_RespuestaUsuario(N'logistica.PA_RecursoProgramado_Ins_Asignar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
