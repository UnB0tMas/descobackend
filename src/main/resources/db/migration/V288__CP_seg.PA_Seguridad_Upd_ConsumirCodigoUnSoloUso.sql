IF OBJECT_ID(N'[seg].[PA_Seguridad_Upd_ConsumirCodigoUnSoloUso]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Seguridad_Upd_ConsumirCodigoUnSoloUso];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Seguridad_Upd_ConsumirCodigoUnSoloUso
' Descripción             : Consume y valida un código de seguridad de un solo uso.
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
        @nUsuarioCorreoSeguridadId BIGINT,
        @bCodigoValido BIT,
        @cMensaje NVARCHAR(300),
        @bResultado BIT,
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Seguridad_Upd_ConsumirCodigoUnSoloUso]
        @nUsuarioId = 0,
        @cProposito = '',
        @binCodigoHmac = 0x,
        @cIp = '',
        @gCorrelacionId = '00000000-0000-0000-0000-000000000001',
        @nCodigoUnSoloUsoId = @nCodigoUnSoloUsoId OUTPUT,
        @nUsuarioCorreoSeguridadId = @nUsuarioCorreoSeguridadId OUTPUT,
        @bCodigoValido = @bCodigoValido OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nCodigoUnSoloUsoId, @nUsuarioCorreoSeguridadId, @bCodigoValido, @cMensaje, @bResultado, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Seguridad_Upd_ConsumirCodigoUnSoloUso]
(
    @nUsuarioId                   BIGINT,
    @cProposito                   VARCHAR(35),
    @binCodigoHmac                VARBINARY(64),
    @cIp                          VARCHAR(64) = NULL,
    @gCorrelacionId               UNIQUEIDENTIFIER = NULL,
    @nCodigoUnSoloUsoId           BIGINT OUTPUT,
    @nUsuarioCorreoSeguridadId    BIGINT OUTPUT,
    @bCodigoValido                BIT OUTPUT,
    @cMensaje                     NVARCHAR(300) OUTPUT,
    @bResultado BIT=NULL OUTPUT,
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
    SET @bCodigoValido = 0;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    SET @bResultado=0;
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
        @binHmacEsperado VARBINARY(64),
        @dExpiracion DATETIME2(0),
        @dUso DATETIME2(0),
        @dInvalidacion DATETIME2(0),
        @nIntentos SMALLINT,
        @nMaxIntentos SMALLINT,
        @gGrupoSolicitud UNIQUEIDENTIFIER,
        @nDispositivoUsuarioId BIGINT,
        @nAuditoriaId BIGINT;

    SET @nCodigoUnSoloUsoId = NULL;
    SET @nUsuarioCorreoSeguridadId = NULL;
    SET @bCodigoValido = 0;
    SET @cMensaje = N'El codigo ingresado no es valido o ha expirado.';

    SET @cProposito = UPPER(NULLIF(LTRIM(RTRIM(@cProposito)), ''));

    IF @nUsuarioId IS NULL
       OR @binCodigoHmac IS NULL
       OR @cProposito NOT IN
          ('VALIDACION_CORREO','RECUPERACION_PASSWORD','SEGUNDO_FACTOR','CAMBIO_CORREO')
    BEGIN
        GOTO __DESCO_Salida;
    END;

    SELECT TOP (1)
        @nCodigoUnSoloUsoId = C.codigo_un_solo_uso_id,
        @nUsuarioCorreoSeguridadId = C.usuario_correo_seguridad_id,
        @binHmacEsperado = C.codigo_hmac,
        @dExpiracion = C.fecha_expiracion,
        @dUso = C.fecha_uso,
        @dInvalidacion = C.fecha_invalidacion,
        @nIntentos = C.intentos_fallidos,
        @nMaxIntentos = C.maximo_intentos,
        @gGrupoSolicitud = C.grupo_solicitud,
        @nDispositivoUsuarioId = C.dispositivo_usuario_id
    FROM [seg].[CodigoUnSoloUso] C WITH (UPDLOCK, HOLDLOCK)
    WHERE C.usuario_id = @nUsuarioId
      AND C.proposito = @cProposito
      AND C.estado = 1
    ORDER BY C.fecha_creacion DESC, C.codigo_un_solo_uso_id DESC;

    SET @gCorrelacionId = COALESCE(@gCorrelacionId, @gGrupoSolicitud, NEWID());

    IF @nCodigoUnSoloUsoId IS NULL
    BEGIN
        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @cAccion = 'VALIDAR_CODIGO_SEGURIDAD',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'CodigoUnSoloUso',
             @cIdentificador = N'NO_DISPONIBLE',
             @cMotivo = @cProposito,
             @cIp = @cIp,
             @cResultado = 'RECHAZADO',
             @gCorrelacionId = @gCorrelacionId,
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;
        GOTO __DESCO_Salida;
    END;

    IF @dUso IS NOT NULL
       OR @dInvalidacion IS NOT NULL
       OR @dExpiracion <= @dAhora
       OR @nIntentos >= @nMaxIntentos
    BEGIN
        UPDATE [seg].[CodigoUnSoloUso]
        SET
            fecha_invalidacion =
                CASE WHEN fecha_uso IS NULL
                     THEN COALESCE(fecha_invalidacion, @dAhora)
                     ELSE fecha_invalidacion END,
            estado = 0
        WHERE codigo_un_solo_uso_id = @nCodigoUnSoloUsoId;

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @nDispositivoUsuarioId = @nDispositivoUsuarioId,
             @cAccion = 'VALIDAR_CODIGO_SEGURIDAD',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'CodigoUnSoloUso',
             @cIdentificador = @nCodigoUnSoloUsoId,
             @cMotivo = @cProposito,
             @cIp = @cIp,
             @cResultado = 'RECHAZADO',
             @gCorrelacionId = @gCorrelacionId,
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;
        GOTO __DESCO_Salida;
    END;

    IF @binHmacEsperado <> @binCodigoHmac
    BEGIN
        UPDATE [seg].[CodigoUnSoloUso]
        SET
            intentos_fallidos =
                CASE
                    WHEN intentos_fallidos + 1 > maximo_intentos
                        THEN maximo_intentos
                    ELSE intentos_fallidos + 1
                END,
            fecha_invalidacion =
                CASE
                    WHEN intentos_fallidos + 1 >= maximo_intentos
                        THEN @dAhora
                    ELSE fecha_invalidacion
                END,
            estado =
                CASE
                    WHEN intentos_fallidos + 1 >= maximo_intentos
                        THEN 0
                    ELSE estado
                END
        WHERE codigo_un_solo_uso_id = @nCodigoUnSoloUsoId;

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @nDispositivoUsuarioId = @nDispositivoUsuarioId,
             @cAccion = 'VALIDAR_CODIGO_SEGURIDAD',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'CodigoUnSoloUso',
             @cIdentificador = @nCodigoUnSoloUsoId,
             @cMotivo = @cProposito,
             @cIp = @cIp,
             @cResultado = 'RECHAZADO',
             @gCorrelacionId = @gCorrelacionId,
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;
        GOTO __DESCO_Salida;
    END;

    UPDATE [seg].[CodigoUnSoloUso]
    SET
        fecha_uso = @dAhora,
        estado = 0
    WHERE codigo_un_solo_uso_id = @nCodigoUnSoloUsoId
      AND estado = 1
      AND fecha_uso IS NULL
      AND fecha_invalidacion IS NULL
      AND fecha_expiracion > @dAhora;

    IF @@ROWCOUNT = 1
    BEGIN
        SET @bCodigoValido = 1;
        SET @cMensaje = N'Codigo validado correctamente.';

        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @nDispositivoUsuarioId = @nDispositivoUsuarioId,
             @cAccion = 'VALIDAR_CODIGO_SEGURIDAD',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'CodigoUnSoloUso',
             @cIdentificador = @nCodigoUnSoloUsoId,
             @cMotivo = @cProposito,
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @nAuditoriaEventoId = @nAuditoriaId OUTPUT;
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
SET @bCodigoValido = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Seguridad_Upd_ConsumirCodigoUnSoloUso',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
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
SET @bCodigoValido = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Seguridad_Upd_ConsumirCodigoUnSoloUso',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bCodigoValido,0) = 1
BEGIN
SET @bCodigoValido = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=CASE WHEN @__DbError=0 THEN ISNULL(@bCodigoValido,0) ELSE 0 END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Seguridad_Upd_ConsumirCodigoUnSoloUso',@bResultado,@cMensaje) R;
IF @__DbError=1 AND @@NESTLEVEL>1 THROW 51000,@cMensaje,1;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
