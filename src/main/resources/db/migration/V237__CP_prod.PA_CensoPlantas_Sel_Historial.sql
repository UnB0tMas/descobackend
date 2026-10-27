IF OBJECT_ID(N'[prod].[PA_CensoPlantas_Sel_Historial]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_CensoPlantas_Sel_Historial];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_CensoPlantas_Sel_Historial
' Descripción             : Consulta el historial de censos de plantas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Producción
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
    EXEC [prod].[PA_CensoPlantas_Sel_Historial]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_CensoPlantas_Sel_Historial]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nCultivo BIGINT,@nParcela BIGINT,@dDesde DATE,@dHasta DATE,@nPagina INT=1,@nTam INT=30;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar los censos.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'CENSOS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nCultivo=parcelaCultivoId,@nParcela=parcelaId,@dDesde=fechaDesde,@dHasta=fechaHasta,@nPagina=ISNULL(pagina,1),@nTam=ISNULL(tamanoPagina,30) FROM OPENJSON(@cJson,'$.filtros') WITH (parcelaCultivoId BIGINT '$.parcelaCultivoId',parcelaId BIGINT '$.parcelaId',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta',pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=30;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT C.censo_plantas_id,C.parcela_cultivo_id,PC.parcela_id,PA.codigo parcelaCodigo,PA.nombre parcelaNombre,VP.nombre variedad,C.fecha_censo,C.plantas_totales,C.plantas_productivas,C.plantas_no_productivas,C.plantas_nuevas,C.plantas_muertas,C.plantas_afectadas,C.observacion,C.estado,COUNT_BIG(*) OVER() totalRegistros
      FROM [prod].[CensoPlantas] C INNER JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_cultivo_id=C.parcela_cultivo_id INNER JOIN [prod].[Parcela] PA ON PA.parcela_id=PC.parcela_id INNER JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id
      WHERE (@nCultivo IS NULL OR C.parcela_cultivo_id=@nCultivo) AND (@nParcela IS NULL OR PC.parcela_id=@nParcela) AND (@dDesde IS NULL OR C.fecha_censo>=@dDesde) AND (@dHasta IS NULL OR C.fecha_censo<=@dHasta)
    )
    SELECT * FROM Q ORDER BY fecha_censo DESC,censo_plantas_id DESC OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Censos cargados correctamente.';

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
    @cProcedimiento = N'prod.PA_CensoPlantas_Sel_Historial',
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
    @cProcedimiento = N'prod.PA_CensoPlantas_Sel_Historial',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_CensoPlantas_Sel_Historial',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
