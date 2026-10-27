IF OBJECT_ID(N'[campo].[PA_SalidaCampo_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_SalidaCampo_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_SalidaCampo_Sel_Listado
' Descripción             : Consulta salidas de campo según los filtros recibidos.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Campo
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [campo].[PA_SalidaCampo_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_SalidaCampo_Sel_Listado]
(
    @cJson NVARCHAR(MAX), @bResultado BIT OUTPUT, @cMensaje NVARCHAR(300) OUTPUT,
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@cEstado VARCHAR(20),@nMotivo SMALLINT,@dDesde DATETIME2(0),@dHasta DATETIME2(0),@nPagina INT=1,@nTam INT=20;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar las salidas.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'SALIDAS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoProceso)),'')),@nMotivo=motivoSalidaId,@dDesde=fechaDesde,@dHasta=fechaHasta,@nPagina=ISNULL(pagina,1),@nTam=ISNULL(tamanoPagina,20) FROM OPENJSON(@cJson,'$.filtros') WITH (estadoProceso VARCHAR(20) '$.estadoProceso',motivoSalidaId SMALLINT '$.motivoSalidaId',fechaDesde DATETIME2(0) '$.fechaDesde',fechaHasta DATETIME2(0) '$.fechaHasta',pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT S.salida_campo_id,S.motivo_salida_id,M.nombre motivo,S.fecha_hora_programada,S.fecha_hora_salida_real,S.fecha_hora_retorno_real,S.descripcion,S.estado_proceso,S.estado,
             (SELECT COUNT(*) FROM [campo].[SalidaParticipante] P WHERE P.salida_campo_id=S.salida_campo_id AND P.estado=1) participantes,
             (SELECT COUNT(*) FROM [logistica].[RecursoProgramado] R WHERE R.salida_campo_id=S.salida_campo_id AND R.estado=1) recursosProgramados,
             COUNT_BIG(*) OVER() totalRegistros
      FROM [campo].[SalidaCampo] S INNER JOIN [campo].[MotivoSalida] M ON M.motivo_salida_id=S.motivo_salida_id
      WHERE (@cEstado IS NULL OR S.estado_proceso=@cEstado) AND (@nMotivo IS NULL OR S.motivo_salida_id=@nMotivo) AND (@dDesde IS NULL OR S.fecha_hora_programada>=@dDesde) AND (@dHasta IS NULL OR S.fecha_hora_programada<=@dHasta)
    )
    SELECT * FROM Q ORDER BY fecha_hora_programada DESC,salida_campo_id DESC OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Salidas cargadas correctamente.';

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
    @cProcedimiento = N'campo.PA_SalidaCampo_Sel_Listado',
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
    @cProcedimiento = N'campo.PA_SalidaCampo_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_SalidaCampo_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
