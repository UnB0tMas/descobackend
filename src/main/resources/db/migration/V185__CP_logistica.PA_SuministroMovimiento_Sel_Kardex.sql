IF OBJECT_ID(N'[logistica].[PA_SuministroMovimiento_Sel_Kardex]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_SuministroMovimiento_Sel_Kardex];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_SuministroMovimiento_Sel_Kardex
' Descripción             : Consulta el kardex de movimiento de suministro.
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
    EXEC [logistica].[PA_SuministroMovimiento_Sel_Kardex]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_SuministroMovimiento_Sel_Kardex](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

 SET NOCOUNT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la información.';
 BEGIN TRY
  DECLARE @vUsuario BIGINT,@vSesion BIGINT,@vDisp BIGINT,@vEmp BIGINT,@vModulo INT,
        @vCorr UNIQUEIDENTIFIER,@vSol UNIQUEIDENTIFIER,@vIp VARCHAR(64),@vEnd NVARCHAR(250),@vOk BIT,@vMsg NVARCHAR(300);
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso=N'INVENTARIO_VER',
        @nUsuarioId=@vUsuario OUTPUT,@nSesionUsuarioId=@vSesion OUTPUT,@nDispositivoUsuarioId=@vDisp OUTPUT,
        @nEmpleadoId=@vEmp OUTPUT,@nModuloId=@vModulo OUTPUT,@gCorrelacionId=@vCorr OUTPUT,
        @gSolicitudId=@vSol OUTPUT,@cIp=@vIp OUTPUT,@cEndpoint=@vEnd OUTPUT,@bResultado=@vOk OUTPUT,@cMensaje=@vMsg OUTPUT;
        IF ISNULL(@vOk,0)=0 BEGIN SET @cMensaje=@vMsg; GOTO Salida; END;
  
  DECLARE @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.suministroId')),
   @desde DATETIME2(0)=TRY_CONVERT(DATETIME2(0),JSON_VALUE(@cJson,'$.filtros.fechaDesde')),
   @hasta DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.filtros.fechaHasta'));
  ;WITH K AS(
   SELECT M.*,SUM(CONVERT(DECIMAL(19,3),CASE WHEN M.tipo_movimiento IN('ENTRADA','DEVOLUCION','AJUSTE_ENTRADA') THEN M.cantidad ELSE -M.cantidad END))
    OVER(PARTITION BY M.suministro_id ORDER BY M.fecha_hora,M.suministro_movimiento_id ROWS UNBOUNDED PRECEDING) saldo,
    CASE WHEN M.tipo_movimiento IN('ENTRADA','DEVOLUCION','AJUSTE_ENTRADA') THEN M.cantidad ELSE CONVERT(DECIMAL(14,3),0) END entrada,
    CASE WHEN M.tipo_movimiento IN('SALIDA','AJUSTE_SALIDA') THEN M.cantidad ELSE CONVERT(DECIMAL(14,3),0) END salida
   FROM logistica.SuministroMovimiento M WHERE M.estado=1 AND (@id IS NULL OR M.suministro_id=@id))
  SELECT K.suministro_movimiento_id suministroMovimientoId,K.suministro_id suministroId,S.codigo,S.nombre,S.unidad_medida unidadMedida,
   K.recurso_programado_id recursoProgramadoId,K.tipo_movimiento tipoMovimiento,K.cantidad,K.fecha_hora fechaHora,
   K.documento_referencia documentoReferencia,K.observacion,U.nombre_usuario usuario,
   K.entrada,K.salida,K.saldo-K.entrada+K.salida saldoAnterior,K.saldo saldoAcumulado,
   K.movimiento_origen_id movimientoOrigenId,K.recurso_movimiento_id recursoMovimientoId,
   COUNT_BIG(*) OVER() totalRegistros
  FROM K JOIN logistica.Suministro S ON S.suministro_id=K.suministro_id
  LEFT JOIN seg.Usuario U ON U.usuario_id=K.usuario_id
  WHERE (@desde IS NULL OR K.fecha_hora>=@desde) AND (@hasta IS NULL OR K.fecha_hora<DATEADD(DAY,1,CONVERT(DATETIME2,@hasta)))
  ORDER BY K.fecha_hora DESC,K.suministro_movimiento_id DESC;

  SELECT @bResultado=1,@cMensaje=N'Kardex consultado.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'logistica.PA_SuministroMovimiento_Sel_Kardex',@cMensaje=@cMensaje OUTPUT,@cJson=@cJson;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'logistica.PA_SuministroMovimiento_Sel_Kardex',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
