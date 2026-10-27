IF OBJECT_ID(N'[logistica].[PA_SuministroUOT_Upd_AnularMovimiento]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroUOT_Upd_AnularMovimiento];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroUOT_Upd_AnularMovimiento
' Descripción             : Anula un movimiento de suministro por UOT.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_SuministroUOT_Upd_AnularMovimiento]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @nMovimientoId = 0,
        @cMotivo = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_SuministroUOT_Upd_AnularMovimiento
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT,@nMovimientoId BIGINT,@cMotivo NVARCHAR(300),
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo anular el movimiento.',@cCodigoRespuesta='SUMINISTRO_MOVIMIENTO_NO_ANULADO',@nHttpRespuesta=400;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300); EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'INVENTARIO_EDITAR',1,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; RETURN 1; END;
 SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N''); IF @cMotivo IS NULL BEGIN SET @cMensaje=N'Indique el motivo de anulacion.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.SuministroMovimiento WHERE suministro_movimiento_id=@nMovimientoId AND uot_id=@Uot AND estado=1 AND recurso_programado_id IS NULL AND tipo_movimiento NOT IN('TRANSFERENCIA_ENTRADA','TRANSFERENCIA_SALIDA'))
 BEGIN SET @cMensaje=N'El movimiento no esta disponible para anulacion.'; SET @nHttpRespuesta=404; RETURN 1; END;
 UPDATE logistica.SuministroMovimiento SET estado=0,observacion=CONCAT(COALESCE(observacion,N''),CASE WHEN observacion IS NULL THEN N'' ELSE N' | ' END,N'ANULADO: ',@cMotivo) WHERE suministro_movimiento_id=@nMovimientoId;
 SELECT @bResultado=1,@cMensaje=N'Movimiento anulado.',@cCodigoRespuesta='SUMINISTRO_MOVIMIENTO_ANULADO',@nHttpRespuesta=200; RETURN 0;
END;
GO
