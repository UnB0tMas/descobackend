IF OBJECT_ID(N'[comercial].[PA_Jabas_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Jabas_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Jabas_Sel_Listado
' Descripción             : Lista los movimientos o registros de jabas.
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
    EXEC [comercial].[PA_Jabas_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Jabas_Sel_Listado]
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
 SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la información.';
 BEGIN TRY
  DECLARE @vUsuario BIGINT,@vSesion BIGINT,@vDisp BIGINT,@vEmp BIGINT,@vModulo INT,
        @vCorr UNIQUEIDENTIFIER,@vSol UNIQUEIDENTIFIER,@vIp VARCHAR(64),@vEnd NVARCHAR(250),@vOk BIT,@vMsg NVARCHAR(300);
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso=N'JABAS_LISTAR',
        @nUsuarioId=@vUsuario OUTPUT,@nSesionUsuarioId=@vSesion OUTPUT,@nDispositivoUsuarioId=@vDisp OUTPUT,
        @nEmpleadoId=@vEmp OUTPUT,@nModuloId=@vModulo OUTPUT,@gCorrelacionId=@vCorr OUTPUT,
        @gSolicitudId=@vSol OUTPUT,@cIp=@vIp OUTPUT,@cEndpoint=@vEnd OUTPUT,@bResultado=@vOk OUTPUT,@cMensaje=@vMsg OUTPUT;
        IF ISNULL(@vOk,0)=0 BEGIN SET @cMensaje=@vMsg; GOTO Salida; END;
  
 DECLARE @pagina INT,@tamano INT,@offset BIGINT,
 @op BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.operativoVentaId'));
 EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@pagina OUTPUT,@tamano OUTPUT,@offset OUTPUT;
 SELECT O.operativo_venta_id operativoVentaId,O.codigo,O.estado_proceso estadoProceso,
 CONVERT(INT,S.recibidas) cantidadJabasRecibidas,CONVERT(INT,S.asignadas) jabasAsignadas,
 CONVERT(INT,S.devueltas_llenas) jabasDevueltasLlenas,CONVERT(INT,S.devueltas_vacias) jabasDevueltasVacias,
 CONVERT(INT,S.devueltas_llenas+S.devueltas_vacias) jabasDevueltas,
 CONVERT(INT,S.disponibles) jabasDisponibles,CONVERT(INT,S.pendientes) jabasPendientes,COUNT_BIG(*) OVER() totalRegistros
 FROM comercial.OperativoVenta O JOIN comercial.JabaSaldoOperativo S ON S.operativo_venta_id=O.operativo_venta_id
 WHERE O.estado=1 AND (@op IS NULL OR O.operativo_venta_id=@op)
 ORDER BY O.fecha_inicio_programada DESC,O.operativo_venta_id DESC OFFSET @offset ROWS FETCH NEXT @tamano ROWS ONLY;

  SELECT @bResultado=1,@cMensaje=N'Control de jabas consultado.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'comercial.PA_Jabas_Sel_Listado',@cMensaje=@cMensaje OUTPUT,@cJson=@cJson;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'comercial.PA_Jabas_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
