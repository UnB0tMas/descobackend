IF OBJECT_ID(N'[logistica].[PA_SuministroUOT_Sel_Kardex]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroUOT_Sel_Kardex];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroUOT_Sel_Kardex
' Descripción             : Consulta el kardex de suministro por UOT.
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
    EXEC [logistica].[PA_SuministroUOT_Sel_Kardex]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotId = 0,
        @nSuministroId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_SuministroUOT_Sel_Kardex
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT=NULL,@nSuministroId BIGINT=NULL,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo consultar el Kardex.',@cCodigoRespuesta='KARDEX_NO_DISPONIBLE',@nHttpRespuesta=400;
 DECLARE @Uot BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300); EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId,@nSesionUsuarioId,@Uot,'INVENTARIO_VER',0,@Uot OUTPUT,@General OUTPUT,@Ok OUTPUT,@Msg OUTPUT;
 IF @Ok=0 BEGIN SET @cMensaje=@Msg; RETURN 1; END;
 ;WITH K AS(
  SELECT M.*,SUM(CONVERT(DECIMAL(19,3),CASE WHEN M.estado=1 THEN CASE WHEN M.tipo_movimiento IN('ENTRADA','DEVOLUCION','AJUSTE_ENTRADA','TRANSFERENCIA_ENTRADA') THEN M.cantidad ELSE -M.cantidad END ELSE 0 END))
   OVER(PARTITION BY M.suministro_id ORDER BY M.fecha_hora,M.suministro_movimiento_id ROWS UNBOUNDED PRECEDING) saldo
  FROM logistica.SuministroMovimiento M
 )
 SELECT K.suministro_movimiento_id suministroMovimientoId,K.suministro_id suministroId,K.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,
        S.codigo,S.nombre,S.unidad_medida unidadMedida,K.recurso_programado_id recursoProgramadoId,K.tipo_movimiento tipoMovimiento,K.cantidad,K.fecha_hora fechaHora,
        K.documento_referencia documentoReferencia,K.observacion,US.nombre_usuario usuario,K.saldo
 FROM K JOIN logistica.Suministro S ON S.suministro_id=K.suministro_id JOIN org.UOT U ON U.uot_id=K.uot_id LEFT JOIN seg.Usuario US ON US.usuario_id=K.usuario_id
 WHERE K.estado=1 AND (@nSuministroId IS NULL OR K.suministro_id=@nSuministroId)
   AND ((@General=0 AND K.uot_id=@Uot) OR (@General=1 AND (@Uot IS NULL OR K.uot_id=@Uot) AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,K.uot_id,'INVENTARIO_VER')=1))
 ORDER BY K.fecha_hora DESC,K.suministro_movimiento_id DESC;
 SELECT @bResultado=1,@cMensaje=N'Kardex consultado.',@cCodigoRespuesta='KARDEX_CONSULTADO',@nHttpRespuesta=200; RETURN 0;
END;
GO
