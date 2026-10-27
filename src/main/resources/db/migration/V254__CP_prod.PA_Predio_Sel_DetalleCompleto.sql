IF OBJECT_ID(N'[prod].[PA_Predio_Sel_DetalleCompleto]', N'P') IS NOT NULL
    DROP PROCEDURE [prod].[PA_Predio_Sel_DetalleCompleto];
GO

/******************************************************************************************************
' Nombre del PA           : prod.PA_Predio_Sel_DetalleCompleto
' Descripción             : Consulta el detalle completo de predios.
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
    EXEC [prod].[PA_Predio_Sel_DetalleCompleto]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [prod].[PA_Predio_Sel_DetalleCompleto]
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
    DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bOk BIT,@cMsg NVARCHAR(300),@nPredio BIGINT;
    SET @bResultado=0;
 SET @cMensaje=N'No se pudo cargar el detalle.';
    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado] @cJson,'PREDIOS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bOk OUTPUT,@cMsg OUTPUT;
    IF @bOk=0 BEGIN SET @cMensaje=@cMsg;
 GOTO __DESCO_Salida;
 END;
    SELECT @nPredio=predioId FROM OPENJSON(@cJson,'$.filtros') WITH (predioId BIGINT '$.predioId');
    IF @nPredio IS NULL OR NOT EXISTS(SELECT 1 FROM [prod].[Predio] WHERE predio_id=@nPredio) BEGIN SET @cMensaje=N'El predio seleccionado no está disponible.';
 GOTO __DESCO_Salida;
 END;

    /* 1. Ficha + mapa + versión vigente */
    SELECT PR.predio_id,PR.codigo,PR.nombre,PR.fecha_registro,PR.estado,U.ubicacion_id,U.distrito_codigo,U.centro_poblado_id,U.referencia,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Lat END latitud,
           CASE WHEN U.posicion IS NULL THEN NULL ELSE U.posicion.Long END longitud,U.altitud_m,
           PV.predio_version_id,PV.area_total_ha,PV.area_cultivable_ha,PV.tipo_riego,PV.fuente_agua,PV.infraestructura,PV.observacion,PV.fecha_desde
    FROM [prod].[Predio] PR INNER JOIN [geo].[Ubicacion] U ON U.ubicacion_id=PR.ubicacion_id
    OUTER APPLY(SELECT TOP(1) V.* FROM [prod].[PredioVersion] V WHERE V.predio_id=PR.predio_id AND V.estado=1 AND V.fecha_hasta IS NULL ORDER BY V.fecha_desde DESC) PV
    WHERE PR.predio_id=@nPredio;

    /* 2. Titularidad completa */
    SELECT PT.predio_titularidad_id,PT.socio_id,P.tipo_documento,P.numero_documento,P.nombres,P.apellido_paterno,P.apellido_materno,
           PT.tipo_titularidad,PT.porcentaje,PT.fecha_desde,PT.fecha_hasta,PT.estado
    FROM [prod].[PredioTitularidad] PT INNER JOIN [org].[Persona] P ON P.persona_id=PT.socio_id WHERE PT.predio_id=@nPredio ORDER BY PT.fecha_desde DESC,PT.predio_titularidad_id;

    /* 3. Historial de características */
    SELECT predio_version_id,area_total_ha,area_cultivable_ha,tipo_riego,fuente_agua,infraestructura,observacion,fecha_desde,fecha_hasta,estado
    FROM [prod].[PredioVersion] WHERE predio_id=@nPredio ORDER BY fecha_desde DESC,predio_version_id DESC;

    /* 4. Parcelas y cultivos */
    SELECT PA.parcela_id,PA.codigo parcelaCodigo,PA.nombre parcelaNombre,PA.area_ha,PA.estado parcelaEstado,PA.ubicacion_id,
           PC.parcela_cultivo_id,VP.variedad_palta_id,VP.nombre variedad,PC.fecha_inicio,PC.fecha_fin,PC.situacion_cultivo,PC.estado cultivoEstado
    FROM [prod].[Parcela] PA LEFT JOIN [prod].[ParcelaCultivo] PC ON PC.parcela_id=PA.parcela_id
    LEFT JOIN [prod].[VariedadPalta] VP ON VP.variedad_palta_id=PC.variedad_palta_id WHERE PA.predio_id=@nPredio ORDER BY PA.nombre,PC.fecha_inicio DESC;

    /* 5. Evidencias vinculadas al predio */
    SELECT A.archivo_id,A.nombre_original,A.mime_type,A.secure_url,A.fecha_carga,A.categoria,A.origen_captura
    FROM [archivo].[ArchivoVinculo] AV INNER JOIN [archivo].[Archivo] A ON A.archivo_id=AV.archivo_id WHERE AV.predio_id=@nPredio AND AV.estado=1 AND A.estado=1 ORDER BY A.fecha_carga DESC;

    SET @bResultado=1;
 SET @cMensaje=N'Detalle cargado correctamente.';

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
    @cProcedimiento = N'prod.PA_Predio_Sel_DetalleCompleto',
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
    @cProcedimiento = N'prod.PA_Predio_Sel_DetalleCompleto',
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
FROM config.FN_RespuestaUsuario(N'prod.PA_Predio_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
