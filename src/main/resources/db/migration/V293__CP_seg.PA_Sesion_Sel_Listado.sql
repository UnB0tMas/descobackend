IF OBJECT_ID(N'[seg].[PA_Sesion_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Sesion_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Sesion_Sel_Listado
' Descripción             : Consulta las sesiones registradas de un usuario.
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
    EXEC [seg].[PA_Sesion_Sel_Listado]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Sesion_Sel_Listado]
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
        @gSesionActual UNIQUEIDENTIFIER,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo consultar las sesiones.';

    IF @cJson IS NULL OR ISJSON(@cJson) <> 1
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    SELECT
        @nUsuarioId = usuarioId,
        @gSesionActual = sesionPublicaId
    FROM OPENJSON(@cJson)
    WITH
    (
        usuarioId BIGINT '$.usuarioId',
        sesionPublicaId UNIQUEIDENTIFIER '$.sesionPublicaId'
    );

    IF @nUsuarioId IS NULL OR @gSesionActual IS NULL
    BEGIN
        SET @cMensaje = N'La solicitud no es valida.';
        GOTO __DESCO_Salida;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [seg].[SesionUsuario] S
        INNER JOIN [seg].[Usuario] U ON U.usuario_id = S.usuario_id
        WHERE S.sesion_publica_id = @gSesionActual
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

    SELECT
        S.sesion_publica_id AS sesionPublicaId,
        S.fecha_creacion AS fechaCreacionUtc,
        S.fecha_ultima_actividad AS fechaUltimaActividadUtc,
        S.fecha_expiracion_renovacion AS fechaExpiracionRenovacionUtc,
        S.ip_creacion AS ipCreacion,
        S.ip_ultima_actividad AS ipUltimaActividad,
        CAST(CASE WHEN S.sesion_publica_id = @gSesionActual THEN 1 ELSE 0 END AS BIT) AS esSesionActual,
        CAST(CASE
                WHEN S.estado = 1
                 AND S.fecha_revocacion IS NULL
                 AND S.fecha_expiracion_renovacion > @dAhora
                THEN 1 ELSE 0
             END AS BIT) AS estaActiva,
        D.dispositivo_usuario_id AS dispositivoUsuarioId,
        D.navegador,
        D.sistema_operativo AS sistemaOperativo,
        D.fecha_primera_deteccion AS fechaPrimeraDeteccionUtc,
        D.fecha_ultima_actividad AS fechaUltimaActividadDispositivoUtc,
        D.es_reconocido AS esReconocido
    FROM [seg].[SesionUsuario] S
    LEFT JOIN [seg].[DispositivoUsuario] D
        ON D.dispositivo_usuario_id = S.dispositivo_usuario_id
    WHERE S.usuario_id = @nUsuarioId
    ORDER BY S.fecha_ultima_actividad DESC, S.sesion_usuario_id DESC;

    SET @bResultado = 1;
    SET @cMensaje = N'Sesiones consultadas correctamente.';

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
    @cProcedimiento = N'seg.PA_Sesion_Sel_Listado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
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
    @cProcedimiento = N'seg.PA_Sesion_Sel_Listado',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 1;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Sesion_Sel_Listado',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
