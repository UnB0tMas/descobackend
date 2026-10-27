IF OBJECT_ID(N'[logistica].[PA_SuministroUOT_Ins_Movimiento]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroUOT_Ins_Movimiento];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroUOT_Ins_Movimiento
' Descripción             : Registra un movimiento de suministros de una UOT.
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
    DECLARE
        @nMovimientoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_SuministroUOT_Ins_Movimiento]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @nSuministroId = 0,
        @cTipo = '',
        @nCantidad = 0,
        @cDocumento = N'',
        @cObservacion = N'',
        @nMovimientoId = @nMovimientoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nMovimientoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_SuministroUOT_Ins_Movimiento
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT,@nSuministroId BIGINT,@cTipo VARCHAR(30),@nCantidad DECIMAL(19,3),@cDocumento NVARCHAR(120)=NULL,@cObservacion NVARCHAR(300)=NULL,
 @nMovimientoId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SELECT @nMovimientoId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar el movimiento.',@cCodigoRespuesta='SUMINISTRO_MOVIMIENTO_NO_CREADO',@nHttpRespuesta=400;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300); EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'INVENTARIO_EDITAR',1,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; RETURN 1; END;
 SET @cTipo=UPPER(NULLIF(LTRIM(RTRIM(@cTipo)),''));
 IF @cTipo NOT IN('ENTRADA','AJUSTE_ENTRADA','AJUSTE_SALIDA') OR @nCantidad IS NULL OR @nCantidad<=0 BEGIN SET @cMensaje=N'El movimiento no es valido.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Suministro WHERE suministro_id=@nSuministroId AND uot_id=@Uot AND estado=1) BEGIN SET @cMensaje=N'El suministro no esta disponible en la UOT.'; SET @nHttpRespuesta=404; RETURN 1; END;
 DECLARE @Disponible DECIMAL(19,3)=COALESCE((SELECT stock_disponible FROM logistica.SuministroSaldo WHERE suministro_id=@nSuministroId),0);
 IF @cTipo='AJUSTE_SALIDA' AND @nCantidad>@Disponible BEGIN SET @cMensaje=N'La cantidad supera el stock disponible.'; SET @cCodigoRespuesta='STOCK_INSUFICIENTE'; SET @nHttpRespuesta=409; RETURN 1; END;
 BEGIN TRY
  INSERT logistica.SuministroMovimiento(suministro_id,uot_id,recurso_programado_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,documento_referencia,observacion,estado)
  VALUES(@nSuministroId,@Uot,NULL,@cTipo,@nCantidad,SYSUTCDATETIME(),@nUsuarioId,NULLIF(LTRIM(RTRIM(@cDocumento)),N''),NULLIF(LTRIM(RTRIM(@cObservacion)),N''),1);
  SET @nMovimientoId=SCOPE_IDENTITY(); SELECT @bResultado=1,@cMensaje=N'Movimiento registrado.',@cCodigoRespuesta='SUMINISTRO_MOVIMIENTO_CREADO',@nHttpRespuesta=201; RETURN 0;
 END TRY BEGIN CATCH SET @nMovimientoId=NULL; SET @cMensaje=N'No se pudo registrar el movimiento.'; RETURN 1; END CATCH;
END;
GO
