IF OBJECT_ID(N'[sanidad].[PA_CasoFitosanitario_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [sanidad].[PA_CasoFitosanitario_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : sanidad.PA_CasoFitosanitario_Sel_Listado
' Descripción             : Lista casos fitosanitarios.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Sanidad
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
    EXEC [sanidad].[PA_CasoFitosanitario_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [sanidad].[PA_CasoFitosanitario_Sel_Listado]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,
            @cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@cEstado VARCHAR(20),@cSeveridad VARCHAR(10),
            @nPredio BIGINT,@nSocio BIGINT,@nTipo SMALLINT,@dDesde DATE,@dHasta DATE,@nPagina INT=1,@nTam INT=25,@nOffset INT;
    SELECT @bResultado=0,@cMensaje=N'No se pudo consultar la sanidad vegetal.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson=@cJson,@cCodigoPermiso='SANIDAD_LISTAR',@nUsuarioId=@nUsuario OUTPUT,
        @nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,
        @gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@bResultado=@bCtx OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoCaso)),'')),@cSeveridad=UPPER(NULLIF(LTRIM(RTRIM(severidad)),'')),@nPredio=predioId,
           @nSocio=socioId,@nTipo=tipoProblemaId,@dDesde=fechaDesde,@dHasta=fechaHasta
    FROM OPENJSON(@cJson,'$.filtros') WITH(estadoCaso VARCHAR(20) '$.estadoCaso',severidad VARCHAR(10) '$.severidad',predioId BIGINT '$.predioId',socioId BIGINT '$.socioId',tipoProblemaId SMALLINT '$.tipoProblemaId',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta');
    SELECT @nPagina=COALESCE(pagina,1),@nTam=COALESCE(tamano,25) FROM OPENJSON(@cJson,'$.paginacion') WITH(pagina INT '$.pagina',tamano INT '$.tamano');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=25;
 IF @nTam>200 SET @nTam=200;
 SET @nOffset=(@nPagina-1)*@nTam;
    SELECT CF.caso_fitosanitario_id casoFitosanitarioId,CF.fecha_deteccion fechaDeteccion,CF.estado_caso estadoCaso,CF.severidad,
           CF.plantas_afectadas plantasAfectadas,CF.cantidad_estimada cantidadEstimada,TP.codigo codigoProblema,TP.nombre problema,
           PC.parcela_cultivo_id parcelaCultivoId,P.parcela_id parcelaId,P.nombre parcelaNombre,PR.predio_id predioId,PR.codigo predioCodigo,PR.nombre predioNombre,
           S.socio_id socioId,PER.numero_documento numeroDocumento,CONCAT(PER.nombres,N' ',PER.apellido_paterno,N' ',COALESCE(PER.apellido_materno,N'')) socioNombre,
           (SELECT COUNT_BIG(*) FROM [archivo].[ArchivoVinculo] AV INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id AND A.estado=1 WHERE AV.caso_fitosanitario_id=CF.caso_fitosanitario_id AND AV.estado=1) evidencias,
           COUNT_BIG(*) OVER() totalRegistros
    FROM [sanidad].[CasoFitosanitario] CF
    INNER JOIN [sanidad].[TipoProblemaFitosanitario] TP ON TP.tipo_problema_fitosanitario_id=CF.tipo_problema_fitosanitario_id
    INNER JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_cultivo_id=CF.parcela_cultivo_id
    INNER JOIN [prod].[Parcela] P ON P.parcela_id=PC.parcela_id
    INNER JOIN [prod].[Predio] PR ON PR.predio_id=P.predio_id
    OUTER APPLY(SELECT TOP(1) PT.socio_id FROM [prod].[PredioTitularidad] PT WHERE PT.predio_id=PR.predio_id AND PT.estado=1 AND PT.fecha_hasta IS NULL ORDER BY PT.fecha_desde DESC) T
    LEFT JOIN [org].[Socio] S ON S.socio_id=T.socio_id LEFT JOIN [org].[Persona] PER ON PER.persona_id=S.socio_id
    WHERE CF.estado=1 AND (@cEstado IS NULL OR CF.estado_caso=@cEstado) AND (@cSeveridad IS NULL OR CF.severidad=@cSeveridad)
      AND (@nPredio IS NULL OR PR.predio_id=@nPredio) AND (@nSocio IS NULL OR S.socio_id=@nSocio)
      AND (@nTipo IS NULL OR CF.tipo_problema_fitosanitario_id=@nTipo)
      AND (@dDesde IS NULL OR CONVERT(DATE,CF.fecha_deteccion)>=@dDesde) AND (@dHasta IS NULL OR CONVERT(DATE,CF.fecha_deteccion)<=@dHasta)
    ORDER BY CF.fecha_deteccion DESC,CF.caso_fitosanitario_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Casos sanitarios cargados correctamente.';

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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Sel_Listado',
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
    @cProcedimiento = N'sanidad.PA_CasoFitosanitario_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'sanidad.PA_CasoFitosanitario_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
