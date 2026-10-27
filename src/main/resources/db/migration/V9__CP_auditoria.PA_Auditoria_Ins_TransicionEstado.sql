IF OBJECT_ID(N'[auditoria].[PA_Auditoria_Ins_TransicionEstado]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_Auditoria_Ins_TransicionEstado];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_Auditoria_Ins_TransicionEstado
' Descripción             : Registra una transición de estado para una entidad auditada.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Auditoría
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo. Sustituir JSON, IDs y valores por datos válidos del entorno.
    DECLARE
        @nTransicionEstadoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [auditoria].[PA_Auditoria_Ins_TransicionEstado]
        @cEsquemaEntidad = N'campo',
        @cNombreEntidad = N'SalidaCampo',
        @cIdentificador = N'1',
        @cCampoEstado = N'estado',
        @cEstadoNuevo = 'FINALIZADO',
        @nTransicionEstadoId = @nTransicionEstadoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nTransicionEstadoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_Auditoria_Ins_TransicionEstado]
(
    @nUsuarioId                 BIGINT = NULL,
    @nSesionUsuarioId           BIGINT = NULL,
    @nDispositivoUsuarioId      BIGINT = NULL,
    @nModuloId                  INT = NULL,
    @cEsquemaEntidad            SYSNAME,
    @cNombreEntidad             SYSNAME,
    @cIdentificador             NVARCHAR(200),
    @cCampoEstado               SYSNAME,
    @cEstadoAnterior            VARCHAR(40) = NULL,
    @cEstadoNuevo               VARCHAR(40),
    @cMotivo                    NVARCHAR(500) = NULL,
    @cIp                        VARCHAR(64) = NULL,
    @gCorrelacionId             UNIQUEIDENTIFIER = NULL,
    @nTransicionEstadoId        BIGINT OUTPUT,
    @bResultado BIT=NULL OUTPUT,
    @cMensaje NVARCHAR(300)=NULL OUTPUT,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    SET @bResultado=0;
BEGIN TRY

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;

    DECLARE @nAuditoriaEventoId BIGINT;
    DECLARE @cAntes NVARCHAR(MAX);
    DECLARE @cDespues NVARCHAR(MAX);

    SET @nTransicionEstadoId = NULL;

    SET @cEsquemaEntidad = NULLIF(LTRIM(RTRIM(@cEsquemaEntidad)), '');
    SET @cNombreEntidad = NULLIF(LTRIM(RTRIM(@cNombreEntidad)), '');
    SET @cIdentificador = NULLIF(LTRIM(RTRIM(@cIdentificador)), '');
    SET @cCampoEstado = NULLIF(LTRIM(RTRIM(@cCampoEstado)), '');
    SET @cEstadoAnterior = NULLIF(LTRIM(RTRIM(@cEstadoAnterior)), '');
    SET @cEstadoNuevo = NULLIF(LTRIM(RTRIM(@cEstadoNuevo)), '');

    IF @cEsquemaEntidad IS NULL
       OR @cNombreEntidad IS NULL
       OR @cIdentificador IS NULL
       OR @cCampoEstado IS NULL
       OR @cEstadoNuevo IS NULL
    BEGIN
        THROW 52110, N'No se pudo registrar el cambio de estado.', 1;
    END;

    INSERT INTO [auditoria].[TransicionEstado]
    (
        [usuario_id],
        [sesion_usuario_id],
        [dispositivo_usuario_id],
        [modulo_id],
        [fecha_hora],
        [esquema_entidad],
        [nombre_entidad],
        [identificador],
        [campo_estado],
        [estado_anterior],
        [estado_nuevo],
        [motivo],
        [correlacion_id],
        [estado]
    )
    VALUES
    (
        @nUsuarioId,
        @nSesionUsuarioId,
        @nDispositivoUsuarioId,
        @nModuloId,
        SYSUTCDATETIME(),
        @cEsquemaEntidad,
        @cNombreEntidad,
        @cIdentificador,
        @cCampoEstado,
        @cEstadoAnterior,
        @cEstadoNuevo,
        @cMotivo,
        @gCorrelacionId,
        1
    );

    SET @nTransicionEstadoId = SCOPE_IDENTITY();

    SELECT @cAntes =
    (
        SELECT
            @cCampoEstado AS campo,
            @cEstadoAnterior AS valor
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    SELECT @cDespues =
    (
        SELECT
            @cCampoEstado AS campo,
            @cEstadoNuevo AS valor
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    EXEC [auditoria].[PA_Auditoria_Ins_Evento]
         @nUsuarioId = @nUsuarioId,
         @nSesionUsuarioId = @nSesionUsuarioId,
         @nDispositivoUsuarioId = @nDispositivoUsuarioId,
         @nModuloId = @nModuloId,
         @cAccion = 'CAMBIO_ESTADO',
         @cEsquemaEntidad = @cEsquemaEntidad,
         @cNombreEntidad = @cNombreEntidad,
         @cIdentificador = @cIdentificador,
         @cDatosAnteriores = @cAntes,
         @cDatosPosteriores = @cDespues,
         @cMotivo = @cMotivo,
         @cIp = @cIp,
         @cResultado = 'EXITOSO',
         @gCorrelacionId = @gCorrelacionId,
         @nAuditoriaEventoId = @nAuditoriaEventoId OUTPUT;

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
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'auditoria.PA_Auditoria_Ins_TransicionEstado',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
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
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'auditoria.PA_Auditoria_Ins_TransicionEstado',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 AND @nTransicionEstadoId IS NOT NULL THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'auditoria.PA_Auditoria_Ins_TransicionEstado',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
