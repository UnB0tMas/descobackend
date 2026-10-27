IF OBJECT_ID(N'[campo].[PA_VisitaTecnica_Sel_DetalleCompleto]', N'P') IS NOT NULL
    DROP PROCEDURE [campo].[PA_VisitaTecnica_Sel_DetalleCompleto];
GO

/******************************************************************************************************
' Nombre del PA           : campo.PA_VisitaTecnica_Sel_DetalleCompleto
' Descripción             : Consulta el detalle completo de una visita técnica.
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
    EXEC [campo].[PA_VisitaTecnica_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [campo].[PA_VisitaTecnica_Sel_DetalleCompleto]
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
            @bCtx BIT,@cMsg NVARCHAR(300),@nVisita BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo consultar la visita.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'VISITAS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
    IF @bCtx=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nVisita=visitaTecnicaId FROM OPENJSON(@cJson,'$.visita') WITH (visitaTecnicaId BIGINT '$.visitaTecnicaId');
    IF NOT EXISTS(SELECT 1 FROM [campo].[VisitaTecnica] WHERE visita_tecnica_id=@nVisita AND estado=1)
    BEGIN SET @cMensaje=N'La visita seleccionada no está disponible.';
 GOTO __DESCO_Salida;
 END;

    /* 1. Ficha de visita + ubicación */
    SELECT V.visita_tecnica_id AS visitaTecnicaId,SP.salida_campo_id AS salidaCampoId,
           V.salida_participante_id AS salidaParticipanteId,SP.empleado_id AS empleadoId,
           CONCAT(P.nombres,N' ',P.apellido_paterno,
                  CASE WHEN P.apellido_materno IS NULL THEN N'' ELSE N' '+P.apellido_materno END) AS tecnico,
           V.predio_id AS predioId,PR.codigo AS codigoPredio,PR.nombre AS predio,
           V.fecha_hora_inicio AS fechaHoraInicio,V.fecha_hora_fin AS fechaHoraFin,
           V.objetivo,V.resumen,V.recomendaciones,V.estado_proceso AS estadoProceso,
           CASE WHEN V.posicion_inicio IS NULL THEN NULL ELSE V.posicion_inicio.Lat END AS latitud,
           CASE WHEN V.posicion_inicio IS NULL THEN NULL ELSE V.posicion_inicio.Long END AS longitud
    FROM [campo].[VisitaTecnica] V
    INNER JOIN [campo].[SalidaParticipante] SP ON SP.salida_participante_id=V.salida_participante_id
    INNER JOIN [org].[Persona] P ON P.persona_id=SP.empleado_id
    INNER JOIN [prod].[Predio] PR ON PR.predio_id=V.predio_id
    WHERE V.visita_tecnica_id=@nVisita AND V.estado=1;

    /* 2. Evaluaciones registradas */
    SELECT EA.evaluacion_agronomica_id AS evaluacionAgronomicaId,EA.parcela_cultivo_id AS parcelaCultivoId,
           EA.tipo_evaluacion_id AS tipoEvaluacionId,TE.codigo AS codigoTipoEvaluacion,TE.nombre AS tipoEvaluacion,
           EA.fecha_hora AS fechaHora,EA.resultado,EA.observacion,
           EMS.porcentaje_materia_seca AS porcentajeMateriaSeca,EMS.numero_muestras AS numeroMuestras
    FROM [campo].[EvaluacionAgronomica] EA
    INNER JOIN [campo].[TipoEvaluacion] TE ON TE.tipo_evaluacion_id=EA.tipo_evaluacion_id
    LEFT JOIN [campo].[EvaluacionMateriaSeca] EMS ON EMS.evaluacion_materia_seca_id=EA.evaluacion_agronomica_id AND EMS.estado=1
    WHERE EA.visita_tecnica_id=@nVisita AND EA.estado=1
    ORDER BY EA.fecha_hora,EA.evaluacion_agronomica_id;

    /* 3. Evidencias vinculadas directamente a la visita */
    SELECT A.archivo_id AS archivoId,A.nombre_original AS nombreOriginal,A.mime_type AS mimeType,
           A.tamano_bytes AS tamanoBytes,A.secure_url AS secureUrl,A.categoria,A.origen_captura AS origenCaptura,
           A.fecha_carga AS fechaCarga
    FROM [archivo].[ArchivoVinculo] AV
    INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id
    WHERE AV.visita_tecnica_id=@nVisita AND AV.estado=1 AND A.estado=1
    ORDER BY A.fecha_carga DESC,A.archivo_id DESC;

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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Sel_DetalleCompleto',
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
    @cProcedimiento = N'campo.PA_VisitaTecnica_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'campo.PA_VisitaTecnica_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
