IF OBJECT_ID(N'[seg].[PA_Usuario_Sel_ContextoAcceso]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Usuario_Sel_ContextoAcceso];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Usuario_Sel_ContextoAcceso
' Descripción             : Consulta el contexto de acceso del usuario.
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
    EXEC [seg].[PA_Usuario_Sel_ContextoAcceso]
        @cJson = N'{}',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE [seg].[PA_Usuario_Sel_ContextoAcceso]
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
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

    /* DESCO_SEGURIDAD_V2_20260825 */
    SET NOCOUNT ON;

    DECLARE
        @nUsuarioId BIGINT,
        @gSesionPublicaId UNIQUEIDENTIFIER,
        @nSesionUsuarioId BIGINT,
        @nDispositivoUsuarioId BIGINT,
        @dAhora DATETIME2(0) = SYSUTCDATETIME();

    SET @bResultado = 0;
    SET @cMensaje = N'No se pudo obtener el contexto de acceso.';

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

    SELECT
        @nSesionUsuarioId = S.sesion_usuario_id,
        @nDispositivoUsuarioId = S.dispositivo_usuario_id
    FROM [seg].[SesionUsuario] S
    INNER JOIN [seg].[Usuario] U ON U.usuario_id = S.usuario_id
    INNER JOIN [org].[Empleado] E ON E.empleado_id = U.persona_id
    INNER JOIN [org].[Persona] P ON P.persona_id = U.persona_id
    WHERE S.sesion_publica_id = @gSesionPublicaId
      AND S.usuario_id = @nUsuarioId
      AND S.estado = 1
      AND S.fecha_revocacion IS NULL
      AND S.fecha_expiracion_renovacion > @dAhora
      AND S.token_version = U.token_version
      AND U.estado = 1
      AND U.estado_cuenta = 'ACTIVA'
      AND (U.bloqueado_hasta IS NULL OR U.bloqueado_hasta <= @dAhora)
      AND E.estado = 1
      AND P.estado = 1;

    IF @nSesionUsuarioId IS NULL
    BEGIN
        SET @cMensaje = N'La sesion no esta disponible.';
        GOTO __DESCO_Salida;
    END;

    CREATE TABLE #TmpRoles
    (
        rol_id BIGINT NOT NULL PRIMARY KEY
    );

    INSERT INTO #TmpRoles(rol_id)
    SELECT DISTINCT R.rol_id
    FROM [seg].[UsuarioRol] UR
    INNER JOIN [seg].[Rol] R ON R.rol_id = UR.rol_id
    WHERE UR.usuario_id = @nUsuarioId
      AND UR.estado = 1
      AND UR.fecha_desde <= @dAhora
      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta >= @dAhora)
      AND R.estado = 1;

    CREATE TABLE #TmpPermisos
    (
        permiso_id BIGINT NOT NULL PRIMARY KEY,
        modulo_id INT NOT NULL
    );

    INSERT INTO #TmpPermisos(permiso_id, modulo_id)
    SELECT DISTINCT
        P.permiso_id,
        P.modulo_id
    FROM #TmpRoles TR
    INNER JOIN [seg].[RolPermiso] RP ON RP.rol_id = TR.rol_id
    INNER JOIN [seg].[Permiso] P ON P.permiso_id = RP.permiso_id
    INNER JOIN [seg].[Modulo] M ON M.modulo_id = P.modulo_id
    WHERE RP.estado = 1
      AND P.estado = 1
      AND M.estado = 1;

    CREATE TABLE #TmpModulos
    (
        modulo_id INT NOT NULL PRIMARY KEY
    );

    ;
WITH ModulosAcceso
    AS
    (
        SELECT DISTINCT
            M.modulo_id,
            M.modulo_padre_id,
            CAST('|' + CAST(M.modulo_id AS VARCHAR(20)) + '|' AS VARCHAR(MAX)) AS ruta_ids
        FROM #TmpPermisos TP
        INNER JOIN [seg].[Modulo] M ON M.modulo_id = TP.modulo_id
        WHERE M.estado = 1

        UNION ALL

        SELECT
            MP.modulo_id,
            MP.modulo_padre_id,
            CAST(MA.ruta_ids + CAST(MP.modulo_id AS VARCHAR(20)) + '|' AS VARCHAR(MAX))
        FROM ModulosAcceso MA
        INNER JOIN [seg].[Modulo] MP ON MP.modulo_id = MA.modulo_padre_id
        WHERE MP.estado = 1
          AND CHARINDEX('|' + CAST(MP.modulo_id AS VARCHAR(20)) + '|', MA.ruta_ids) = 0
    )
    INSERT INTO #TmpModulos(modulo_id)
    SELECT DISTINCT modulo_id
    FROM ModulosAcceso
    OPTION (MAXRECURSION 100);

    /* RESULTSET 1: USUARIO + SESION */
    SELECT
        U.usuario_id AS usuarioId,
        U.nombre_usuario AS nombreUsuario,
        U.estado_cuenta AS estadoCuenta,
        U.ultimo_acceso_correcto AS ultimoAccesoCorrectoUtc,
        U.requiere_cambio_password AS requiereCambioPassword,
        U.segundo_factor_habilitado AS segundoFactorHabilitado,
        U.token_version AS tokenVersion,

        P.persona_id AS personaId,
        P.tipo_documento AS tipoDocumento,
        P.numero_documento AS numeroDocumento,
        P.nombres,
        P.apellido_paterno AS apellidoPaterno,
        P.apellido_materno AS apellidoMaterno,
        CONCAT
        (
            P.nombres, N' ', P.apellido_paterno,
            CASE WHEN P.apellido_materno IS NULL OR LTRIM(RTRIM(P.apellido_materno)) = N''
                 THEN N'' ELSE N' ' + P.apellido_materno END
        ) AS nombreCompleto,
        P.telefono,

        E.codigo_empleado AS codigoEmpleado,
        E.empresa_id AS empresaId,

        UCS.correo AS correoSeguridad,
        UCS.es_verificado AS correoSeguridadVerificado,

        S.sesion_publica_id AS sesionPublicaId,
        S.fecha_creacion AS fechaSesionUtc,
        S.fecha_expiracion_renovacion AS fechaExpiracionRenovacionUtc,
        S.dispositivo_usuario_id AS dispositivoUsuarioId,

        D.navegador,
        D.sistema_operativo AS sistemaOperativo,
        D.es_reconocido AS dispositivoReconocido
    FROM [seg].[Usuario] U
    INNER JOIN [org].[Persona] P ON P.persona_id = U.persona_id
    INNER JOIN [org].[Empleado] E ON E.empleado_id = U.persona_id
    INNER JOIN [seg].[SesionUsuario] S ON S.sesion_usuario_id = @nSesionUsuarioId
    LEFT JOIN [seg].[DispositivoUsuario] D
        ON D.dispositivo_usuario_id = S.dispositivo_usuario_id
    OUTER APPLY
    (
        SELECT TOP (1)
            X.correo,
            X.es_verificado
        FROM [seg].[UsuarioCorreoSeguridad] X
        WHERE X.usuario_id = U.usuario_id
          AND X.estado = 1
          AND X.es_principal = 1
          AND X.fecha_hasta IS NULL
        ORDER BY X.fecha_desde DESC
    ) UCS
    WHERE U.usuario_id = @nUsuarioId;

    /* RESULTSET 2: ROLES */
    SELECT
        R.rol_id AS rolId,
        R.codigo AS codigoRol,
        R.nombre AS nombreRol,
        R.descripcion,
        R.requiere_segundo_factor AS requiereSegundoFactor
    FROM #TmpRoles TR
    INNER JOIN [seg].[Rol] R ON R.rol_id = TR.rol_id
    ORDER BY R.nombre;

    /* RESULTSET 3: MODULOS */
    SELECT
        M.modulo_id AS moduloId,
        M.modulo_padre_id AS moduloPadreId,
        M.codigo AS codigoModulo,
        M.nombre AS nombreModulo,
        M.orden,
        M.ruta,
        M.icono,
        M.visible_menu AS visibleMenu,
        M.es_grupo AS esGrupo
    FROM #TmpModulos TM
    INNER JOIN [seg].[Modulo] M ON M.modulo_id = TM.modulo_id
    WHERE M.estado = 1
    ORDER BY M.orden, M.nombre;

    /* RESULTSET 4: PERMISOS */
    SELECT
        P.permiso_id AS permisoId,
        M.modulo_id AS moduloId,
        M.codigo AS codigoModulo,
        P.codigo AS codigoPermiso,
        P.nombre AS nombrePermiso,
        P.descripcion,
        P.accion,
        P.es_sensible AS esSensible,
        P.requiere_motivo AS requiereMotivo
    FROM #TmpPermisos TP
    INNER JOIN [seg].[Permiso] P ON P.permiso_id = TP.permiso_id
    INNER JOIN [seg].[Modulo] M ON M.modulo_id = P.modulo_id
    ORDER BY M.orden, M.nombre, P.nombre;

    SET @bResultado = 1;
    SET @cMensaje = N'Contexto de acceso obtenido correctamente.';

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
    @cProcedimiento = N'seg.PA_Usuario_Sel_ContextoAcceso',
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
    @cProcedimiento = N'seg.PA_Usuario_Sel_ContextoAcceso',
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
FROM config.FN_RespuestaUsuario(N'seg.PA_Usuario_Sel_ContextoAcceso',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
