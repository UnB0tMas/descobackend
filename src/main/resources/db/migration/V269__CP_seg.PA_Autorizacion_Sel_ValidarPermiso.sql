IF OBJECT_ID(N'[seg].[PA_Autorizacion_Sel_ValidarPermiso]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Autorizacion_Sel_ValidarPermiso];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Autorizacion_Sel_ValidarPermiso
' Descripción             : Valida si el contexto de sesión tiene el permiso solicitado.
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
        @bAutorizado BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [seg].[PA_Autorizacion_Sel_ValidarPermiso]
        @nUsuarioId = 0,
        @gSesionPublicaId = '00000000-0000-0000-0000-000000000001',
        @cCodigoPermiso = '',
        @bAutorizado = @bAutorizado OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @bAutorizado, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE seg.PA_Autorizacion_Sel_ValidarPermiso
(
    @nUsuarioId BIGINT,
    @gSesionPublicaId UNIQUEIDENTIFIER,
    @cCodigoPermiso VARCHAR(400),
    @bAutorizado BIT OUTPUT,
    @bResultado BIT=NULL OUTPUT,
    @cMensaje NVARCHAR(300)=NULL OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @bAutorizado=0,@bResultado=0,@cMensaje=N'No tiene acceso a esta opcion.',@cCodigoRespuesta='ACCESO_DENEGADO',@nHttpRespuesta=403;
    SET @cCodigoPermiso=UPPER(NULLIF(LTRIM(RTRIM(@cCodigoPermiso)),''));
    IF @nUsuarioId IS NULL OR @gSesionPublicaId IS NULL OR @cCodigoPermiso IS NULL RETURN 1;

    DECLARE @Ahora DATETIME2(0)=SYSUTCDATETIME(),@Modo VARCHAR(12),@Uot BIGINT;
    SELECT TOP(1) @Modo=S.modo_uot,@Uot=S.uot_contexto_id
    FROM seg.SesionUsuario S
    JOIN seg.Usuario U ON U.usuario_id=S.usuario_id
    JOIN org.Persona P ON P.persona_id=U.persona_id
    WHERE S.sesion_publica_id=@gSesionPublicaId AND S.usuario_id=@nUsuarioId
      AND S.estado=1 AND S.fecha_revocacion IS NULL AND S.fecha_expiracion_renovacion>@Ahora
      AND S.token_version=U.token_version AND U.estado=1 AND U.estado_cuenta='ACTIVA'
      AND (U.bloqueado_hasta IS NULL OR U.bloqueado_hasta<=@Ahora) AND P.estado=1;
    IF @Modo IS NULL RETURN 1;

    DECLARE @Permisos TABLE(codigo VARCHAR(40) PRIMARY KEY);
    INSERT @Permisos(codigo)
    SELECT DISTINCT CONVERT(VARCHAR(40),UPPER(LTRIM(RTRIM(value))))
    FROM STRING_SPLIT(@cCodigoPermiso,'|') WHERE NULLIF(LTRIM(RTRIM(value)),'') IS NOT NULL;
    IF NOT EXISTS(SELECT 1 FROM @Permisos) RETURN 1;

    /* El superadministrador global puede administrar la plataforma. */
    IF EXISTS(
        SELECT 1 FROM seg.UsuarioRol UR
        JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.codigo='ADMINISTRADOR' AND R.estado=1
        JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.estado=1
        JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id AND P.estado=1
        JOIN @Permisos Q ON Q.codigo=P.codigo
        WHERE UR.usuario_id=@nUsuarioId AND UR.estado=1 AND UR.fecha_desde<=@Ahora
          AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>@Ahora)
    ) SET @bAutorizado=1;

    IF @bAutorizado=0 AND @Modo='ESPECIFICA' AND @Uot IS NOT NULL
       AND EXISTS(SELECT 1 FROM @Permisos Q WHERE seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,Q.codigo)=1)
        SET @bAutorizado=1;

    IF @bAutorizado=0 AND @Modo='GENERAL'
       AND EXISTS(
           SELECT 1 FROM seg.UsuarioUOT UU
           JOIN org.UOT O ON O.uot_id=UU.uot_id AND O.estado=1
           CROSS JOIN @Permisos Q
           WHERE UU.usuario_id=@nUsuarioId AND UU.estado=1 AND UU.fecha_hasta IS NULL AND UU.fecha_desde<=@Ahora
             AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,UU.uot_id,Q.codigo)=1
       ) SET @bAutorizado=1;

    IF @bAutorizado=1
    BEGIN
        SELECT @bResultado=1,@cMensaje=N'Acceso validado.',@cCodigoRespuesta='ACCESO_VALIDADO',@nHttpRespuesta=200;
        RETURN 0;
    END;
    RETURN 1;
END;
GO
