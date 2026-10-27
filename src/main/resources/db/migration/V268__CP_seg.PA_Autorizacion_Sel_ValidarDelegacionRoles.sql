IF OBJECT_ID(N'[seg].[PA_Autorizacion_Sel_ValidarDelegacionRoles]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Autorizacion_Sel_ValidarDelegacionRoles];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Autorizacion_Sel_ValidarDelegacionRoles
' Descripción             : Valida las reglas para delegar roles a otro usuario.
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
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Autorizacion_Sel_ValidarDelegacionRoles]
        @nUsuarioActorId = 0,
        @cRolesJson = N'',
        @bRequerirAlMenosUno = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Autorizacion_Sel_ValidarDelegacionRoles]
(
    @nUsuarioActorId BIGINT,
    @cRolesJson NVARCHAR(MAX),
    @bRequerirAlMenosUno BIT = 1,
    @bResultado BIT OUTPUT,
    @cMensaje NVARCHAR(300) OUTPUT,
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

    SET NOCOUNT ON;

    DECLARE @dAhora DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @Roles TABLE (rol_id BIGINT PRIMARY KEY);

    SELECT
        @bResultado = 0,
        @cMensaje = N'No se pudieron validar los roles seleccionados.';

    IF @nUsuarioActorId IS NULL
       OR @cRolesJson IS NULL
       OR ISJSON(@cRolesJson) <> 1
    BEGIN
        SET @cMensaje = N'No se pudieron validar los roles seleccionados.';
        GOTO __DESCO_Salida;
    END;

    INSERT INTO @Roles(rol_id)
    SELECT DISTINCT J.rolId
    FROM OPENJSON(@cRolesJson)
    WITH (rolId BIGINT '$.rolId') J
    WHERE J.rolId IS NOT NULL;

    IF @bRequerirAlMenosUno = 1
       AND NOT EXISTS (SELECT 1 FROM @Roles)
    BEGIN
        SET @cMensaje = N'Seleccione al menos un rol.';
        GOTO __DESCO_Salida;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @Roles X
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [seg].[Rol] R
            WHERE R.rol_id = X.rol_id
              AND R.estado = 1
        )
    )
    BEGIN
        SET @cMensaje = N'Uno o más roles seleccionados no están disponibles.';
        GOTO __DESCO_Salida;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @Roles X
        INNER JOIN [seg].[RolPermiso] RPObjetivo
            ON RPObjetivo.rol_id = X.rol_id
           AND RPObjetivo.estado = 1
        INNER JOIN [seg].[Permiso] PObjetivo
            ON PObjetivo.permiso_id = RPObjetivo.permiso_id
           AND PObjetivo.estado = 1
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [seg].[UsuarioRol] URActor
            INNER JOIN [seg].[Rol] RActor
                ON RActor.rol_id = URActor.rol_id
               AND RActor.estado = 1
            INNER JOIN [seg].[RolPermiso] RPActor
                ON RPActor.rol_id = URActor.rol_id
               AND RPActor.permiso_id = RPObjetivo.permiso_id
               AND RPActor.estado = 1
            INNER JOIN [seg].[Permiso] PActor
                ON PActor.permiso_id = RPActor.permiso_id
               AND PActor.estado = 1
            WHERE URActor.usuario_id = @nUsuarioActorId
              AND URActor.estado = 1
              AND URActor.fecha_desde <= @dAhora
              AND (URActor.fecha_hasta IS NULL OR URActor.fecha_hasta >= @dAhora)
        )
    )
    BEGIN
        SET @cMensaje = N'Solo puede asignar roles cuyos permisos ya están dentro de sus propios permisos vigentes.';
        GOTO __DESCO_Salida;
    END;

    SET @bResultado = 1;
    SET @cMensaje = N'Roles autorizados para delegación.';

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
    @cProcedimiento = N'seg.PA_Autorizacion_Sel_ValidarDelegacionRoles',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
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
    @cProcedimiento = N'seg.PA_Autorizacion_Sel_ValidarDelegacionRoles',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = NULL,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'seg.PA_Autorizacion_Sel_ValidarDelegacionRoles',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
