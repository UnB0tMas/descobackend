IF OBJECT_ID(N'[prod].[PA_ParcelaCultivo_Sel_DetalleExpediente]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_ParcelaCultivo_Sel_DetalleExpediente];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_ParcelaCultivo_Sel_DetalleExpediente
' Descripción             : Consulta el detalle de expediente de una parcela de cultivo.
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
    EXEC [prod].[PA_ParcelaCultivo_Sel_DetalleExpediente]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_ParcelaCultivo_Sel_DetalleExpediente]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nParcela BIGINT,@nCultivo BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar el expediente.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'CULTIVOS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nParcela=parcelaId,@nCultivo=parcelaCultivoId FROM OPENJSON(@cJson,'$.filtros') WITH (parcelaId BIGINT '$.parcelaId',parcelaCultivoId BIGINT '$.parcelaCultivoId');
    IF @nParcela IS NULL AND @nCultivo IS NOT NULL SELECT @nParcela=parcela_id FROM [prod].[ParcelaCultivo] WHERE parcela_cultivo_id=@nCultivo;
    IF @nParcela IS NULL OR NOT EXISTS(SELECT 1 FROM [prod].[Parcela] WHERE parcela_id=@nParcela) BEGIN SET @cMensaje=N'La parcela seleccionada no está disponible.';
 GOTO __DESCO_Salida;
 END;

    /* 1. Parcela + ubicación efectiva.
       Si la parcela no tiene ubicación propia, hereda la del predio. */
    SELECT
        PA.parcela_id,
        PA.predio_id,
        PR.codigo predioCodigo,
        PR.nombre predioNombre,
        PA.codigo,
        PA.nombre,
        PA.area_ha,
        PA.estado,
        COALESCE(PA.ubicacion_id,PR.ubicacion_id) AS ubicacion_id,
        CAST(CASE WHEN PA.ubicacion_id IS NULL THEN 0 ELSE 1 END AS BIT) AS ubicacionPropia,
        U.distrito_codigo,
        U.centro_poblado_id,
        U.referencia,
        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END latitud,
        CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END longitud,
        U.altitud_m
    FROM [prod].[Parcela] PA
    INNER JOIN [prod].[Predio] PR
            ON PR.predio_id=PA.predio_id
    LEFT JOIN [geo].[Ubicacion] U
           ON U.ubicacion_id=COALESCE(PA.ubicacion_id,PR.ubicacion_id)
    WHERE PA.parcela_id=@nParcela;
    /* 2. Cultivos */
    SELECT PC.parcela_cultivo_id,PC.variedad_palta_id,VP.codigo variedadCodigo,VP.nombre variedad,PC.fecha_inicio,PC.fecha_fin,PC.situacion_cultivo,PC.estado
    FROM [prod].[ParcelaCultivo] PC INNER JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id WHERE PC.parcela_id=@nParcela ORDER BY PC.fecha_inicio DESC;
    /* 3. Censos */
    SELECT C.censo_plantas_id,C.parcela_cultivo_id,C.fecha_censo,C.plantas_totales,C.plantas_productivas,C.plantas_no_productivas,C.plantas_nuevas,C.plantas_muertas,C.plantas_afectadas,C.observacion,C.estado
    FROM [prod].[CensoPlantas] C INNER JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_cultivo_id=C.parcela_cultivo_id WHERE PC.parcela_id=@nParcela AND (@nCultivo IS NULL OR C.parcela_cultivo_id=@nCultivo) ORDER BY C.fecha_censo DESC;
    /* 4. Evaluaciones */
    SELECT E.evaluacion_agronomica_id,E.visita_tecnica_id,E.parcela_cultivo_id,E.tipo_evaluacion_id,T.nombre tipoEvaluacion,E.fecha_hora,E.resultado,E.observacion,E.estado
    FROM [campo].[EvaluacionAgronomica] E INNER JOIN [campo].[TipoEvaluacion] T ON T.tipo_evaluacion_id=E.tipo_evaluacion_id INNER JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_cultivo_id=E.parcela_cultivo_id WHERE PC.parcela_id=@nParcela AND (@nCultivo IS NULL OR E.parcela_cultivo_id=@nCultivo) ORDER BY E.fecha_hora DESC;
    /* 5. Evidencias de parcela/cultivo/censo/evaluación */
    SELECT A.archivo_id,A.nombre_original,A.mime_type,A.secure_url,A.fecha_carga,A.categoria,A.origen_captura,AV.parcela_id,AV.parcela_cultivo_id,AV.censo_plantas_id,AV.evaluacion_agronomica_id
    FROM [archivo].[ArchivoVinculo] AV INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id
    WHERE AV.estado=1 AND A.estado=1 AND (AV.parcela_id=@nParcela OR AV.parcela_cultivo_id IN(SELECT parcela_cultivo_id FROM [prod].[ParcelaCultivo] WHERE parcela_id=@nParcela)) ORDER BY A.fecha_carga DESC;
    SET @bResultado=1;
 SET @cMensaje=N'Expediente cargado correctamente.';

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
    @cProcedimiento = N'prod.PA_ParcelaCultivo_Sel_DetalleExpediente',
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
    @cProcedimiento = N'prod.PA_ParcelaCultivo_Sel_DetalleExpediente',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_ParcelaCultivo_Sel_DetalleExpediente',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
