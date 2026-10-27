IF OBJECT_ID(N'[geo].[PA_Ubicacion_Upd_Interna]', N'P') IS NOT NULL
    DROP PROCEDURE [geo].[PA_Ubicacion_Upd_Interna];
GO

/******************************************************************************************************
' Nombre del PA           : geo.PA_Ubicacion_Upd_Interna
' Descripción             : Actualiza internamente una ubicación geográfica.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Geografía
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [geo].[PA_Ubicacion_Upd_Interna]
        @nUbicacionId = 0,
        @cDistritoCodigo = '',
        @nCentroPobladoId = 0,
        @cReferencia = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @nLatitud = 0,
        @nLongitud = 0,
        @nAltitudM = 0,
        @bActualizarGeoposicion = 0,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [geo].[PA_Ubicacion_Upd_Interna]
(
    @nUbicacionId            BIGINT,
    @cDistritoCodigo         CHAR(6),
    @nCentroPobladoId        BIGINT = NULL,
    @cReferencia             NVARCHAR(300) = NULL,
    @bResultado              BIT OUTPUT,
    @cMensaje                NVARCHAR(300) OUTPUT,

    /* Parámetros añadidos al final para mantener compatibilidad con
       las llamadas posicionales del parche Persona/Empresa V2. */
    @nLatitud                DECIMAL(9,6) = NULL,
    @nLongitud               DECIMAL(9,6) = NULL,
    @nAltitudM               DECIMAL(8,2) = NULL,
    @bActualizarGeoposicion  BIT = 0,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    SET NOCOUNT ON;

    DECLARE @gPosicion GEOGRAPHY = NULL;

    SET @bResultado=0;
    SET @cMensaje=N'No se pudo actualizar la ubicación.';
    SET @cDistritoCodigo=NULLIF(LTRIM(RTRIM(@cDistritoCodigo)),'');
    SET @cReferencia=NULLIF(LTRIM(RTRIM(@cReferencia)),N'');

    IF @nUbicacionId IS NULL
    BEGIN
        SET @cMensaje=N'La ubicación seleccionada no es válida.';
        GOTO __DESCO_Salida;
    END;

    IF @cDistritoCodigo IS NULL
    BEGIN
        SET @cMensaje=N'Seleccione un distrito.';
        GOTO __DESCO_Salida;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [geo].[Distrito] D
        WHERE D.distrito_codigo=@cDistritoCodigo
          AND D.estado=1
    )
    BEGIN
        SET @cMensaje=N'El distrito seleccionado no está disponible.';
        GOTO __DESCO_Salida;
    END;

    IF @nCentroPobladoId IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [geo].[CentroPoblado] CP
           WHERE CP.centro_poblado_id=@nCentroPobladoId
             AND CP.distrito_codigo=@cDistritoCodigo
             AND CP.estado=1
       )
    BEGIN
        SET @cMensaje=N'El centro poblado seleccionado no corresponde al distrito.';
        GOTO __DESCO_Salida;
    END;

    IF @bActualizarGeoposicion=1
    BEGIN
        IF (@nLatitud IS NULL AND @nLongitud IS NOT NULL)
           OR (@nLatitud IS NOT NULL AND @nLongitud IS NULL)
           OR (@nLatitud IS NOT NULL AND (@nLatitud < -90 OR @nLatitud > 90))
           OR (@nLongitud IS NOT NULL AND (@nLongitud < -180 OR @nLongitud > 180))
        BEGIN
            SET @cMensaje=N'La latitud y longitud seleccionadas no son válidas.';
            GOTO __DESCO_Salida;
        END;

        IF @nLatitud IS NOT NULL
        BEGIN
            SET @gPosicion=geography::Point(@nLatitud,@nLongitud,4326);
        END;
    END;

    IF @bActualizarGeoposicion=1
    BEGIN
        UPDATE [geo].[Ubicacion]
           SET distrito_codigo=@cDistritoCodigo,
               centro_poblado_id=@nCentroPobladoId,
               referencia=@cReferencia,
               posicion=@gPosicion,
               altitud_m=@nAltitudM,
               estado=1
         WHERE ubicacion_id=@nUbicacionId;
    END
    ELSE
    BEGIN
        UPDATE [geo].[Ubicacion]
           SET distrito_codigo=@cDistritoCodigo,
               centro_poblado_id=@nCentroPobladoId,
               referencia=@cReferencia,
               estado=1
         WHERE ubicacion_id=@nUbicacionId;
    END;

    IF @@ROWCOUNT=0
    BEGIN
        SET @cMensaje=N'La ubicación seleccionada no está disponible.';
        GOTO __DESCO_Salida;
    END;

    SET @bResultado=1;
    SET @cMensaje=N'Ubicación actualizada correctamente.';

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
    @cProcedimiento = N'geo.PA_Ubicacion_Upd_Interna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
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
    @cProcedimiento = N'geo.PA_Ubicacion_Upd_Interna',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'geo.PA_Ubicacion_Upd_Interna',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
