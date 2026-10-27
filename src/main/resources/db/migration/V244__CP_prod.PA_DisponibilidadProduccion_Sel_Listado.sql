IF OBJECT_ID(N'[prod].[PA_DisponibilidadProduccion_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_DisponibilidadProduccion_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_DisponibilidadProduccion_Sel_Listado
' Descripción             : Lista disponibilidades de producción.
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
    EXEC [prod].[PA_DisponibilidadProduccion_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_DisponibilidadProduccion_Sel_Listado]
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

    DECLARE
        @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
        @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
        @bCtx BIT,@cMsg NVARCHAR(300),@cEstado VARCHAR(20),@nZona BIGINT,@nPredio BIGINT,
        @nSocio BIGINT,@nAsociacion BIGINT,@nVariedad SMALLINT,@cOrigen VARCHAR(20),
        @dDesde DATE,@dHasta DATE,@nPagina INT=1,@nTam INT=25,@nOffset INT;

    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudo consultar la producción disponible.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'PRODUCCION_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;

    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @cEstado=UPPER(NULLIF(LTRIM(RTRIM(estadoEstimacion)),'')),
        @nZona=zonaProductivaId,
        @nPredio=predioId,
        @nSocio=socioId,
        @nAsociacion=asociacionId,
        @nVariedad=variedadPaltaId,
        @cOrigen=UPPER(NULLIF(LTRIM(RTRIM(origen)),'')),
        @dDesde=disponibleDesde,
        @dHasta=disponibleHasta
    FROM OPENJSON(@cJson,'$.filtros')
    WITH
    (
        estadoEstimacion VARCHAR(20) '$.estadoEstimacion',
        zonaProductivaId BIGINT '$.zonaProductivaId',
        predioId BIGINT '$.predioId',
        socioId BIGINT '$.socioId',
        asociacionId BIGINT '$.asociacionId',
        variedadPaltaId SMALLINT '$.variedadPaltaId',
        origen VARCHAR(20) '$.origen',
        disponibleDesde DATE '$.disponibleDesde',
        disponibleHasta DATE '$.disponibleHasta'
    );

    IF @cEstado IS NOT NULL AND @cEstado NOT IN('ESTIMADA','CONFIRMADA','DESCARTADA')
    BEGIN
        SET @cMensaje=N'Seleccione un estado de producción válido.';
        GOTO __DESCO_Salida;
    END;

    IF @cOrigen IS NOT NULL AND @cOrigen NOT IN('DIRECTA','VISITA')
    BEGIN
        SET @cMensaje=N'Seleccione un origen de estimación válido.';
        GOTO __DESCO_Salida;
    END;

    IF @dDesde IS NOT NULL AND @dHasta IS NOT NULL AND @dHasta<@dDesde
    BEGIN
        SET @cMensaje=N'El rango de fechas seleccionado no es válido.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nPagina=COALESCE(pagina,1),
        @nTam=COALESCE(tamano,25)
    FROM OPENJSON(@cJson,'$.paginacion')
    WITH
    (
        pagina INT '$.pagina',
        tamano INT '$.tamano'
    );

    IF @nPagina<1 SET @nPagina=1;
    IF @nTam<1 SET @nTam=25;
    IF @nTam>200 SET @nTam=200;
    SET @nOffset=(@nPagina-1)*@nTam;

    SELECT
        DP.disponibilidad_produccion_id disponibilidadProduccionId,
        DP.fecha_estimacion fechaEstimacion,
        DP.disponible_desde disponibleDesde,
        DP.disponible_hasta disponibleHasta,
        DP.cantidad_estimada_kg cantidadEstimadaKg,
        DP.estado_estimacion estadoEstimacion,
        DP.observacion,
        PC.parcela_cultivo_id parcelaCultivoId,
        VP.variedad_palta_id variedadPaltaId,
        VP.nombre variedad,
        P.parcela_id parcelaId,
        P.nombre parcelaNombre,
        PR.predio_id predioId,
        PR.codigo predioCodigo,
        PR.nombre predioNombre,
        ZP.zona_productiva_id zonaProductivaId,
        ZP.nombre zonaProductiva,
        TIT.socio_id socioId,
        LTRIM(RTRIM(CONCAT(COALESCE(PER.nombres,N''),N' ',COALESCE(PER.apellido_paterno,N''),N' ',COALESCE(PER.apellido_materno,N'')))) socioNombre,
        SA.asociacion_id asociacionId,
        EMP.razon_social asociacionNombre,
        DP.visita_tecnica_id visitaTecnicaId,
        CASE WHEN DP.visita_tecnica_id IS NULL THEN N'Estimación directa' ELSE N'Visita técnica' END origenEstimacion,
        COUNT_BIG(*) OVER() totalRegistros
    FROM [prod].[DisponibilidadProduccion] DP
    INNER JOIN [prod].[ParcelaCultivo] PC
        ON PC.parcela_cultivo_id=DP.parcela_cultivo_id
    INNER JOIN [prod].[VariedadPalta] VP
        ON VP.variedad_palta_id=PC.variedad_palta_id
    INNER JOIN [prod].[Parcela] P
        ON P.parcela_id=PC.parcela_id
    INNER JOIN [prod].[Predio] PR
        ON PR.predio_id=P.predio_id
    OUTER APPLY
    (
        SELECT TOP(1) X.zona_productiva_id
        FROM [geo].[ZonaProductivaPredio] X
        WHERE X.predio_id=PR.predio_id
          AND X.estado=1
          AND X.fecha_hasta IS NULL
        ORDER BY X.fecha_desde DESC
    ) ZPX
    LEFT JOIN [geo].[ZonaProductiva] ZP
        ON ZP.zona_productiva_id=ZPX.zona_productiva_id
    OUTER APPLY
    (
        SELECT TOP(1) PT.socio_id
        FROM [prod].[PredioTitularidad] PT
        WHERE PT.predio_id=PR.predio_id
          AND PT.estado=1
          AND PT.fecha_hasta IS NULL
        ORDER BY PT.fecha_desde DESC,PT.predio_titularidad_id DESC
    ) TIT
    LEFT JOIN [org].[Socio] S
        ON S.socio_id=TIT.socio_id
       AND S.estado=1
    LEFT JOIN [org].[Persona] PER
        ON PER.persona_id=S.socio_id
    OUTER APPLY
    (
        SELECT TOP(1) X.asociacion_id
        FROM [org].[SocioAsociacion] X
        WHERE X.socio_id=TIT.socio_id
          AND X.estado=1
          AND X.fecha_hasta IS NULL
        ORDER BY X.fecha_desde DESC,X.socio_asociacion_id DESC
    ) SA
    LEFT JOIN [org].[Empresa] EMP
        ON EMP.empresa_id=SA.asociacion_id
       AND EMP.estado=1
    WHERE DP.estado=1
      AND (@cEstado IS NULL OR DP.estado_estimacion=@cEstado)
      AND (@nZona IS NULL OR ZP.zona_productiva_id=@nZona)
      AND (@nPredio IS NULL OR PR.predio_id=@nPredio)
      AND (@nVariedad IS NULL OR VP.variedad_palta_id=@nVariedad)
      AND (@cOrigen IS NULL OR (@cOrigen='DIRECTA' AND DP.visita_tecnica_id IS NULL) OR (@cOrigen='VISITA' AND DP.visita_tecnica_id IS NOT NULL))
      AND
      (
          @nSocio IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM [prod].[PredioTitularidad] PTX
              WHERE PTX.predio_id=PR.predio_id
                AND PTX.socio_id=@nSocio
                AND PTX.estado=1
                AND PTX.fecha_hasta IS NULL
          )
      )
      AND
      (
          @nAsociacion IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM [prod].[PredioTitularidad] PTX
              INNER JOIN [org].[SocioAsociacion] SAX
                  ON SAX.socio_id=PTX.socio_id
                 AND SAX.estado=1
                 AND SAX.fecha_hasta IS NULL
              WHERE PTX.predio_id=PR.predio_id
                AND PTX.estado=1
                AND PTX.fecha_hasta IS NULL
                AND SAX.asociacion_id=@nAsociacion
          )
      )
      AND (@dDesde IS NULL OR COALESCE(DP.disponible_hasta,DP.disponible_desde)>=@dDesde)
      AND (@dHasta IS NULL OR DP.disponible_desde<=@dHasta)
    ORDER BY DP.disponible_desde,PR.nombre,DP.disponibilidad_produccion_id
    OFFSET @nOffset ROWS FETCH NEXT @nTam ROWS ONLY;

    SET @bResultado=1;
    SET @cMensaje=N'Producción disponible cargada correctamente.';

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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Sel_Listado',
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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_DisponibilidadProduccion_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
