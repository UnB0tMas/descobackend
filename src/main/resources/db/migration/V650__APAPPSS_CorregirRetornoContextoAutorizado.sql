-- DESCO / APAPPSS - correccion del retorno de autorizacion.
-- Fuente: procedimiento instalado en el volcado SQL facilitado (V274).
-- V650: no cambia firmas, permisos, tablas, sesiones ni historiales.
-- El flujo exitoso antes caia sin RETURN en __DESCO_Salida y
-- cambiaba @bResultado de 1 a 0.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [seg].[PA_Operacion_Sel_ContextoAutorizado]
(
    @cJson                       NVARCHAR(MAX),
    @cCodigoPermiso              VARCHAR(400),
    @nUsuarioId                  BIGINT OUTPUT,
    @nSesionUsuarioId            BIGINT OUTPUT,
    @nDispositivoUsuarioId       BIGINT OUTPUT,
    @nEmpleadoId                 BIGINT OUTPUT,
    @nModuloId                   INT OUTPUT,
    @gCorrelacionId              UNIQUEIDENTIFIER OUTPUT,
    @gSolicitudId                UNIQUEIDENTIFIER OUTPUT,
    @cIp                         VARCHAR(64) OUTPUT,
    @cEndpoint                   NVARCHAR(250) OUTPUT,
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    /* DESCO_JEFE_UOT_33_33_33_43_V1_20260826 */
    SET NOCOUNT ON;

    DECLARE @gSesionPublicaId UNIQUEIDENTIFIER;
    DECLARE @bAutorizado BIT = 0;
    DECLARE @dAhora DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @nCantidadModulos INT = 0;

    DECLARE @PermisosSolicitados TABLE
    (
        codigo VARCHAR(40) NOT NULL PRIMARY KEY
    );

    SELECT
        @nUsuarioId = NULL,
        @nSesionUsuarioId = NULL,
        @nDispositivoUsuarioId = NULL,
        @nEmpleadoId = NULL,
        @nModuloId = NULL,
        @gCorrelacionId = NULL,
        @gSolicitudId = NULL,
        @cIp = NULL,
        @cEndpoint = NULL,
        @bResultado = 0,
        @cMensaje = N'No se pudo validar su acceso.';

    SET @cCodigoPermiso = UPPER(NULLIF(LTRIM(RTRIM(@cCodigoPermiso)), ''));

    IF @cJson IS NULL
       OR ISJSON(@cJson) <> 1
       OR @cCodigoPermiso IS NULL
    BEGIN
        GOTO __DESCO_Salida;
    END;

    INSERT INTO @PermisosSolicitados(codigo)
    SELECT DISTINCT
           CONVERT(VARCHAR(40), UPPER(LTRIM(RTRIM(value))))
    FROM STRING_SPLIT(@cCodigoPermiso, '|')
    WHERE NULLIF(LTRIM(RTRIM(value)), '') IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM @PermisosSolicitados)
    BEGIN
        GOTO __DESCO_Salida;
    END;

    /*
       Una lista flexible representa alternativas para UNA MISMA acción funcional.
       Por seguridad no se permite mezclar permisos de módulos distintos.
    */
    SELECT
        @nCantidadModulos = COUNT(DISTINCT PE.modulo_id),
        @nModuloId = MIN(PE.modulo_id)
    FROM [seg].[Permiso] PE
    INNER JOIN [seg].[Modulo] M
        ON M.modulo_id = PE.modulo_id
       AND M.estado = 1
    INNER JOIN @PermisosSolicitados PS
        ON PS.codigo = PE.codigo
    WHERE PE.estado = 1;

    IF @nCantidadModulos <> 1
    BEGIN
        SET @nModuloId = NULL;
        SET @cMensaje = N'Esta opción no está disponible en este momento.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @gSesionPublicaId = sesionPublicaId,
        @gCorrelacionId = correlacionId,
        @gSolicitudId = solicitudId,
        @cIp = NULLIF(LTRIM(RTRIM(ip)), ''),
        @cEndpoint = NULLIF(LTRIM(RTRIM(endpoint)), N'')
    FROM OPENJSON(@cJson, '$.contexto')
    WITH
    (
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId',
        correlacionId UNIQUEIDENTIFIER '$.correlacionId',
        solicitudId UNIQUEIDENTIFIER '$.solicitudId',
        ip VARCHAR(64) '$.ip',
        endpoint NVARCHAR(250) '$.endpoint'
    );

    IF @gSesionPublicaId IS NULL
    BEGIN
        SET @nModuloId = NULL;
        GOTO __DESCO_Salida;
    END;

    IF @gCorrelacionId IS NULL SET @gCorrelacionId = NEWID();
    IF @gSolicitudId IS NULL SET @gSolicitudId = NEWID();

    SELECT TOP (1)
        @nUsuarioId = U.usuario_id,
        @nSesionUsuarioId = S.sesion_usuario_id,
        @nDispositivoUsuarioId = S.dispositivo_usuario_id,
        @nEmpleadoId = U.persona_id
    FROM [seg].[SesionUsuario] S
    INNER JOIN [seg].[Usuario] U
        ON U.usuario_id = S.usuario_id
    INNER JOIN [org].[Empleado] E
        ON E.empleado_id = U.persona_id
    INNER JOIN [org].[Persona] P
        ON P.persona_id = U.persona_id
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > @dAhora
      AND S.token_version = U.token_version
      AND U.estado = 1
      AND U.estado_cuenta = 'ACTIVA'
      AND (U.bloqueado_hasta IS NULL OR U.bloqueado_hasta <= @dAhora)
      AND E.estado = 1
      AND P.estado = 1;

    IF @nUsuarioId IS NULL
    BEGIN
        SET @nModuloId = NULL;
        GOTO __DESCO_Salida;
    END;

    EXEC [seg].[PA_Autorizacion_Sel_ValidarPermiso]
        @nUsuarioId = @nUsuarioId,
        @gSesionPublicaId = @gSesionPublicaId,
        @cCodigoPermiso = @cCodigoPermiso,
        @bAutorizado = @bAutorizado OUTPUT;

    IF @bAutorizado = 0
    BEGIN
        SET @nModuloId = NULL;
        SET @cMensaje = N'No tiene acceso a esta opción.';
        GOTO __DESCO_Salida;
    END;

    SET @bResultado = 1;
    SET @cMensaje = N'Acceso validado.';

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
    @cProcedimiento = N'seg.PA_Operacion_Sel_ContextoAutorizado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

-- El flujo correcto no debe caer en el bloque de error.
-- Solo las solicitudes rechazadas pasan por __DESCO_Salida.
IF ISNULL(@bResultado,0)=1 GOTO __DESCO_RespuestaFinal;

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
    @cProcedimiento = N'seg.PA_Operacion_Sel_ContextoAutorizado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
__DESCO_RespuestaFinal:
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Operacion_Sel_ContextoAutorizado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
