IF OBJECT_ID(N'[campo].[PA_EvaluacionAgronomica_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_EvaluacionAgronomica_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_EvaluacionAgronomica_Sel_Listado
' Descripción             : Consulta evaluaciones agronómicas según los filtros recibidos.
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
    EXEC [campo].[PA_EvaluacionAgronomica_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_EvaluacionAgronomica_Sel_Listado]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,
            @gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),
            @bCtx BIT,@cMsg NVARCHAR(300),@nPagina INT=1,@nTam INT=20,@nVisita BIGINT=NULL,@nCultivo BIGINT=NULL,
            @nTipo SMALLINT=NULL,@dDesde DATETIME2(0)=NULL,@dHasta DATETIME2(0)=NULL;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudieron consultar las evaluaciones.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'EVALUACIONES_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPagina=ISNULL(NULLIF(pagina,0),1),@nTam=ISNULL(NULLIF(tamanoPagina,0),20),
           @nVisita=visitaTecnicaId,@nCultivo=parcelaCultivoId,@nTipo=tipoEvaluacionId,@dDesde=fechaDesde,@dHasta=fechaHasta
    FROM OPENJSON(@cJson,'$.filtros') WITH
    (pagina INT '$.pagina',tamanoPagina INT '$.tamanoPagina',visitaTecnicaId BIGINT '$.visitaTecnicaId',
     parcelaCultivoId BIGINT '$.parcelaCultivoId',tipoEvaluacionId SMALLINT '$.tipoEvaluacionId',
     fechaDesde DATETIME2(0) '$.fechaDesde',fechaHasta DATETIME2(0) '$.fechaHasta');
    IF @nPagina<1 SET @nPagina=1;
 IF @nTam<1 SET @nTam=20;
 IF @nTam>200 SET @nTam=200;
    ;
WITH Q AS
    (
      SELECT EA.evaluacion_agronomica_id,EA.visita_tecnica_id,EA.parcela_cultivo_id,EA.tipo_evaluacion_id,
             TE.codigo codigo_tipo,TE.nombre tipo_evaluacion,EA.fecha_hora,EA.resultado,EA.observacion,
             EMS.porcentaje_materia_seca,EMS.numero_muestras,V.predio_id,PR.codigo codigo_predio,PR.nombre predio,
             COUNT(*) OVER() total_registros
      FROM [campo].[EvaluacionAgronomica] EA
      INNER JOIN [campo].[TipoEvaluacion] TE ON TE.tipo_evaluacion_id=EA.tipo_evaluacion_id
      INNER JOIN [campo].[VisitaTecnica] V ON V.visita_tecnica_id=EA.visita_tecnica_id
      INNER JOIN [prod].[Predio] PR ON PR.predio_id=V.predio_id
      LEFT JOIN [campo].[EvaluacionMateriaSeca] EMS ON EMS.evaluacion_materia_seca_id=EA.evaluacion_agronomica_id AND EMS.estado=1
      WHERE EA.estado=1
        AND (@nVisita IS NULL OR EA.visita_tecnica_id=@nVisita)
        AND (@nCultivo IS NULL OR EA.parcela_cultivo_id=@nCultivo)
        AND (@nTipo IS NULL OR EA.tipo_evaluacion_id=@nTipo)
        AND (@dDesde IS NULL OR EA.fecha_hora>=@dDesde)
        AND (@dHasta IS NULL OR EA.fecha_hora<DATEADD(DAY,1,@dHasta))
    )
    SELECT evaluacion_agronomica_id AS evaluacionAgronomicaId,visita_tecnica_id AS visitaTecnicaId,
           parcela_cultivo_id AS parcelaCultivoId,tipo_evaluacion_id AS tipoEvaluacionId,
           codigo_tipo AS codigoTipoEvaluacion,tipo_evaluacion AS tipoEvaluacion,fecha_hora AS fechaHora,
           resultado,observacion,porcentaje_materia_seca AS porcentajeMateriaSeca,numero_muestras AS numeroMuestras,
           predio_id AS predioId,codigo_predio AS codigoPredio,predio,total_registros AS totalRegistros
    FROM Q ORDER BY fecha_hora DESC,evaluacion_agronomica_id DESC
    OFFSET (@nPagina-1)*@nTam ROWS FETCH NEXT @nTam ROWS ONLY;
    SET @bResultado=1;
 SET @cMensaje=N'Consulta realizada correctamente.';

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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Sel_Listado',
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
    @cProcedimiento = N'campo.PA_EvaluacionAgronomica_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_EvaluacionAgronomica_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
