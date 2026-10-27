IF OBJECT_ID(N'[seg].[PA_Usuario_Ins_SolicitarRecuperacionPassword]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Ins_SolicitarRecuperacionPassword];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Ins_SolicitarRecuperacionPassword
' Descripción             : Registra una solicitud de recuperación de contraseña.
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
        @nCodigoUnSoloUsoId BIGINT,
        @nNotificacionSeguridadId BIGINT,
        @cCorreoDestino NVARCHAR(320),
        @bDebeEnviar BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Usuario_Ins_SolicitarRecuperacionPassword]
        @cJson = N'{}',
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
CREATE PROCEDURE [seg].[PA_Usuario_Ins_SolicitarRecuperacionPassword]
(
    @cJson                       NVARCHAR(MAX),
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

    BEGIN TRY

    SET NOCOUNT ON;

    DECLARE
        @nUsuarioIdSolicitado BIGINT,
        @cNombreUsuario VARCHAR(80),
        @nUsuarioId BIGINT,
        @cCodigoHmacHex VARCHAR(128),
        @binCodigoHmac VARBINARY(64),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @bInterno BIT,
        @cMensajeInterno NVARCHAR(300),
        @nAuditoriaId BIGINT;

    SET @nCodigoUnSoloUsoId = NULL;
    SET @nNotificacionSeguridadId = NULL;
    SET @cCorreoDestino = NULL;
    SET @bDebeEnviar = 0;

    /*
       La respuesta funcional sigue considerándose procesada aun cuando la
       cuenta no exista. El application service conserva el mensaje público
       genérico y no expone estos detalles al cliente.
    */
    SET @bResultado = 1;
    SET @cMensaje =
        N'Si la cuenta esta disponible, recibira instrucciones en su correo de seguridad.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje =
            N'RECOVERY_NO_DISPATCH: payload interno no valido.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioIdSolicitado = usuarioId,
        @cNombreUsuario =
            NULLIF(LTRIM(RTRIM(nombreUsuario)), ''),
        @cCodigoHmacHex =
            NULLIF(LTRIM(RTRIM(codigoHmacHex)), ''),
        @cIp =
            NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        nombreUsuario VARCHAR(80) '$.nombreUsuario',
        codigoHmacHex VARCHAR(128) '$.codigoHmacHex',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binCodigoHmac =
        TRY_CONVERT(
            VARBINARY(64),
            @cCodigoHmacHex,
            2
        );

    IF @cNombreUsuario IS NULL
       OR @binCodigoHmac IS NULL
    BEGIN
        SET @cMensaje =
            N'RECOVERY_NO_DISPATCH: username u HMAC interno no valido.';
        GOTO __DESCO_Salida;
    END;

    /*
       Primero se usa el usuario ya resuelto por el backend mediante
       findCredential(). Esto evita duplicar una segunda resolución diferente
       a la utilizada por login.

       Si no vino usuarioId se conserva compatibilidad con clientes anteriores
       y se resuelve por username.
    */
    /*
       IMPORTANTE:
       AND tiene mayor precedencia que OR. Se agrupa expresamente toda la
       condición de resolución para que los filtros de estado apliquen tanto
       al usuarioId como al fallback por username.
    */
    SELECT TOP (1)
        @nUsuarioId = U.usuario_id
    FROM [seg].[Usuario] U
    INNER JOIN [org].[Empleado] E
        ON E.empleado_id = U.persona_id
    INNER JOIN [org].[Persona] P
        ON P.persona_id = U.persona_id
    WHERE
        (
            (
                @nUsuarioIdSolicitado IS NOT NULL
                AND U.usuario_id = @nUsuarioIdSolicitado
            )
            OR
            (
                @nUsuarioIdSolicitado IS NULL
                AND U.nombre_usuario = @cNombreUsuario
            )
        )
      AND U.estado = 1
      AND U.estado_cuenta NOT IN
          ('RETIRADA', 'DESHABILITADA')
      AND E.estado = 1
      AND P.estado = 1
      AND EXISTS
      (
          SELECT 1
          FROM [seg].[UsuarioCorreoSeguridad] UCS
          WHERE UCS.usuario_id = U.usuario_id
            AND UCS.estado = 1
            AND UCS.es_principal = 1
            AND UCS.es_verificado = 1
            AND UCS.fecha_hasta IS NULL
      )
    ORDER BY U.usuario_id;

    IF @nUsuarioId IS NULL
    BEGIN
        SET @cMensaje =
            N'RECOVERY_NO_DISPATCH: cuenta no elegible o correo principal no verificado.';
        GOTO __DESCO_Salida;
    END;

    BEGIN TRY
        BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;

        EXEC [seg].[PA_Seguridad_Ins_CodigoUnSoloUso]
             @nUsuarioId = @nUsuarioId,
             @cProposito = 'RECUPERACION_PASSWORD',
             @binCodigoHmac = @binCodigoHmac,
             @cIp = @cIp,
             @gCorrelacionId = @gCorrelacionId,
             @nCodigoUnSoloUsoId =
                 @nCodigoUnSoloUsoId OUTPUT,
             @nNotificacionSeguridadId =
                 @nNotificacionSeguridadId OUTPUT,
             @cCorreoDestino =
                 @cCorreoDestino OUTPUT,
             @bDebeEnviar =
                 @bDebeEnviar OUTPUT,
             @bResultado =
                 @bInterno OUTPUT,
             @cMensaje =
                 @cMensajeInterno OUTPUT;

        IF ISNULL(@bInterno, 0) = 0
        BEGIN
            /*
               Normalmente cooldown/política/correo. No se expone al frontend,
               pero el backend puede verlo en consola.
            */
            IF XACT_STATE() = 1
                BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
            ELSE IF XACT_STATE() = -1
                BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

            SET @nCodigoUnSoloUsoId = NULL;
            SET @nNotificacionSeguridadId = NULL;
            SET @cCorreoDestino = NULL;
            SET @bDebeEnviar = 0;
            SET @bResultado = 1;
            SET @cMensaje =
                COALESCE(
                    @cMensajeInterno,
                    N'RECOVERY_NO_DISPATCH: el generador interno no autorizo el envio.'
                );
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
        SET @cMensaje =
            N'Codigo de recuperacion generado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;

        SET @nCodigoUnSoloUsoId = NULL;
        SET @nNotificacionSeguridadId = NULL;
        SET @cCorreoDestino = NULL;
        SET @bDebeEnviar = 0;
        SET @bResultado=0;
        SET @cMensaje =
            CONCAT(
                N'RECOVERY_INTERNAL_ERROR_SQL_',
                ERROR_NUMBER()
            );
        
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarRecuperacionPassword',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
END;
GOTO __DESCO_Salida;
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarRecuperacionPassword',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
END;
END CATCH;

    /*
       La auditoría de la SOLICITUD ya no participa en la transacción de
       emisión. Si la trazabilidad falla, no se revierte un OTP/notificación
       que ya fueron generados correctamente.
    */
    BEGIN TRY
        EXEC [auditoria].[PA_Auditoria_Ins_Evento]
             @nUsuarioId = @nUsuarioId,
             @cAccion = 'SOLICITAR_RECUPERACION',
             @cEsquemaEntidad = N'seg',
             @cNombreEntidad = N'Usuario',
             @cIdentificador = @nUsuarioId,
             @cMotivo =
                 N'Solicitud de recuperacion de cuenta.',
             @cIp = @cIp,
             @cResultado = 'EXITOSO',
             @gCorrelacionId = @gCorrelacionId,
             @cEndpoint =
                 N'/api/v1/auth/password-recovery/request',
             @nAuditoriaEventoId =
                 @nAuditoriaId OUTPUT;
    END TRY
    BEGIN CATCH
        /*
           Best effort: un fallo de auditoría no invalida el código ya emitido.
           No se cambia @bDebeEnviar ni los IDs.
        */
        SET @nAuditoriaId = NULL;
    
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarRecuperacionPassword',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
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
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarRecuperacionPassword',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
SET @bResultado=0;
SET @bDebeEnviar = 0;
SET @nCodigoUnSoloUsoId = NULL;
SET @nNotificacionSeguridadId = NULL;
SET @cCorreoDestino = NULL;
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
SET @cMensaje = N'Si la cuenta está disponible, recibirá instrucciones en su correo de seguridad.';

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
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarRecuperacionPassword',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
SET @bResultado=0;
SET @bDebeEnviar = 0;
SET @nCodigoUnSoloUsoId = NULL;
SET @nNotificacionSeguridadId = NULL;
SET @cCorreoDestino = NULL;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
IF XACT_STATE()=-1 SELECT @bDebeEnviar=0,@nCodigoUnSoloUsoId=NULL,@nNotificacionSeguridadId=NULL,@cCorreoDestino=NULL;
SET @bResultado=1;
 SET @cMensaje=N'Si la cuenta está disponible, recibirá instrucciones en su correo de seguridad.';
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Ins_SolicitarRecuperacionPassword',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
