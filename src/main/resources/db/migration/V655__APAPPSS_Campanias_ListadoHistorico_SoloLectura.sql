-- DESCO / APAPPSS: restaurar las lecturas históricas de campañas.
-- V654 está aplicada; esta migración no la reescribe ni modifica datos.
-- El convenio vigente condiciona nuevas operaciones, no la consulta de campañas anteriores.
-- Se conservan la autorización por UOT, filtros, orden, paginación y respuestas.

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
        SELECT C.campania_venta_id campaniaVentaId,C.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,C.asociacion_id asociacionId,EA.razon_social asociacion,C.empresa_compradora_id empresaCompradoraId,COALESCE(EC.razon_social,CASE WHEN B.tipo='PERSONA' THEN NULLIF(LTRIM(RTRIM(CONCAT(PB.nombres,N' ',PB.apellido_paterno,N' ',PB.apellido_materno))),N'') ELSE EB.razon_social END) empresaCompradora,C.codigo,C.nombre,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) THEN 'VENCIDA' ELSE C.estado_proceso END estadoProceso,C.observacion,C.estado,COUNT_BIG(*) OVER() totalRegistros
        FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id
        LEFT JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id
        LEFT JOIN comercial.CompradorAPAPPSS B ON B.comprador_apappss_id=C.comprador_apappss_id AND B.uot_id=C.uot_id
        LEFT JOIN org.Persona PB ON PB.persona_id=B.persona_id
        LEFT JOIN org.Empresa EB ON EB.empresa_id=B.empresa_id
        WHERE C.estado=1 AND (@nUot IS NULL OR C.uot_id=@nUot) AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,C.uot_id,'CAMPANIAS_LISTAR')=1 AND (@cEstado IS NULL OR (CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) THEN 'VENCIDA' ELSE C.estado_proceso END)=@cEstado) AND (@nAsoc IS NULL OR C.asociacion_id=@nAsoc) AND (@nComprador IS NULL OR C.empresa_compradora_id=@nComprador) AND (@dDesde IS NULL OR C.fecha_inicio>=@dDesde) AND (@dHasta IS NULL OR C.fecha_inicio<=@dHasta)
        ORDER BY C.fecha_inicio DESC,C.campania_venta_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;
        SET @bResultado=1; SET @cMensaje=N'Campañas consultadas.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO

-- El detalle requiere permiso CAMPANIAS_VER y respeta la UOT, sin exigir convenio vigente.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Sel_DetalleCompleto]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la campaña.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nId BIGINT=COALESCE(TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.campania.campaniaVentaId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.campaniaVentaId'))),@nUotSolicitada BIGINT=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.campania.uotId'),JSON_VALUE(@cJson,'$.uotId'))),@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
        IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId;
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'CAMPANIAS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'CAMPANIAS_VER',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId AND uot_id=@nUot AND estado=1) BEGIN SET @cMensaje=N'La campaña no está disponible en esta UOT.'; GOTO Salida; END;
        SELECT C.*,U.codigo uotCodigo,U.nombre uotNombre,EA.razon_social asociacion,COALESCE(EC.razon_social,CASE WHEN B.tipo='PERSONA' THEN NULLIF(LTRIM(RTRIM(CONCAT(PB.nombres,N' ',PB.apellido_paterno,N' ',PB.apellido_materno))),N'') ELSE EB.razon_social END) empresaCompradora,CASE WHEN C.estado_proceso='ACTIVA' AND C.fecha_fin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) THEN 'VENCIDA' ELSE C.estado_proceso END estadoProceso FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id
        LEFT JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id
        LEFT JOIN comercial.CompradorAPAPPSS B ON B.comprador_apappss_id=C.comprador_apappss_id AND B.uot_id=C.uot_id
        LEFT JOIN org.Persona PB ON PB.persona_id=B.persona_id
        LEFT JOIN org.Empresa EB ON EB.empresa_id=B.empresa_id WHERE C.campania_venta_id=@nId AND C.uot_id=@nUot;
        SELECT O.* FROM comercial.OperativoVenta O WHERE O.campania_venta_id=@nId ORDER BY O.operativo_venta_id;
        SET @bResultado=1; SET @cMensaje=N'Campaña consultada.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la campaña.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO
