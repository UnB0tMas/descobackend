IF OBJECT_ID(N'[comercial].[PA_IncidenciaOperativa_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_IncidenciaOperativa_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_IncidenciaOperativa_Sel_Listado
' Descripción             : Lista las incidencias operativas.
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
    EXEC [comercial].[PA_IncidenciaOperativa_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_IncidenciaOperativa_Sel_Listado](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
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
SELECT @bResultado=0,@cMensaje=N'No se pudieron consultar las incidencias.';
EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='INCIDENCIAS_LISTAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
 DECLARE @nOpVenta BIGINT,@nEntrega BIGINT,@cEstado VARCHAR(20),@cTipo VARCHAR(25),@cSev VARCHAR(10);
SELECT @nOpVenta=operativoVentaId,@nEntrega=entregaSocioId,@cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoIncidencia)),'')),@cTipo=UPPER(NULLIF(LTRIM(RTRIM(tipoIncidencia)),'')),@cSev=UPPER(NULLIF(LTRIM(RTRIM(severidad)),'')) FROM OPENJSON(@cJson,'$.filtros') WITH(operativoVentaId BIGINT '$.operativoVentaId',entregaSocioId BIGINT '$.entregaSocioId',estadoIncidencia VARCHAR(20) '$.estadoIncidencia',tipoIncidencia VARCHAR(25) '$.tipoIncidencia',severidad VARCHAR(10) '$.severidad');
SELECT I.incidencia_operativa_id incidenciaId,I.operativo_venta_id operativoVentaId,O.codigo operativo,I.entrega_socio_id entregaSocioId,E.codigo_lote codigoLote,I.tipo_incidencia tipoIncidencia,I.fecha_hora fechaHora,I.peso_afectado_kg pesoAfectadoKg,I.severidad,I.descripcion,I.estado_incidencia estadoIncidencia , COUNT_BIG(*) OVER() AS totalRegistros FROM comercial.IncidenciaOperativa I INNER JOIN comercial.OperativoVenta O ON O.operativo_venta_id=I.operativo_venta_id LEFT JOIN comercial.EntregaSocio E ON E.entrega_socio_id=I.entrega_socio_id WHERE I.estado=1 AND (@nOpVenta IS NULL OR I.operativo_venta_id=@nOpVenta) AND (@nEntrega IS NULL OR I.entrega_socio_id=@nEntrega) AND (@cEstado IS NULL OR I.estado_incidencia=@cEstado) AND (@cTipo IS NULL OR I.tipo_incidencia=@cTipo) AND (@cSev IS NULL OR I.severidad=@cSev) ORDER BY I.fecha_hora DESC,I.incidencia_operativa_id DESC OFFSET @nOffsetListado ROWS FETCH NEXT @nTamanoListado ROWS ONLY;
SET @bResultado=1;
SET @cMensaje=N'Incidencias consultadas correctamente.';
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
    @cProcedimiento = N'comercial.PA_IncidenciaOperativa_Sel_Listado',
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
    @cProcedimiento = N'comercial.PA_IncidenciaOperativa_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'comercial.PA_IncidenciaOperativa_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
