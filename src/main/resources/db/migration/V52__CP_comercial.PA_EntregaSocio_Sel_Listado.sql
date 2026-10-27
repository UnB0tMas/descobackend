IF OBJECT_ID(N'[comercial].[PA_EntregaSocio_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_EntregaSocio_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_EntregaSocio_Sel_Listado
' Descripción             : Consulta el listado de entregas de socios.
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
    EXEC [comercial].[PA_EntregaSocio_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_EntregaSocio_Sel_Listado](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar las entregas.';
EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='ENTREGAS_LISTAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
 DECLARE @nOpVenta BIGINT,@nSocio BIGINT,@cEstado VARCHAR(20),@cCalidad VARCHAR(20),@dDesde DATE,@dHasta DATE;
SELECT @nOpVenta=operativoVentaId,@nSocio=socioId,@cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),'')),@cCalidad=UPPER(NULLIF(LTRIM(RTRIM(estadoControlCalidad)),'')),@dDesde=fechaDesde,@dHasta=fechaHasta FROM OPENJSON(@cJson,'$.filtros') WITH(operativoVentaId BIGINT '$.operativoVentaId',socioId BIGINT '$.socioId',estadoProceso VARCHAR(20) '$.estadoProceso',estadoControlCalidad VARCHAR(20) '$.estadoControlCalidad',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta');
SELECT E.entrega_socio_id entregaSocioId,E.codigo_lote codigoLote,E.fecha_hora fechaHora,E.peso_bruto_kg pesoBrutoKg,E.tara_kg taraKg,E.peso_rechazado_kg pesoRechazadoKg,E.peso_aceptado_kg pesoAceptadoKg,E.estado_control_calidad estadoControlCalidad,E.estado_proceso estadoProceso,O.operativo_venta_id operativoVentaId,O.codigo operativo,S.socio_id socioId,PE.numero_documento numeroDocumento,CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre,COALESCE((SELECT SUM(CONVERT(DECIMAL(19,4),D.importe)) FROM comercial.EntregaDetalle D WHERE D.entrega_socio_id=E.entrega_socio_id AND D.estado=1),0) valorizacion , COUNT_BIG(*) OVER() AS totalRegistros FROM comercial.EntregaSocio E INNER JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id INNER JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id INNER JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=OS.participacion_campania_socio_id INNER JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id INNER JOIN org.Socio S ON S.socio_id=SA.socio_id INNER JOIN org.Persona PE ON PE.persona_id=S.socio_id WHERE E.estado=1 AND (@nOpVenta IS NULL OR O.operativo_venta_id=@nOpVenta) AND (@nSocio IS NULL OR S.socio_id=@nSocio) AND (@cEstado IS NULL OR E.estado_proceso=@cEstado) AND (@cCalidad IS NULL OR E.estado_control_calidad=@cCalidad) AND (@dDesde IS NULL OR CONVERT(DATE,E.fecha_hora)>=@dDesde) AND (@dHasta IS NULL OR CONVERT(DATE,E.fecha_hora)<=@dHasta) ORDER BY E.fecha_hora DESC,E.entrega_socio_id DESC OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;
SET @bResultado=1;
SET @cMensaje=N'Entregas consultadas correctamente.';
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
    @cProcedimiento = N'comercial.PA_EntregaSocio_Sel_Listado',
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
    @cProcedimiento = N'comercial.PA_EntregaSocio_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_EntregaSocio_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
