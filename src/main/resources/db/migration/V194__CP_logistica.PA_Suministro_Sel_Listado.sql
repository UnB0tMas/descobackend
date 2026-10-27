IF OBJECT_ID(N'[logistica].[PA_Suministro_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Suministro_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Suministro_Sel_Listado
' Descripción             : Lista suministro.
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
    EXEC [logistica].[PA_Suministro_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [logistica].[PA_Suministro_Sel_Listado](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso=N'INVENTARIO_LISTAR',
        @nUsuarioId=@vUsuario OUTPUT,@nSesionUsuarioId=@vSesion OUTPUT,@nDispositivoUsuarioId=@vDisp OUTPUT,
        @nEmpleadoId=@vEmp OUTPUT,@nModuloId=@vModulo OUTPUT,@gCorrelacionId=@vCorr OUTPUT,
        @gSolicitudId=@vSol OUTPUT,@cIp=@vIp OUTPUT,@cEndpoint=@vEnd OUTPUT,@bResultado=@vOk OUTPUT,@cMensaje=@vMsg OUTPUT;
        IF ISNULL(@vOk,0)=0 BEGIN SET @cMensaje=@vMsg; GOTO Salida; END;
  
  DECLARE @pagina INT,@tamano INT,@offset BIGINT;
  EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@pagina OUTPUT,@tamano OUTPUT,@offset OUTPUT;
  SELECT suministro_id suministroId,codigo,nombre,unidad_medida unidadMedida,estado,
   stock_actual stock,COUNT_BIG(*) OVER() totalRegistros,
   stock_actual stockActual,stock_reservado stockReservado,stock_disponible stockDisponible,
   stock_minimo stockMinimo,requiere_reposicion requiereReposicion
  FROM logistica.VW_SuministroExistencia WHERE estado=1 ORDER BY nombre,suministro_id
  OFFSET @offset ROWS FETCH NEXT @tamano ROWS ONLY;

  SELECT @bResultado=1,@cMensaje=N'Suministros consultados.';
 END TRY
 BEGIN CATCH
  SET @bResultado=0;
  EXEC config.PA_Respuesta_ResolverError @cProcedimiento=N'logistica.PA_Suministro_Sel_Listado',@cMensaje=@cMensaje OUTPUT,@cJson=@cJson;
 END CATCH;
Salida:
 SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'logistica.PA_Suministro_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
