IF OBJECT_ID(N'[seg].[PA_Usuario_Ins_SolicitarCambioCorreo]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Ins_SolicitarCambioCorreo];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Ins_SolicitarCambioCorreo
' Descripción             : Registra una solicitud de cambio de correo del usuario.
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
        @nUsuarioCorreoSeguridadId BIGINT,
        @nCodigoUnSoloUsoId BIGINT,
        @nNotificacionSeguridadId BIGINT,
        @cCorreoDestino NVARCHAR(320),
        @bDebeEnviar BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Usuario_Ins_SolicitarCambioCorreo]
        @cJson = N'{}',
        @nUsuarioCorreoSeguridadId = @nUsuarioCorreoSeguridadId OUTPUT,
        @nCodigoUnSoloUsoId = @nCodigoUnSoloUsoId OUTPUT,
        @nNotificacionSeguridadId = @nNotificacionSeguridadId OUTPUT,
        @cCorreoDestino = @cCorreoDestino OUTPUT,
        @bDebeEnviar = @bDebeEnviar OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nUsuarioCorreoSeguridadId, @nCodigoUnSoloUsoId, @nNotificacionSeguridadId, @cCorreoDestino, @bDebeEnviar, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Ins_SolicitarCambioCorreo]
(
    @cJson                       NVARCHAR(MAX),
    @nUsuarioCorreoSeguridadId  BIGINT OUTPUT,
    @nCodigoUnSoloUsoId         BIGINT OUTPUT,
    @nNotificacionSeguridadId   BIGINT OUTPUT,
    @cCorreoDestino             NVARCHAR(320) OUTPUT,
    @bDebeEnviar                BIT OUTPUT,
    @bResultado                 BIT OUTPUT,
    @cMensaje                   NVARCHAR(300) OUTPUT,
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

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @nUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @nSesionId BIGINT,
        @cNuevoCorreo NVARCHAR(320),
        @cCorreoNormalizado NVARCHAR(320),
        @cCodigoHmacHex VARCHAR(128),
        @binCodigoHmac VARBINARY(64),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @bInterno BIT,
        @cMensajeInterno NVARCHAR(300);

    SET @nUsuarioCorreoSeguridadId = NULL;
    SET @nCodigoUnSoloUsoId = NULL;
    SET @nNotificacionSeguridadId = NULL;
    SET @cCorreoDestino = NULL;
    SET @bDebeEnviar = 0;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo solicitar el cambio de correo.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId,
        @cNuevoCorreo = NULLIF(LTRIM(RTRIM(nuevoCorreo)), ''),
        @cCodigoHmacHex = NULLIF(LTRIM(RTRIM(codigoHmacHex)), ''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        nuevoCorreo NVARCHAR(320) '$.nuevoCorreo',
        codigoHmacHex VARCHAR(128) '$.codigoHmacHex',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binCodigoHmac = TRY_CONVERT(VARBINARY(64), @cCodigoHmacHex, 2);
    SET @cCorreoNormalizado = LOWER(@cNuevoCorreo);

    IF @nUsuarioId IS NULL
       OR @gSesionPublicaId IS NULL
       OR @cNuevoCorreo IS NULL
       OR @binCodigoHmac IS NULL
       OR LEN(@cNuevoCorreo) > 320
       OR CHARINDEX(N'@', @cNuevoCorreo) <= 1
    BEGIN
        SET @cMensaje = N'Ingrese un correo valido.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nSesionId = S.sesion_usuario_id
    FROM [seg].[SesionUsuario] S
    INNER JOIN [seg].[Usuario] U ON U.usuario_id = S.usuario_id
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.usuario_id = @nUsuarioId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > @dAhora
      AND S.token_version = U.token_version
      AND U.estado = 1
      AND U.estado_cuenta = 'ACTIVA';

    IF @nSesionId IS NULL
    BEGIN
        SET @cMensaje = N'La sesion no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [seg].[UsuarioCorreoSeguridad]
        WHERE usuario_id = @nUsuarioId
          AND estado = 1
          AND es_principal = 1
          AND correo_normalizado = @cCorreoNormalizado
          AND fecha_hasta IS NULL
    )
    BEGIN
        SET @cMensaje = N'El correo ingresado ya es su correo de seguridad actual.';
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        /*
           Cierra solicitudes anteriores de cambio que aun no llegaron a ser
           principales ni verificadas.
        */
        UPDATE [seg].[UsuarioCorreoSeguridad]
        SET
            fecha_hasta = COALESCE(fecha_hasta, @dAhora),
            motivo_cambio = COALESCE(motivo_cambio, N'Solicitud de cambio reemplazada.'),
            estado = 0
        WHERE usuario_id = @nUsuarioId
          AND estado = 1
          AND es_principal = 0
          AND es_verificado = 0
          AND fecha_hasta IS NULL;

        INSERT INTO [seg].[UsuarioCorreoSeguridad]
        (
            usuario_id,
            correo,
            correo_normalizado,
            es_principal,
            es_verificado,
            fecha_desde,
            creado_por_usuario_id,
            motivo_cambio,
            estado
        )
        VALUES
        (
            @nUsuarioId,
            @cNuevoCorreo,
            @cCorreoNormalizado,
            0,
            0,
            @dAhora,
            @nUsuarioId,
            N'Solicitud de cambio de correo.',
            1
        );

        SET @nUsuarioCorreoSeguridadId = SCOPE_IDENTITY();

        EXEC [seg].[PA_Seguridad_Ins_CodigoUnSoloUso]
             @nUsuarioId = @nUsuarioId,
             @cProposito = 'CAMBIO_CORREO',
             @binCodigoHmac = @binCodigoHmac,
             @nUsuarioCorreoSeguridadId = @nUsuarioCorreoSeguridadId,
             @cIp = @cIp,
             @gCorrelacionId = @gCorrelacionId,
             @nCodigoUnSoloUsoId = @nCodigoUnSoloUsoId OUTPUT,
             @nNotificacionSeguridadId = @nNotificacionSeguridadId OUTPUT,
             @cCorreoDestino = @cCorreoDestino OUTPUT,
             @bDebeEnviar = @bDebeEnviar OUTPUT,
             @bResultado = @bInterno OUTPUT,
             @cMensaje = @cMensajeInterno OUTPUT;

        IF @bInterno = 0
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

            SET @nUsuarioCorreoSeguridadId = NULL;
            SET @nCodigoUnSoloUsoId = NULL;
            SET @nNotificacionSeguridadId = NULL;
            SET @cCorreoDestino = NULL;
            SET @bDebeEnviar = 0;
            SET @cMensaje = @cMensajeInterno;
            GOTO __DESCO_Salida;
        END;

        BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @bResultado = 1;
        SET @cMensaje = N'Revise el nuevo correo para confirmar el cambio.';
    END TRY
    BEGIN CATCH
SET @bResultado = 0;

        IF XACT_STATE() <> 0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @nUsuarioCorreoSeguridadId = NULL;
        SET @nCodigoUnSoloUsoId = NULL;
        SET @nNotificacionSeguridadId = NULL;
        SET @cCorreoDestino = NULL;
        SET @bDebeEnviar = 0;
        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo solicitar el cambio de correo. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarCambioCorreo',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;

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
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarCambioCorreo',
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
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarCambioCorreo',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Ins_SolicitarCambioCorreo',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
