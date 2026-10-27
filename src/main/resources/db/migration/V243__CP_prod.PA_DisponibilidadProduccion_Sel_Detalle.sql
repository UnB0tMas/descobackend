IF OBJECT_ID(N'[prod].[PA_DisponibilidadProduccion_Sel_Detalle]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_DisponibilidadProduccion_Sel_Detalle];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_DisponibilidadProduccion_Sel_Detalle
' Descripción             : Consulta el detalle de disponibilidades de producción.
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
    EXEC [prod].[PA_DisponibilidadProduccion_Sel_Detalle]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_DisponibilidadProduccion_Sel_Detalle]
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
        @bCtx BIT,@cMsg NVARCHAR(300),@nId BIGINT;

    SELECT
        @bResultado=0,
        @cMensaje=N'No se pudo consultar la estimación.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson,'PRODUCCION_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,
        @nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;

    IF @bCtx=0
    BEGIN
        SET @cMensaje=@cMsg;
        GOTO __DESCO_Salida;
    END;

    SELECT @nId=disponibilidadProduccionId
    FROM OPENJSON(@cJson,'$.produccion')
    WITH(disponibilidadProduccionId BIGINT '$.disponibilidadProduccionId');

    IF @nId IS NULL
       OR NOT EXISTS
          (
              SELECT 1
              FROM [prod].[DisponibilidadProduccion]
              WHERE disponibilidad_produccion_id=@nId
                AND estado=1
          )
    BEGIN
        SET @cMensaje=N'La estimación seleccionada no está disponible.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        DP.disponibilidad_produccion_id disponibilidadProduccionId,
        DP.parcela_cultivo_id parcelaCultivoId,
        DP.visita_tecnica_id visitaTecnicaId,
        CASE WHEN DP.visita_tecnica_id IS NULL THEN N'Estimación directa' ELSE N'Visita técnica' END origenEstimacion,
        DP.fecha_estimacion fechaEstimacion,
        DP.disponible_desde disponibleDesde,
        DP.disponible_hasta disponibleHasta,
        DP.cantidad_estimada_kg cantidadEstimadaKg,
        DP.estado_estimacion estadoEstimacion,
        DP.observacion,
        PC.situacion_cultivo estadoCultivo,
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
        V.fecha_hora_inicio visitaFechaInicio,
        V.estado_proceso visitaEstado
    FROM [prod].[DisponibilidadProduccion] DP
    INNER JOIN [prod].[ParcelaCultivo] PC
        ON PC.parcela_cultivo_id=DP.parcela_cultivo_id
    INNER JOIN [prod].[VariedadPalta] VP
        ON VP.variedad_palta_id=PC.variedad_palta_id
    INNER JOIN [prod].[Parcela] P
        ON P.parcela_id=PC.parcela_id
    INNER JOIN [prod].[Predio] PR
        ON PR.predio_id=P.predio_id
    LEFT JOIN [campo].[VisitaTecnica] V
        ON V.visita_tecnica_id=DP.visita_tecnica_id
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
    WHERE DP.disponibilidad_produccion_id=@nId;

    SELECT
        A.archivo_id archivoId,
        A.nombre_original nombreOriginal,
        A.mime_type mimeType,
        A.secure_url secureUrl,
        A.categoria,
        A.tipo_evidencia tipoEvidencia,
        A.origen_captura origenCaptura,
        A.descripcion,
        A.fecha_captura fechaCaptura,
        A.fecha_carga fechaCarga
    FROM [archivo].[ArchivoVinculo] AV
    INNER JOIN [archivo].[Archivo] A
        ON A.archivo_id=AV.archivo_id
    WHERE AV.disponibilidad_produccion_id=@nId
      AND AV.estado=1
      AND A.estado=1
    ORDER BY A.fecha_carga DESC;

    SET @bResultado=1;
    SET @cMensaje=N'Detalle de producción cargado correctamente.';

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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Sel_Detalle',
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
    @cProcedimiento = N'prod.PA_DisponibilidadProduccion_Sel_Detalle',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_DisponibilidadProduccion_Sel_Detalle',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
