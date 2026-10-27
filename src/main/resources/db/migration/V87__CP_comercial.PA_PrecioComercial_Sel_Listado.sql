IF OBJECT_ID(N'[comercial].[PA_PrecioComercial_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_PrecioComercial_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_PrecioComercial_Sel_Listado
' Descripción             : Lista los precios comerciales.
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
    EXEC [comercial].[PA_PrecioComercial_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_PrecioComercial_Sel_Listado](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;

    BEGIN TRY
  SET NOCOUNT ON;
    DECLARE @nPaginaListado INT, @nTamanoListado INT, @nOffsetListado BIGINT;
    EXEC [seg].[PA_Consulta_Sel_ResolverPaginacion]
         @cJson = @cJson,
         @nPagina = @nPaginaListado OUTPUT,
         @nTamanoPagina = @nTamanoListado OUTPUT,
         @nOffset = @nOffsetListado OUTPUT;
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300);
    SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar los precios.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson=@cJson,@cCodigoPermiso='PRECIOS_LISTAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
 DECLARE @nCamp BIGINT,@nOp BIGINT,@nVar SMALLINT,@nCond BIGINT;
SELECT @nCamp=campaniaVentaId,@nOp=operativoVentaId,@nVar=variedadPaltaId,@nCond=condicionComercialId FROM OPENJSON(@cJson,'$.filtros') WITH(campaniaVentaId BIGINT '$.campaniaVentaId',operativoVentaId BIGINT '$.operativoVentaId',variedadPaltaId SMALLINT '$.variedadPaltaId',condicionComercialId BIGINT '$.condicionComercialId');
SELECT P.precio_comercial_id precioComercialId,P.campania_venta_id campaniaVentaId,C.nombre campania,P.operativo_venta_id operativoVentaId,O.codigo operativo,P.variedad_palta_id variedadPaltaId,V.nombre variedad,P.condicion_comercial_id condicionComercialId,CC.nombre condicion,P.precio,P.moneda,P.unidad_medida unidadMedida,P.fecha_vigencia_desde fechaVigenciaDesde,P.fecha_vigencia_hasta fechaVigenciaHasta,P.version,CASE WHEN P.estado=1 AND P.fecha_vigencia_hasta IS NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END vigente , COUNT_BIG(*) OVER() AS totalRegistros FROM comercial.PrecioComercial P INNER JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id LEFT JOIN comercial.OperativoVenta O ON O.operativo_venta_id=P.operativo_venta_id INNER JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad_palta_id INNER JOIN comercial.CondicionComercial CC ON CC.condicion_comercial_id=P.condicion_comercial_id WHERE P.estado=1 AND (@nCamp IS NULL OR P.campania_venta_id=@nCamp) AND (@nOp IS NULL OR P.operativo_venta_id=@nOp) AND (@nVar IS NULL OR P.variedad_palta_id=@nVar) AND (@nCond IS NULL OR P.condicion_comercial_id=@nCond) ORDER BY P.campania_venta_id DESC,P.variedad_palta_id,P.condicion_comercial_id,P.version DESC,P.precio_comercial_id DESC OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;
SET @bResultado=1;
SET @cMensaje=N'Precios consultados correctamente.';
    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_PrecioComercial_Sel_Listado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_PrecioComercial_Sel_Listado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'comercial.PA_PrecioComercial_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
