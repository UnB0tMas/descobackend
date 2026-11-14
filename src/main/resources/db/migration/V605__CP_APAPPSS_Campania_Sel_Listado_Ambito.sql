-- Restricción por asociación APAPPSS en listado sin alterar columnas o paginación.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Sel_Listado]
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
        -- Sólo APAPPSS con convenio UOT real, activo y módulo especial explícito.
        IF @nUot IS NULL OR NOT EXISTS (
          SELECT 1 FROM org.ConvenioUOTOrganizacion CU
          JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
          JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1
          JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
          JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
          JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
          WHERE CU.uot_id=@nUot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
            AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
            AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
        BEGIN SET @cMensaje=N'No existe convenio APAPPSS vigente para la UOT seleccionada.'; GOTO Salida; END;
        SELECT C.campania_venta_id campaniaVentaId,C.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,C.asociacion_id asociacionId,EA.razon_social asociacion,C.empresa_compradora_id empresaCompradoraId,EC.razon_social empresaCompradora,C.codigo,C.nombre,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,C.estado_proceso estadoProceso,C.observacion,C.estado,COUNT_BIG(*) OVER() totalRegistros
        FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id
        WHERE C.estado=1 AND C.uot_id=@nUot AND EA.ruc='20602771394' AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,C.uot_id,'CAMPANIAS_LISTAR')=1 AND (@cEstado IS NULL OR C.estado_proceso=@cEstado) AND (@nAsoc IS NULL OR C.asociacion_id=@nAsoc) AND (@nComprador IS NULL OR C.empresa_compradora_id=@nComprador) AND (@dDesde IS NULL OR C.fecha_inicio>=@dDesde) AND (@dHasta IS NULL OR C.fecha_inicio<=@dHasta)
        ORDER BY C.fecha_inicio DESC,C.campania_venta_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;
        SET @bResultado=1; SET @cMensaje=N'Campañas consultadas.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
