IF OBJECT_ID(N'[seg].[PA_Operacion_Ins_IniciarIdempotente]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Operacion_Ins_IniciarIdempotente];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Operacion_Ins_IniciarIdempotente
' Descripción             : Inicia o recupera una operación idempotente y su contexto autorizado.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Seguridad
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
        @nUsuarioId BIGINT,
        @nSesionUsuarioId BIGINT,
        @nDispositivoUsuarioId BIGINT,
        @nEmpleadoId BIGINT,
        @nModuloId INT,
        @gCorrelacionId UNIQUEIDENTIFIER,
        @gSolicitudId UNIQUEIDENTIFIER,
        @cIp VARCHAR(64),
        @cEndpoint NVARCHAR(250),
        @nOperacionIdempotenteId BIGINT,
        @bEsRepetida BIT,
        @cEstadoOperacion VARCHAR(20),
        @cIdentificadorResultado NVARCHAR(200),
        @cCodigoResultado VARCHAR(40),
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente]
        @cJson = N'{}',
        @cCodigoPermiso = '',
        @cAmbito = '',
        @nUsuarioId = @nUsuarioId OUTPUT,
        @nSesionUsuarioId = @nSesionUsuarioId OUTPUT,
        @nDispositivoUsuarioId = @nDispositivoUsuarioId OUTPUT,
        @nEmpleadoId = @nEmpleadoId OUTPUT,
        @nModuloId = @nModuloId OUTPUT,
        @gCorrelacionId = @gCorrelacionId OUTPUT,
        @gSolicitudId = @gSolicitudId OUTPUT,
        @cIp = @cIp OUTPUT,
        @cEndpoint = @cEndpoint OUTPUT,
        @nOperacionIdempotenteId = @nOperacionIdempotenteId OUTPUT,
        @bEsRepetida = @bEsRepetida OUTPUT,
        @cEstadoOperacion = @cEstadoOperacion OUTPUT,
        @cIdentificadorResultado = @cIdentificadorResultado OUTPUT,
        @cCodigoResultado = @cCodigoResultado OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUsuarioId, @nSesionUsuarioId, @nDispositivoUsuarioId, @nEmpleadoId, @nModuloId, @gCorrelacionId, @gSolicitudId, @cIp, @cEndpoint, @nOperacionIdempotenteId, @bEsRepetida, @cEstadoOperacion, @cIdentificadorResultado, @cCodigoResultado, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Operacion_Ins_IniciarIdempotente]
(
    @cJson                       NVARCHAR(MAX),
    @cCodigoPermiso              VARCHAR(400),
    @cAmbito                     VARCHAR(100),
    @nUsuarioId                  BIGINT OUTPUT,
    @nSesionUsuarioId            BIGINT OUTPUT,
    @nDispositivoUsuarioId       BIGINT OUTPUT,
    @nEmpleadoId                 BIGINT OUTPUT,
    @nModuloId                   INT OUTPUT,
    @gCorrelacionId              UNIQUEIDENTIFIER OUTPUT,
    @gSolicitudId                UNIQUEIDENTIFIER OUTPUT,
    @cIp                         VARCHAR(64) OUTPUT,
    @cEndpoint                   NVARCHAR(250) OUTPUT,
    @nOperacionIdempotenteId     BIGINT OUTPUT,
    @bEsRepetida                 BIT OUTPUT,
    @cEstadoOperacion            VARCHAR(20) OUTPUT,
    @cIdentificadorResultado     NVARCHAR(200) OUTPUT,
    @cCodigoResultado            VARCHAR(40) OUTPUT,
    @bResultado                  BIT OUTPUT,
    @cMensaje                    NVARCHAR(300) OUTPUT,
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

    /* DESCO_JEFE_UOT_33_33_33_43_V1_20260826 */
    SET NOCOUNT ON;

    DECLARE @gClaveIdempotencia UNIQUEIDENTIFIER;
    DECLARE @cRequestHashHex VARCHAR(128);
    DECLARE @bContexto BIT = 0;
    DECLARE @cMensajeContexto NVARCHAR(300);

    SELECT
        @nOperacionIdempotenteId = NULL,
        @bEsRepetida = 0,
        @cEstadoOperacion = NULL,
        @cIdentificadorResultado = NULL,
        @cCodigoResultado = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo procesar la solicitud.';

    EXEC [seg].[PA_Operacion_Sel_ContextoAutorizado]
        @cJson = @cJson,
        @cCodigoPermiso = @cCodigoPermiso,
        @nUsuarioId = @nUsuarioId OUTPUT,
        @nSesionUsuarioId = @nSesionUsuarioId OUTPUT,
        @nDispositivoUsuarioId = @nDispositivoUsuarioId OUTPUT,
        @nEmpleadoId = @nEmpleadoId OUTPUT,
        @nModuloId = @nModuloId OUTPUT,
        @gCorrelacionId = @gCorrelacionId OUTPUT,
        @gSolicitudId = @gSolicitudId OUTPUT,
        @cIp = @cIp OUTPUT,
        @cEndpoint = @cEndpoint OUTPUT,
        @bResultado = @bContexto OUTPUT,
        @cMensaje = @cMensajeContexto OUTPUT;

    IF @bContexto = 0
    BEGIN
        SET @cMensaje = @cMensajeContexto;
        GOTO __DESCO_Salida;
    END;

    SELECT
        @gClaveIdempotencia = claveIdempotencia,
        @cRequestHashHex = NULLIF(LTRIM(RTRIM(requestHashHex)), '')
    FROM OPENJSON(@cJson, '$.contexto')
    WITH
    (
        claveIdempotencia UNIQUEIDENTIFIER '$.claveIdempotencia',
        requestHashHex VARCHAR(128) '$.requestHashHex'
    );

    IF @gClaveIdempotencia IS NULL
    BEGIN
        SET @cMensaje = N'No se pudo procesar la solicitud.';
        GOTO __DESCO_Salida;
    END;

    EXEC [auditoria].[PA_OperacionIdempotente_Ins_Iniciar]
        @nUsuarioId = @nUsuarioId,
        @gClaveIdempotencia = @gClaveIdempotencia,
        @cAmbito = @cAmbito,
        @cRequestHashHex = @cRequestHashHex,
        @nMinutosVigencia = 1440,
        @nOperacionIdempotenteId = @nOperacionIdempotenteId OUTPUT,
        @bEsRepetida = @bEsRepetida OUTPUT,
        @cEstadoOperacion = @cEstadoOperacion OUTPUT,
        @cIdentificadorResultado = @cIdentificadorResultado OUTPUT,
        @cCodigoResultado = @cCodigoResultado OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;

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
    @cProcedimiento = N'seg.PA_Operacion_Ins_IniciarIdempotente',
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
    @cProcedimiento = N'seg.PA_Operacion_Ins_IniciarIdempotente',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Operacion_Ins_IniciarIdempotente',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
