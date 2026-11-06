-- Conserva el movimiento original y registra su inverso una sola vez.
ALTER TABLE logistica.SuministroMovimiento ADD movimiento_anulado_id BIGINT NULL
 REFERENCES logistica.SuministroMovimiento(suministro_movimiento_id);
GO
CREATE UNIQUE INDEX UX_SuministroMovimiento_Anulacion ON logistica.SuministroMovimiento(movimiento_anulado_id) WHERE movimiento_anulado_id IS NOT NULL;
GO
IF OBJECT_ID(N'logistica.PA_SuministroUOT_Upd_AnularMovimiento',N'P') IS NOT NULL DROP PROCEDURE logistica.PA_SuministroUOT_Upd_AnularMovimiento;
GO
IF OBJECT_ID(N'logistica.PA_SuministroUOT_Upd_AnularMovimiento', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_SuministroUOT_Upd_AnularMovimiento;
GO
CREATE PROCEDURE logistica.PA_SuministroUOT_Upd_AnularMovimiento
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT,@nMovimientoId BIGINT,@cMotivo NVARCHAR(300),
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo anular el movimiento.',@cCodigoRespuesta='SUMINISTRO_MOVIMIENTO_NO_ANULADO',@nHttpRespuesta=400;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300),@Suministro BIGINT,@Tipo VARCHAR(25),@Cantidad DECIMAL(19,3),@Disponible DECIMAL(19,3);
 EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'INVENTARIO_EDITAR',1,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg;RETURN 1;END;
 SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
 IF @cMotivo IS NULL BEGIN SET @cMensaje=N'Indique el motivo de anulación.';RETURN 1;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  SELECT @Suministro=suministro_id,@Tipo=tipo_movimiento,@Cantidad=cantidad
  FROM logistica.SuministroMovimiento WITH(UPDLOCK,HOLDLOCK)
  WHERE suministro_movimiento_id=@nMovimientoId AND uot_id=@Uot AND estado=1 AND recurso_programado_id IS NULL
   AND movimiento_anulado_id IS NULL AND tipo_movimiento NOT IN('TRANSFERENCIA_ENTRADA','TRANSFERENCIA_SALIDA');
  IF @Suministro IS NULL THROW 51122,N'El movimiento no está disponible para anulación.',1;
  IF NOT EXISTS(SELECT 1 FROM logistica.SuministroMovimiento WITH(UPDLOCK,HOLDLOCK) WHERE movimiento_anulado_id=@nMovimientoId)
  BEGIN
   SELECT @Disponible=stock_disponible FROM logistica.SuministroSaldo WITH(UPDLOCK,HOLDLOCK) WHERE suministro_id=@Suministro;
   IF @Tipo IN('ENTRADA','AJUSTE_ENTRADA','DEVOLUCION') AND COALESCE(@Disponible,0)<@Cantidad
    THROW 51122,N'No hay stock disponible suficiente para anular esta entrada sin afectar reservas o consumos.',1;
   INSERT logistica.SuministroMovimiento(suministro_id,uot_id,tipo_movimiento,cantidad,usuario_id,documento_referencia,observacion,estado,movimiento_anulado_id)
   VALUES(@Suministro,@Uot,CASE WHEN @Tipo IN('ENTRADA','AJUSTE_ENTRADA','DEVOLUCION') THEN 'AJUSTE_SALIDA' ELSE 'AJUSTE_ENTRADA' END,
    @Cantidad,@nUsuarioId,CONCAT('ANULACION-',@nMovimientoId),@cMotivo,1,@nMovimientoId);
  END;
  COMMIT;SELECT @bResultado=1,@cMensaje=N'Movimiento anulado mediante compensación.',@cCodigoRespuesta='SUMINISTRO_MOVIMIENTO_ANULADO',@nHttpRespuesta=200;RETURN 0;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  SET @cMensaje=CASE WHEN ERROR_NUMBER()=51122 THEN ERROR_MESSAGE() ELSE N'No se pudo registrar la compensación del movimiento.' END;RETURN 1;
 END CATCH;
END;
GO
