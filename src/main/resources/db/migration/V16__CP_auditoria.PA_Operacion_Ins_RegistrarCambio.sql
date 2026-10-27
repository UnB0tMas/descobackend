IF OBJECT_ID(N'[auditoria].[PA_Operacion_Ins_RegistrarCambio]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_Operacion_Ins_RegistrarCambio];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_Operacion_Ins_RegistrarCambio
' Descripción             : Registra el evento de auditoría y, si procede, la transición de estado.
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
        @nAuditoriaEventoId BIGINT,
        @nTransicionEstadoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [auditoria].[PA_Operacion_Ins_RegistrarCambio]
        @nUsuarioId = 1,
        @nSesionUsuarioId = 1,
        @nModuloId = 1,
        @cAccion = 'ACTUALIZAR',
        @cEsquemaEntidad = N'campo',
        @cNombreEntidad = N'SalidaCampo',
        @cIdentificador = N'1',
        @nAuditoriaEventoId = @nAuditoriaEventoId OUTPUT,
        @nTransicionEstadoId = @nTransicionEstadoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nAuditoriaEventoId, @nTransicionEstadoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_Operacion_Ins_RegistrarCambio]
(
    @nUsuarioId                 BIGINT,
    @nSesionUsuarioId           BIGINT,
    @nDispositivoUsuarioId      BIGINT = NULL,
    @nModuloId                  INT,
    @cAccion                    VARCHAR(40),
    @cEsquemaEntidad            SYSNAME,
    @cNombreEntidad             SYSNAME,
    @cIdentificador             NVARCHAR(200),
    @cDatosAnteriores           NVARCHAR(MAX) = NULL,
    @cDatosPosteriores          NVARCHAR(MAX) = NULL,
    @cMotivo                    NVARCHAR(500) = NULL,
    @cCampoEstado               SYSNAME = NULL,
    @cEstadoAnterior            VARCHAR(40) = NULL,
    @cEstadoNuevo               VARCHAR(40) = NULL,
    @cIp                        VARCHAR(64) = NULL,
    @gCorrelacionId             UNIQUEIDENTIFIER = NULL,
    @gSolicitudId               UNIQUEIDENTIFIER = NULL,
    @cEndpoint                  NVARCHAR(250) = NULL,
    @nAuditoriaEventoId         BIGINT OUTPUT,
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

    SET @bResultado=0;
BEGIN TRY
BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

    SET NOCOUNT ON;

    SET @nAuditoriaEventoId = NULL;
    SET @nTransicionEstadoId = NULL;

    EXEC [auditoria].[PA_Auditoria_Ins_Evento]
        @nUsuarioId = @nUsuarioId,
        @nSesionUsuarioId = @nSesionUsuarioId,
        @nDispositivoUsuarioId = @nDispositivoUsuarioId,
        @nModuloId = @nModuloId,
        @cAccion = @cAccion,
        @cEsquemaEntidad = @cEsquemaEntidad,
        @cNombreEntidad = @cNombreEntidad,
        @cIdentificador = @cIdentificador,
        @cDatosAnteriores = @cDatosAnteriores,
        @cDatosPosteriores = @cDatosPosteriores,
        @cMotivo = @cMotivo,
        @cIp = @cIp,
        @cDispositivo = NULL,
        @cResultado = 'EXITOSO',
        @gCorrelacionId = @gCorrelacionId,
        @gSolicitudId = @gSolicitudId,
        @cEndpoint = @cEndpoint,
        @nAuditoriaEventoId = @nAuditoriaEventoId OUTPUT;

    IF @cCampoEstado IS NOT NULL AND @cEstadoNuevo IS NOT NULL
    BEGIN
        EXEC [auditoria].[PA_Auditoria_Ins_TransicionEstado]
            @nUsuarioId = @nUsuarioId,
            @nSesionUsuarioId = @nSesionUsuarioId,
            @nDispositivoUsuarioId = @nDispositivoUsuarioId,
            @nModuloId = @nModuloId,
            @cEsquemaEntidad = @cEsquemaEntidad,
            @cNombreEntidad = @cNombreEntidad,
            @cIdentificador = @cIdentificador,
            @cCampoEstado = @cCampoEstado,
            @cEstadoAnterior = @cEstadoAnterior,
            @cEstadoNuevo = @cEstadoNuevo,
            @cMotivo = @cMotivo,
            @cIp = @cIp,
            @gCorrelacionId = @gCorrelacionId,
            @nTransicionEstadoId = @nTransicionEstadoId OUTPUT;
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
    @cProcedimiento = N'auditoria.PA_Operacion_Ins_RegistrarCambio',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
    IF @__DbError = 0 AND XACT_STATE() = 1
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
    ELSE
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
    @cProcedimiento = N'auditoria.PA_Operacion_Ins_RegistrarCambio',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 AND @nAuditoriaEventoId IS NOT NULL THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'auditoria.PA_Operacion_Ins_RegistrarCambio',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
