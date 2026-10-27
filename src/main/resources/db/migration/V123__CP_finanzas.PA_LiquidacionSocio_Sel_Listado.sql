IF OBJECT_ID(N'[finanzas].[PA_LiquidacionSocio_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [finanzas].[PA_LiquidacionSocio_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : finanzas.PA_LiquidacionSocio_Sel_Listado
' Descripción             : Lista liquidación de socio.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Finanzas
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
    EXEC [finanzas].[PA_LiquidacionSocio_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [finanzas].[PA_LiquidacionSocio_Sel_Listado]
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

    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300),@nCamp BIGINT,@nPart BIGINT,@cEstado VARCHAR(20);

    SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar las liquidaciones.';
    EXEC seg.PA_Operacion_Sel_ContextoAutorizado
         @cJson=@cJson,@cCodigoPermiso='LIQUIDACIONES_LISTAR',
         @nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,
         @nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,
         @nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,
         @gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,
         @bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;

    SELECT @nCamp=campaniaVentaId,@nPart=participacionId,
           @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),''))
    FROM OPENJSON(@cJson,'$.filtros')
    WITH(campaniaVentaId BIGINT '$.campaniaVentaId',participacionId BIGINT '$.participacionId',estadoProceso VARCHAR(20) '$.estadoProceso');

    SELECT
        L.liquidacion_socio_id liquidacionSocioId,
        L.participacion_campania_socio_id participacionId,
        P.campania_venta_id campaniaVentaId,
        C.nombre campania,
        L.version,
        L.fecha_calculo fechaCalculo,
        L.importe_bruto importeBruto,
        L.total_ajustes totalAjustes,
        L.total_gastos totalGastos,
        L.total_bonificaciones totalBonificaciones,
        L.importe_neto importeNeto,
        L.moneda,
        L.estado_proceso estadoProceso,
        COALESCE(PG.totalPagado,0) totalPagado,
        CASE WHEN L.importe_neto-COALESCE(PG.totalPagado,0)<0 THEN 0
             ELSE L.importe_neto-COALESCE(PG.totalPagado,0) END saldoPendiente
    , COUNT_BIG(*) OVER() AS totalRegistros FROM finanzas.LiquidacionSocio L
    INNER JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
    INNER JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id
    OUTER APPLY
    (
        SELECT COALESCE(SUM(X.importe),0) totalPagado
        FROM finanzas.PagoSocio X
        WHERE X.liquidacion_socio_id=L.liquidacion_socio_id
          AND X.estado=1
          AND X.estado_proceso='CONFIRMADO'
    ) PG
    WHERE L.estado=1
      AND (@nCamp IS NULL OR P.campania_venta_id=@nCamp)
      AND (@nPart IS NULL OR L.participacion_campania_socio_id=@nPart)
      AND (@cEstado IS NULL OR L.estado_proceso=@cEstado)
    ORDER BY L.fecha_calculo DESC,L.version DESC,L.liquidacion_socio_id DESC OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;

    SET @bResultado=1;
    SET @cMensaje=N'Liquidaciones consultadas correctamente.';

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
    @cProcedimiento = N'finanzas.PA_LiquidacionSocio_Sel_Listado',
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
    @cProcedimiento = N'finanzas.PA_LiquidacionSocio_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'finanzas.PA_LiquidacionSocio_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
