IF OBJECT_ID(N'[geo].[PA_Ubicacion_Ins_Interna]', N'P') IS NOT NULL
    DROP PROCEDURE [geo].[PA_Ubicacion_Ins_Interna];
GO

/******************************************************************************************************
' Nombre del PA           : geo.PA_Ubicacion_Ins_Interna
' Descripción             : Registra internamente una ubicación geográfica.
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
        @nUbicacionId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [geo].[PA_Ubicacion_Ins_Interna]
        @cDistritoCodigo = '',
        @nCentroPobladoId = 0,
        @cReferencia = N'',
        @nLatitud = 0,
        @nLongitud = 0,
        @nAltitudM = 0,
        @nUbicacionId = @nUbicacionId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUbicacionId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [geo].[PA_Ubicacion_Ins_Interna]
(
    @cDistritoCodigo       CHAR(6),
    @nCentroPobladoId      BIGINT = NULL,
    @cReferencia           NVARCHAR(300) = NULL,
    @nLatitud              DECIMAL(9,6) = NULL,
    @nLongitud             DECIMAL(9,6) = NULL,
    @nAltitudM             DECIMAL(8,2) = NULL,
    @nUbicacionId          BIGINT OUTPUT,
    @bResultado            BIT OUTPUT,
    @cMensaje              NVARCHAR(300) OUTPUT,
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

    SET @nUbicacionId = NULL;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo registrar la ubicación.';
    SET @cDistritoCodigo = NULLIF(LTRIM(RTRIM(@cDistritoCodigo)), '');
    SET @cReferencia = NULLIF(LTRIM(RTRIM(@cReferencia)), N'');

    IF @cDistritoCodigo IS NULL
    BEGIN
        SET @cMensaje = N'Seleccione un distrito.';
        GOTO __DESCO_Salida;
    END;

    IF NOT EXISTS (SELECT 1 FROM [geo].[Distrito] D WHERE D.distrito_codigo = @cDistritoCodigo AND D.estado = 1)
    BEGIN
        SET @cMensaje = N'El distrito seleccionado no está disponible.';
        GOTO __DESCO_Salida;
    END;

    IF @nCentroPobladoId IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM [geo].[CentroPoblado] CP
           WHERE CP.centro_poblado_id = @nCentroPobladoId
             AND CP.distrito_codigo = @cDistritoCodigo
             AND CP.estado = 1
       )
    BEGIN
        SET @cMensaje = N'El centro poblado seleccionado no corresponde al distrito.';
        GOTO __DESCO_Salida;
    END;

    IF (@nLatitud IS NULL AND @nLongitud IS NOT NULL)
       OR (@nLatitud IS NOT NULL AND @nLongitud IS NULL)
       OR (@nLatitud IS NOT NULL AND (@nLatitud < -90 OR @nLatitud > 90))
       OR (@nLongitud IS NOT NULL AND (@nLongitud < -180 OR @nLongitud > 180))
    BEGIN
        SET @cMensaje = N'La ubicación seleccionada no es válida.';
        GOTO __DESCO_Salida;
    END;

    INSERT INTO [geo].[Ubicacion]
    (
        distrito_codigo, centro_poblado_id, referencia, posicion, altitud_m, estado
    )
    VALUES
    (
        @cDistritoCodigo,
        @nCentroPobladoId,
        @cReferencia,
        CASE WHEN @nLatitud IS NULL THEN NULL ELSE geography::Point(@nLatitud, @nLongitud, 4326) END,
        @nAltitudM,
        1
    );

    SET @nUbicacionId = CONVERT(BIGINT, SCOPE_IDENTITY());
    SET @bResultado = 1;
    SET @cMensaje = N'Ubicación registrada correctamente.';

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
    @cProcedimiento = N'geo.PA_Ubicacion_Ins_Interna',
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
    @cProcedimiento = N'geo.PA_Ubicacion_Ins_Interna',
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
FROM config.FN_RespuestaUsuario(N'geo.PA_Ubicacion_Ins_Interna',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
