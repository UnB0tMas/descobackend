IF OBJECT_ID(N'[seg].[PA_Seguridad_Ins_CodigoUnSoloUso]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Seguridad_Ins_CodigoUnSoloUso];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Seguridad_Ins_CodigoUnSoloUso
' Descripción             : Registra un código de seguridad de un solo uso.
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
        @nCodigoUnSoloUsoId BIGINT,
        @nNotificacionSeguridadId BIGINT,
        @cCorreoDestino NVARCHAR(320),
        @bDebeEnviar BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Seguridad_Ins_CodigoUnSoloUso]
        @nUsuarioId = 0,
        @cProposito = '',
        @binCodigoHmac = 0x,
        @nDispositivoUsuarioId = 0,
        @nUsuarioCorreoSeguridadId = 0,
        @cIp = '',
        @gCorrelacionId = '00000000-0000-0000-0000-000000000001',
        @nCodigoUnSoloUsoId = @nCodigoUnSoloUsoId OUTPUT,
        @nNotificacionSeguridadId = @nNotificacionSeguridadId OUTPUT,
        @cCorreoDestino = @cCorreoDestino OUTPUT,
        @bDebeEnviar = @bDebeEnviar OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nCodigoUnSoloUsoId, @nNotificacionSeguridadId, @cCorreoDestino, @bDebeEnviar, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Seguridad_Ins_CodigoUnSoloUso]
(
    @nUsuarioId                   BIGINT,
    @cProposito                   VARCHAR(35),
    @binCodigoHmac                VARBINARY(64),
    @nDispositivoUsuarioId        BIGINT = NULL,
    @nUsuarioCorreoSeguridadId    BIGINT = NULL,
    @cIp                          VARCHAR(64) = NULL,
    @gCorrelacionId               UNIQUEIDENTIFIER = NULL,
    @nCodigoUnSoloUsoId           BIGINT OUTPUT,
    @nNotificacionSeguridadId     BIGINT OUTPUT,
    @cCorreoDestino               NVARCHAR(320) OUTPUT,
    @bDebeEnviar                  BIT OUTPUT,
    @bResultado                   BIT OUTPUT,
    @cMensaje                     NVARCHAR(300) OUTPUT,
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
BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;

    DECLARE
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nMaxIntentos SMALLINT,
        @nSegundosReenvio SMALLINT,
        @nMinutosExpiracion SMALLINT,
        @dUltimaCreacion DATETIME2(0),
        @nCorreoId BIGINT,
        @bCorreoVerificado BIT,
        @nAuditoriaId BIGINT;

    SET @nCodigoUnSoloUsoId = NULL;
    SET @nNotificacionSeguridadId = NULL;
    SET @cCorreoDestino = NULL;
    SET @bDebeEnviar = 0;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo generar el codigo de seguridad.';

    SET @cProposito = UPPER(NULLIF(LTRIM(RTRIM(@cProposito)), ''));
    IF @gCorrelacionId IS NULL SET @gCorrelacionId = NEWID();

    IF @nUsuarioId IS NULL
       OR @binCodigoHmac IS NULL
       OR @cProposito NOT IN
          ('VALIDACION_CORREO','RECUPERACION_PASSWORD','SEGUNDO_FACTOR','CAMBIO_CORREO')
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT TOP (1)
        @nMaxIntentos = PS.max_intentos_codigo,
        @nSegundosReenvio = PS.segundos_minimos_reenvio,
        @nMinutosExpiracion =
            CASE @cProposito
                WHEN 'VALIDACION_CORREO' THEN PS.minutos_expiracion_validacion
                WHEN 'RECUPERACION_PASSWORD' THEN PS.minutos_expiracion_recuperacion
                WHEN 'SEGUNDO_FACTOR' THEN PS.minutos_expiracion_segundo_factor
                WHEN 'CAMBIO_CORREO' THEN PS.minutos_expiracion_validacion
            END
    FROM [seg].[PoliticaSeguridad] PS
    WHERE PS.codigo = 'GENERAL'
      AND PS.estado = 1
      AND PS.fecha_hasta IS NULL
      AND PS.fecha_desde <= @dAhora
    ORDER BY PS.fecha_desde DESC;

    IF @nMaxIntentos IS NULL
    BEGIN
        SET @cMensaje = N'La politica de seguridad no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    IF @cProposito = 'CAMBIO_CORREO'
       AND @nUsuarioCorreoSeguridadId IS NOT NULL
    BEGIN
        SELECT
            @nCorreoId = UCS.usuario_correo_seguridad_id,
            @cCorreoDestino = UCS.correo,
            @bCorreoVerificado = UCS.es_verificado
        FROM [seg].[UsuarioCorreoSeguridad] UCS
        WHERE UCS.usuario_correo_seguridad_id = @nUsuarioCorreoSeguridadId
          AND UCS.usuario_id = @nUsuarioId
          AND UCS.estado = 1;
    END
    ELSE
    BEGIN
        SELECT TOP (1)
            @nCorreoId = UCS.usuario_correo_seguridad_id,
            @cCorreoDestino = UCS.correo,
            @bCorreoVerificado = UCS.es_verificado
        FROM [seg].[UsuarioCorreoSeguridad] UCS
        WHERE UCS.usuario_id = @nUsuarioId
          AND UCS.estado = 1
          AND UCS.es_principal = 1
          AND UCS.fecha_hasta IS NULL
        ORDER BY UCS.fecha_desde DESC;
    END;

    IF @nCorreoId IS NULL OR @cCorreoDestino IS NULL
    BEGIN
        SET @cMensaje = N'No hay un correo de seguridad disponible.';
        GOTO __DESCO_Salida;
    END;

    IF @cProposito IN ('RECUPERACION_PASSWORD','SEGUNDO_FACTOR')
       AND ISNULL(@bCorreoVerificado, 0) = 0
    BEGIN
        SET @cMensaje = N'El correo de seguridad aun no ha sido validado.';
        GOTO __DESCO_Salida;
    END;

    SELECT TOP (1)
        @dUltimaCreacion = C.fecha_creacion
    FROM [seg].[CodigoUnSoloUso] C WITH (UPDLOCK, HOLDLOCK)
    WHERE C.usuario_id = @nUsuarioId
      AND C.proposito = @cProposito
      AND C.estado = 1
      AND C.fecha_uso IS NULL
      AND C.fecha_invalidacion IS NULL
    ORDER BY C.fecha_creacion DESC, C.codigo_un_solo_uso_id DESC;

    IF @dUltimaCreacion IS NOT NULL
       AND DATEDIFF(SECOND, @dUltimaCreacion, @dAhora) < @nSegundosReenvio
    BEGIN
        SET @cMensaje = N'Espere unos segundos antes de solicitar un nuevo codigo.';
        GOTO __DESCO_Salida;
    END;

    /* Solicitar uno nuevo invalida todos los anteriores del mismo proposito. */
    UPDATE [seg].[CodigoUnSoloUso]
    SET
        fecha_invalidacion = COALESCE(fecha_invalidacion, @dAhora),
        estado = 0
    WHERE usuario_id = @nUsuarioId
      AND proposito = @cProposito
      AND estado = 1
      AND fecha_uso IS NULL
      AND fecha_invalidacion IS NULL;

    INSERT INTO [seg].[CodigoUnSoloUso]
    (
        usuario_id,
        usuario_correo_seguridad_id,
        dispositivo_usuario_id,
        proposito,
        canal,
        codigo_hmac,
        correo_destino,
        fecha_creacion,
        fecha_expiracion,
        intentos_fallidos,
        maximo_intentos,
        ip_solicitud,
        grupo_solicitud,
        estado
    )
    VALUES
    (
        @nUsuarioId,
        @nCorreoId,
        @nDispositivoUsuarioId,
        @cProposito,
        'EMAIL',
        @binCodigoHmac,
        @cCorreoDestino,
        @dAhora,
        DATEADD(MINUTE, @nMinutosExpiracion, @dAhora),
        0,
        @nMaxIntentos,
        NULLIF(LTRIM(RTRIM(@cIp)), ''),
        @gCorrelacionId,
        1
    );

    SET @nCodigoUnSoloUsoId = CONVERT(BIGINT, SCOPE_IDENTITY());

    EXEC [seg].[PA_Seguridad_Ins_Notificacion]
         @nUsuarioId = @nUsuarioId,
         @cTipoNotificacion = @cProposito,
         @cCorreoDestino = @cCorreoDestino,
         @cMetadata = NULL,
         @gCorrelacionId = @gCorrelacionId,
         @nNotificacionSeguridadId = @nNotificacionSeguridadId OUTPUT;

    /*
       Se audita la EMISION, nunca el HMAC ni el OTP. El PA de auditoria
       elimina defensivamente cualquier payload de CodigoUnSoloUso.
    */
    EXEC [auditoria].[PA_Auditoria_Ins_Evento]
         @nUsuarioId = @nUsuarioId,
         @nDispositivoUsuarioId = @nDispositivoUsuarioId,
         @cAccion = 'EMITIR_CODIGO_SEGURIDAD',
         @cEsquemaEntidad = N'seg',
         @cNombreEntidad = N'CodigoUnSoloUso',
         @cIdentificador = @nCodigoUnSoloUsoId,
         @cMotivo = @cProposito,
         @cIp = @cIp,
         @cResultado = 'EXITOSO',
         @gCorrelacionId = @gCorrelacionId,
         @nAuditoriaEventoId = @nAuditoriaId OUTPUT;

    SET @bDebeEnviar = 1;
    SET @bResultado = 1;
    SET @cMensaje = N'Codigo de seguridad generado correctamente.';

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
    @cProcedimiento = N'seg.PA_Seguridad_Ins_CodigoUnSoloUso',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
    IF @__DbError = 0 AND @bResultado = 1 AND XACT_STATE() = 1
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
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Seguridad_Ins_CodigoUnSoloUso',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
IF ISNULL(@bResultado,0) = 0 SELECT @nCodigoUnSoloUsoId=NULL, @nNotificacionSeguridadId=NULL;
IF ISNULL(@bResultado,0) = 0 SELECT @bDebeEnviar=0,@cCorreoDestino=NULL;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Seguridad_Ins_CodigoUnSoloUso',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
