IF OBJECT_ID(N'[seg].[PA_Dispositivo_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Dispositivo_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Dispositivo_Sel_Listado
' Descripción             : Consulta los dispositivos asociados a un usuario.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Dispositivo_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Dispositivo_Sel_Listado]
(
    @cJson       NVARCHAR(MAX),
    @bResultado  BIT OUTPUT,
    @cMensaje    NVARCHAR(300) OUTPUT,
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

    DECLARE
        @nUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME(),
        @nDiasReconocido SMALLINT;

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo consultar los dispositivos.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionPublicaId = sesionPublicaId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId'
    );

    IF @nUsuarioId IS NULL OR @gSesionPublicaId IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [seg].[SesionUsuario] S
        INNER JOIN [seg].[Usuario] U ON U.usuario_id = S.usuario_id
        WHERE S.sesion_publica_id = @gSesionPublicaId
          AND S.usuario_id = @nUsuarioId
          AND S.estado = 1
          AND S.fecha_revocacion IS NULL
          AND S.fecha_expiracion_renovacion > @dAhora
          AND S.token_version = U.token_version
          AND U.estado = 1
          AND U.estado_cuenta = 'ACTIVA'
    )
    BEGIN
        SET @cMensaje = N'La sesion no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    SELECT TOP (1)
        @nDiasReconocido = PS.dias_dispositivo_reconocido
    FROM [seg].[PoliticaSeguridad] PS
    WHERE PS.codigo = 'GENERAL'
      AND PS.estado = 1
      AND PS.fecha_hasta IS NULL
      AND PS.fecha_desde <= @dAhora
    ORDER BY PS.fecha_desde DESC;

    /* Caducidad efectiva y persistente del reconocimiento. */
    UPDATE D
    SET
        D.es_reconocido = 0,
        D.fecha_retiro_reconocimiento =
            COALESCE(D.fecha_retiro_reconocimiento, @dAhora)
    FROM [seg].[DispositivoUsuario] D
    WHERE D.usuario_id = @nUsuarioId
      AND D.estado = 1
      AND D.es_reconocido = 1
      AND D.fecha_reconocimiento IS NOT NULL
      AND DATEADD(DAY, ISNULL(@nDiasReconocido, 7), D.fecha_reconocimiento) <= @dAhora;

    SELECT
        D.dispositivo_usuario_id AS dispositivoUsuarioId,
        D.navegador,
        D.sistema_operativo AS sistemaOperativo,
        D.fecha_primera_deteccion AS fechaPrimeraDeteccionUtc,
        D.fecha_ultima_actividad AS fechaUltimaActividadUtc,
        D.ultima_ip AS ultimaIp,
        CAST
        (
            CASE
                WHEN D.es_reconocido = 1
                 AND D.fecha_reconocimiento IS NOT NULL
                 AND DATEADD(DAY, ISNULL(@nDiasReconocido, 7), D.fecha_reconocimiento) > @dAhora
                THEN 1 ELSE 0
            END
            AS BIT
        ) AS esReconocidoVigente,
        D.fecha_reconocimiento AS fechaReconocimientoUtc,
        CASE
            WHEN D.es_reconocido = 1
             AND D.fecha_reconocimiento IS NOT NULL
            THEN DATEADD(DAY, ISNULL(@nDiasReconocido, 7), D.fecha_reconocimiento)
            ELSE NULL
        END AS fechaExpiracionReconocimientoUtc,
        CAST
        (
            CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM [seg].[SesionUsuario] S
                    WHERE S.sesion_publica_id = @gSesionPublicaId
                      AND S.dispositivo_usuario_id = D.dispositivo_usuario_id
                )
                THEN 1 ELSE 0
            END
            AS BIT
        ) AS esDispositivoActual
    FROM [seg].[DispositivoUsuario] D
    WHERE D.usuario_id = @nUsuarioId
      AND D.estado = 1
    ORDER BY D.fecha_ultima_actividad DESC, D.dispositivo_usuario_id DESC;

    SET @bResultado = 1;
    SET @cMensaje = N'Dispositivos consultados correctamente.';

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
    @cProcedimiento = N'seg.PA_Dispositivo_Sel_Listado',
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
    @cProcedimiento = N'seg.PA_Dispositivo_Sel_Listado',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Dispositivo_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
