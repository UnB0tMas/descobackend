IF OBJECT_ID(N'[prod].[PA_ParcelaCultivo_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_ParcelaCultivo_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_ParcelaCultivo_Sel_Listado
' Descripción             : Lista parcelas de cultivo.
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
    EXEC [prod].[PA_ParcelaCultivo_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_ParcelaCultivo_Sel_Listado]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),
            @nPredio BIGINT,@nSocio BIGINT,@nVariedad SMALLINT,@cSituacion VARCHAR(20),@cBuscar NVARCHAR(150),@nPagina INT=1,@nTam INT=20;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar la información.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'CULTIVOS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPredio=predioId,@nSocio=socioId,@nVariedad=variedadPaltaId,@cSituacion=UPPER(NULLIF(LTRIM(RTRIM(situacionCultivo)),'')),@cBuscar=NULLIF(LTRIM(RTRIM(buscar)),N''),@nPagina=ISNULL(pagina,1),@nTam=ISNULL(tamanoPagina,20)
    FROM OPENJSON(@cJson,'$.filtros') WITH (predioId BIGINT '$.predioId',socioId BIGINT '$.socioId',variedadPaltaId SMALLINT '$.variedadPaltaId',situacionCultivo VARCHAR(20) '$.situacionCultivo',buscar NVARCHAR(150) '$.buscar',pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT PA.parcela_id,PA.predio_id,PR.codigo predioCodigo,PR.nombre predioNombre,PA.codigo parcelaCodigo,PA.nombre parcelaNombre,PA.area_ha,PA.ubicacion_id,PA.estado parcelaEstado,
             PC.parcela_cultivo_id,PC.variedad_palta_id,VP.nombre variedad,PC.fecha_inicio,PC.fecha_fin,PC.situacion_cultivo,PC.estado cultivoEstado,
             COUNT_BIG(*) OVER() totalRegistros
      FROM [prod].[Parcela] PA INNER JOIN [prod].[Predio] PR ON PR.predio_id=PA.predio_id
      LEFT JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_id=PA.parcela_id AND PC.estado=1
      LEFT JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id
      WHERE PA.estado=1 AND PR.estado=1
        AND (@nPredio IS NULL OR PA.predio_id=@nPredio)
        AND (@nVariedad IS NULL OR PC.variedad_palta_id=@nVariedad)
        AND (@cSituacion IS NULL OR PC.situacion_cultivo=@cSituacion)
        AND (@nSocio IS NULL OR EXISTS(SELECT 1 FROM [prod].[PredioTitularidad] PT WHERE PT.predio_id=PR.predio_id AND PT.socio_id=@nSocio AND PT.estado=1 AND PT.fecha_hasta IS NULL))
        AND (@cBuscar IS NULL OR PA.codigo LIKE '%'+@cBuscar+'%' OR PA.nombre LIKE N'%'+@cBuscar+N'%' OR PR.codigo LIKE '%'+@cBuscar+'%' OR PR.nombre LIKE N'%'+@cBuscar+N'%')
    )
    SELECT * FROM Q ORDER BY predioNombre,parcelaNombre,fecha_inicio DESC OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Información cargada correctamente.';

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
    @cProcedimiento = N'prod.PA_ParcelaCultivo_Sel_Listado',
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
    @cProcedimiento = N'prod.PA_ParcelaCultivo_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_ParcelaCultivo_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
