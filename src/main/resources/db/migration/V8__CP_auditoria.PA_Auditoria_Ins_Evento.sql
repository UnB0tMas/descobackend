IF OBJECT_ID(N'[auditoria].[PA_Auditoria_Ins_Evento]', N'P') IS NOT NULL
    DROP PROCEDURE [auditoria].[PA_Auditoria_Ins_Evento];
GO

/******************************************************************************************************
' Nombre del PA           : auditoria.PA_Auditoria_Ins_Evento
' Descripción             : Registra un evento de auditoría y el contexto de la operación.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [auditoria].[PA_Auditoria_Ins_Evento]
        @cAccion = 'CREAR',
        @cEsquemaEntidad = N'archivo',
        @cNombreEntidad = N'Archivo',
        @cIdentificador = N'1',
        @cResultado = 'EXITOSO',
        @nAuditoriaEventoId = @nAuditoriaEventoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nAuditoriaEventoId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [auditoria].[PA_Auditoria_Ins_Evento]
(
    @nUsuarioId                 BIGINT = NULL,
    @nSesionUsuarioId           BIGINT = NULL,
    @nDispositivoUsuarioId      BIGINT = NULL,
    @nModuloId                  INT = NULL,
    @cAccion                    VARCHAR(40),
    @cEsquemaEntidad            SYSNAME,
    @cNombreEntidad             SYSNAME,
    @cIdentificador             NVARCHAR(200),
    @cDatosAnteriores           NVARCHAR(MAX) = NULL,
    @cDatosPosteriores          NVARCHAR(MAX) = NULL,
    @cMotivo                    NVARCHAR(500) = NULL,
    @cIp                        VARCHAR(64) = NULL,
    @cDispositivo               NVARCHAR(200) = NULL,
    @cResultado                 VARCHAR(20) = NULL,
    @gCorrelacionId             UNIQUEIDENTIFIER = NULL,
    @gSolicitudId               UNIQUEIDENTIFIER = NULL,
    @cEndpoint                  NVARCHAR(250) = NULL,
    @nAuditoriaEventoId         BIGINT OUTPUT,
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

    SET @nAuditoriaEventoId = NULL;

    SET @cAccion = NULLIF(LTRIM(RTRIM(@cAccion)), '');
    SET @cEsquemaEntidad = NULLIF(LTRIM(RTRIM(@cEsquemaEntidad)), '');
    SET @cNombreEntidad = NULLIF(LTRIM(RTRIM(@cNombreEntidad)), '');
    SET @cIdentificador = NULLIF(LTRIM(RTRIM(@cIdentificador)), '');
    SET @cResultado = NULLIF(UPPER(LTRIM(RTRIM(@cResultado))), '');

    IF @cAccion IS NULL
       OR @cEsquemaEntidad IS NULL
       OR @cNombreEntidad IS NULL
       OR @cIdentificador IS NULL
    BEGIN
        THROW 52100, N'No se pudo registrar la trazabilidad de la operacion.', 1;
    END;

    IF @cResultado IS NOT NULL
       AND @cResultado NOT IN ('EXITOSO','RECHAZADO','ERROR_CONTROLADO')
    BEGIN
        SET @cResultado = 'ERROR_CONTROLADO';
    END;

    IF @cDatosAnteriores IS NOT NULL
       AND ISJSON(@cDatosAnteriores) <> 1
    BEGIN
        SET @cDatosAnteriores = NULL;
    END;

    IF @cDatosPosteriores IS NOT NULL
       AND ISJSON(@cDatosPosteriores) <> 1
    BEGIN
        SET @cDatosPosteriores = NULL;
    END;

    /*
       Defensa adicional:
       para entidades de autenticacion nunca se persiste payload antes/despues.
       La trazabilidad conserva evento, actor, fecha, resultado y contexto.
    */
    IF LOWER(@cEsquemaEntidad) = N'seg'
       AND LOWER(@cNombreEntidad) IN
       (
           N'usuario',
           N'codigounsolouso',
           N'refreshtokensesion',
           N'tokenaccesorevocado',
           N'historialpassword',
           N'sesionusuario'
       )
    BEGIN
        SET @cDatosAnteriores = NULL;
        SET @cDatosPosteriores = NULL;
    END;

    INSERT INTO [auditoria].[AuditoriaEvento]
    (
        [usuario_id],
        [modulo_id],
        [fecha_hora],
        [accion],
        [esquema_entidad],
        [nombre_entidad],
        [identificador],
        [datos_anteriores],
        [datos_posteriores],
        [motivo],
        [ip],
        [dispositivo],
        [estado],
        [sesion_usuario_id],
        [dispositivo_usuario_id],
        [correlacion_id],
        [solicitud_id],
        [resultado],
        [endpoint]
    )
    VALUES
    (
        @nUsuarioId,
        @nModuloId,
        SYSUTCDATETIME(),
        @cAccion,
        @cEsquemaEntidad,
        @cNombreEntidad,
        @cIdentificador,
        @cDatosAnteriores,
        @cDatosPosteriores,
        @cMotivo,
        NULLIF(LTRIM(RTRIM(@cIp)), ''),
        @cDispositivo,
        1,
        @nSesionUsuarioId,
        @nDispositivoUsuarioId,
        @gCorrelacionId,
        @gSolicitudId,
        @cResultado,
        @cEndpoint
    );

    SET @nAuditoriaEventoId = SCOPE_IDENTITY();

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
    @cProcedimiento = N'auditoria.PA_Auditoria_Ins_Evento',
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
    @cProcedimiento = N'auditoria.PA_Auditoria_Ins_Evento',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 AND @nAuditoriaEventoId IS NOT NULL THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'auditoria.PA_Auditoria_Ins_Evento',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
