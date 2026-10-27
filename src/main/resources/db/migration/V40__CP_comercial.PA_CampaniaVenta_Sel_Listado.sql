IF OBJECT_ID(N'[comercial].[PA_CampaniaVenta_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaVenta_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_CampaniaVenta_Sel_Listado
' Descripción             : Lista las campañas de venta según los filtros recibidos.
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
    EXEC [comercial].[PA_CampaniaVenta_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_CampaniaVenta_Sel_Listado]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nPagina INT,@nTamano INT,@nOffset BIGINT; EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@nPagina OUTPUT,@nTamano OUTPUT,@nOffset OUTPUT;
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@cEstado VARCHAR(20),@nAsoc BIGINT,@nComprador BIGINT,@dDesde DATE,@dHasta DATE;
        SELECT @nUotSolicitada=uotId,@cEstado=estadoProceso,@nAsoc=asociacionId,@nComprador=empresaCompradoraId,@dDesde=fechaDesde,@dHasta=fechaHasta FROM OPENJSON(@cJson,'$.filtros') WITH(uotId BIGINT '$.uotId',estadoProceso VARCHAR(20) '$.estadoProceso',asociacionId BIGINT '$.asociacionId',empresaCompradoraId BIGINT '$.empresaCompradoraId',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta');
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'CAMPANIAS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'CAMPANIAS_LISTAR',0,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        SELECT C.campania_venta_id campaniaVentaId,C.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,C.asociacion_id asociacionId,EA.razon_social asociacion,C.empresa_compradora_id empresaCompradoraId,EC.razon_social empresaCompradora,C.codigo,C.nombre,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,C.estado_proceso estadoProceso,C.observacion,C.estado,COUNT_BIG(*) OVER() totalRegistros
        FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id
        WHERE C.estado=1 AND (@nUot IS NULL OR C.uot_id=@nUot) AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,C.uot_id,'CAMPANIAS_LISTAR')=1 AND (@cEstado IS NULL OR C.estado_proceso=@cEstado) AND (@nAsoc IS NULL OR C.asociacion_id=@nAsoc) AND (@nComprador IS NULL OR C.empresa_compradora_id=@nComprador) AND (@dDesde IS NULL OR C.fecha_inicio>=@dDesde) AND (@dHasta IS NULL OR C.fecha_inicio<=@dHasta)
        ORDER BY C.fecha_inicio DESC,C.campania_venta_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;
        SET @bResultado=1; SET @cMensaje=N'Campañas consultadas.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
