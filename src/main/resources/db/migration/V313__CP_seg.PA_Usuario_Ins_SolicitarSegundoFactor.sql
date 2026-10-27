IF OBJECT_ID(N'[seg].[PA_Usuario_Ins_SolicitarSegundoFactor]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Ins_SolicitarSegundoFactor];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Ins_SolicitarSegundoFactor
' Descripción             : Registra una solicitud de segundo factor de autenticación.
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
    EXEC [seg].[PA_Usuario_Ins_SolicitarSegundoFactor]
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
CREATE PROCEDURE [seg].[PA_Usuario_Ins_SolicitarSegundoFactor]
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

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @nUsuarioId BIGINT,
        @cCodigoHmacHex VARCHAR(128),
        @binCodigoHmac VARBINARY(64),
        @cIp VARCHAR(64),
        @gCorrelacionId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nMinutosPreAutenticacion SMALLINT,
        @bRequiere BIT = 0,
        @bInterno BIT,
        @cMensajeInterno NVARCHAR(300);

    SET @nCodigoUnSoloUsoId = NULL;
    SET @nNotificacionSeguridadId = NULL;
    SET @cCorreoDestino = NULL;
    SET @bDebeEnviar = 0;
    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo generar la verificacion adicional.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @cCodigoHmacHex = NULLIF(LTRIM(RTRIM(codigoHmacHex)), ''),
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @gCorrelacionId = correlacionId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        codigoHmacHex VARCHAR(128) '$.codigoHmacHex',
        ip VARCHAR(64) '$.ip',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId'
    );

    SET @binCodigoHmac = TRY_CONVERT(VARBINARY(64), @cCodigoHmacHex, 2);

    IF @nUsuarioId IS NULL
       OR @binCodigoHmac IS NULL
       OR @gCorrelacionId IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT TOP (1)
        @nMinutosPreAutenticacion = PS.minutos_expiracion_segundo_factor
    FROM [seg].[PoliticaSeguridad] PS
    WHERE PS.codigo = 'GENERAL'
      AND PS.estado = 1
      AND PS.fecha_hasta IS NULL
      AND PS.fecha_desde <= @dAhora
    ORDER BY PS.fecha_desde DESC;

    IF @nMinutosPreAutenticacion IS NULL
    BEGIN
        SET @cMensaje = N'No se pudo continuar con la verificacion adicional.';
        GOTO __DESCO_Salida;
    END;

    /*
       El segundo factor solo puede solicitarse como continuacion de una
       credencial Argon2 validada en el mismo flujo/correlacion.
    */
    IF NOT EXISTS
    (
        SELECT 1
        FROM [auditoria].[AuditoriaEvento] A
        WHERE A.usuario_id = @nUsuarioId
          AND A.accion = 'LOGIN_CREDENCIAL'
          AND A.resultado = 'EXITOSO'
          AND A.correlacion_id = @gCorrelacionId
          AND A.endpoint = N'/api/auth/login'
          AND A.estado = 1
          AND A.fecha_hora >= DATEADD(MINUTE, -@nMinutosPreAutenticacion, @dAhora)
    )
    BEGIN
        SET @cMensaje = N'La verificacion de acceso ya no esta disponible. Inicie sesion nuevamente.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @bRequiere =
            CASE
                WHEN U.segundo_factor_habilitado = 1 THEN 1
                WHEN EXISTS
                (
                    SELECT 1
                    FROM [seg].[UsuarioRol] UR
                    INNER JOIN [seg].[Rol] R ON R.rol_id = UR.rol_id
                    WHERE UR.usuario_id = U.usuario_id
                      AND UR.estado = 1
                      AND UR.fecha_desde <= @dAhora
                      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta >= @dAhora)
                      AND R.estado = 1
                      AND R.requiere_segundo_factor = 1
                ) THEN 1
                ELSE 0
            END
    FROM [seg].[Usuario] U
    WHERE U.usuario_id = @nUsuarioId
      AND U.estado = 1
      AND U.estado_cuenta = 'ACTIVA';

    IF ISNULL(@bRequiere, 0) = 0
    BEGIN
        SET @cMensaje = N'La cuenta no requiere segundo factor.';
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
             @cProposito = 'SEGUNDO_FACTOR',
             @binCodigoHmac = @binCodigoHmac,
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
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
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
        SET @cMensaje = N'Codigo de seguridad generado. Revise su correo.';
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

        SET @bResultado = 0;
        SET @cMensaje = N'No se pudo generar la verificacion adicional. Intente nuevamente.';
    
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarSegundoFactor',
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
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarSegundoFactor',
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
    @cProcedimiento = N'seg.PA_Usuario_Ins_SolicitarSegundoFactor',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Ins_SolicitarSegundoFactor',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
