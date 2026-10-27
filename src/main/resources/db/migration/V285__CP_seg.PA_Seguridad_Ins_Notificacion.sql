IF OBJECT_ID(N'[seg].[PA_Seguridad_Ins_Notificacion]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Seguridad_Ins_Notificacion];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Seguridad_Ins_Notificacion
' Descripción             : Registra una notificación de seguridad.
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
    DECLARE
        @nNotificacionSeguridadId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Seguridad_Ins_Notificacion]
        @nUsuarioId = 0,
        @cTipoNotificacion = '',
        @cCorreoDestino = N'',
        @cMetadata = N'',
        @gCorrelacionId = '00000000-0000-0000-0000-000000000001',
        @nNotificacionSeguridadId = @nNotificacionSeguridadId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nNotificacionSeguridadId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Seguridad_Ins_Notificacion]
(
    @nUsuarioId                 BIGINT,
    @cTipoNotificacion          VARCHAR(35),
    @cCorreoDestino             NVARCHAR(320),
    @cMetadata                  NVARCHAR(MAX) = NULL,
    @gCorrelacionId             UNIQUEIDENTIFIER = NULL,
    @nNotificacionSeguridadId   BIGINT OUTPUT,
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

    SET @nNotificacionSeguridadId = NULL;

    SET @cTipoNotificacion = UPPER(NULLIF(LTRIM(RTRIM(@cTipoNotificacion)), ''));
    SET @cCorreoDestino = NULLIF(LTRIM(RTRIM(@cCorreoDestino)), '');

    IF @nUsuarioId IS NULL
       OR @cTipoNotificacion IS NULL
       OR @cCorreoDestino IS NULL
       OR @cTipoNotificacion NOT IN
       (
           'VALIDACION_CORREO',
           'RECUPERACION_PASSWORD',
           'SEGUNDO_FACTOR',
           'NUEVO_DISPOSITIVO',
           'CAMBIO_PASSWORD',
           'CAMBIO_CORREO'
       )
    BEGIN
        THROW 52200, N'No se pudo registrar la notificacion de seguridad.', 1;
    END;

    IF @cMetadata IS NOT NULL AND ISJSON(@cMetadata) <> 1
    BEGIN
        SET @cMetadata = NULL;
    END;

    /*
       Los tres tipos con codigo nunca guardan metadata que pueda terminar
       conteniendo el OTP por error. El codigo vive solo en memoria del backend.
    */
    IF @cTipoNotificacion IN
       ('VALIDACION_CORREO','RECUPERACION_PASSWORD','SEGUNDO_FACTOR')
    BEGIN
        SET @cMetadata = NULL;
    END;

    IF @gCorrelacionId IS NULL
        SET @gCorrelacionId = NEWID();

    INSERT INTO [seg].[NotificacionSeguridad]
    (
        usuario_id,
        tipo_notificacion,
        correo_destino,
        fecha_creacion,
        cantidad_intentos,
        estado_envio,
        correlacion_id,
        metadata,
        estado
    )
    VALUES
    (
        @nUsuarioId,
        @cTipoNotificacion,
        @cCorreoDestino,
        SYSUTCDATETIME(),
        0,
        'PENDIENTE',
        @gCorrelacionId,
        @cMetadata,
        1
    );

    SET @nNotificacionSeguridadId = SCOPE_IDENTITY();

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
    @cProcedimiento = N'seg.PA_Seguridad_Ins_Notificacion',
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
    @cProcedimiento = N'seg.PA_Seguridad_Ins_Notificacion',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
SET @bResultado=0; SET @cMensaje=@__DbMensaje;
END CATCH;
SET @bResultado=CASE WHEN @__DbError=0 AND @nNotificacionSeguridadId IS NOT NULL THEN 1 ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Seguridad_Ins_Notificacion',@bResultado,@cMensaje) R;
IF @bResultado=0 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
