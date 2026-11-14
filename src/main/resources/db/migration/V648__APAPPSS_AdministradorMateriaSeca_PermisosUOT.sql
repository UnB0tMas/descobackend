-- V648. APAPPSS: permitir al ADMINISTRADOR de sistema operar desde su UOT
-- solo con un permiso especial individual vigente; no elimina restricciones de convenio.
-- La sincronizacion de autorizaciones se realiza en AdministratorAccessBootstrap.
-- Requiere V413, V414, V645 y V647 aplicadas. No modificar migraciones existentes.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER FUNCTION [seg].[FN_Usuario_TienePermisoUOT]
(
    @usuario_id BIGINT,
    @uot_id BIGINT,
    @codigo_permiso VARCHAR(40)
)
RETURNS BIT
AS
BEGIN
    DECLARE @R BIT=0, @UsuarioUOTId BIGINT, @PermisoId BIGINT, @Override BIT;

    SELECT TOP (1) @UsuarioUOTId = usuario_uot_id
    FROM [seg].[UsuarioUOT]
    WHERE usuario_id=@usuario_id AND uot_id=@uot_id AND estado=1
      AND fecha_desde<=SYSUTCDATETIME()
      AND (fecha_hasta IS NULL OR fecha_hasta>SYSUTCDATETIME())
    ORDER BY usuario_uot_id DESC;

    IF @UsuarioUOTId IS NULL RETURN 0;

    SELECT @PermisoId=permiso_id
    FROM [seg].[Permiso]
    WHERE codigo=@codigo_permiso AND estado=1;
    IF @PermisoId IS NULL RETURN 0;

    IF EXISTS (SELECT 1 FROM [seg].[ModuloEspecialPermiso] WHERE permiso_id=@PermisoId)
       AND NOT EXISTS (
           SELECT 1
           FROM [seg].[ModuloEspecialPermiso] MP
           JOIN [seg].[ModuloEspecial] M
                ON M.modulo_especial_id=MP.modulo_especial_id AND M.estado=1
           JOIN [org].[ConvenioModuloEspecial] CM
                ON CM.modulo_especial_id=M.modulo_especial_id AND CM.estado=1
           JOIN [org].[ConvenioUOTOrganizacion] C
                ON C.convenio_uot_organizacion_id=CM.convenio_uot_organizacion_id
           JOIN [org].[Empresa] E ON E.empresa_id=C.empresa_id AND E.estado=1
           WHERE MP.permiso_id=@PermisoId AND C.uot_id=@uot_id AND C.estado=1
             AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
             AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
       ) RETURN 0;

    -- Administrador de sistema: excepcion SOLAMENTE al vinculo EmpleadoUOT.
    -- Se exige UsuarioUOT, modulo de convenio habilitado y concesion explicita.
    -- No se heredan permisos especiales del rol ni se habilitan otras organizaciones.
    IF EXISTS (SELECT 1 FROM [seg].[ModuloEspecialPermiso] WHERE permiso_id=@PermisoId)
       AND NOT EXISTS (
           SELECT 1 FROM [seg].[UsuarioRol] UR
           JOIN [seg].[Rol] R ON R.rol_id=UR.rol_id AND R.estado=1
           WHERE UR.usuario_id=@usuario_id AND UR.estado=1
             AND UR.fecha_desde<=SYSUTCDATETIME()
             AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
             AND R.codigo='ADMINISTRADOR'
       )
       AND NOT EXISTS (
           SELECT 1 FROM [seg].[Usuario] U
           JOIN [org].[Empleado] E ON E.empleado_id=U.persona_id AND E.estado=1
           JOIN [org].[EmpleadoUOT] EU ON EU.empleado_id=E.empleado_id
           WHERE U.usuario_id=@usuario_id AND U.estado=1
             AND EU.uot_id=@uot_id AND EU.estado=1
             AND EU.fecha_desde<=CONVERT(date,SYSUTCDATETIME())
             AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(date,SYSUTCDATETIME()))
       ) RETURN 0;

    SELECT TOP(1) @Override=permitido
    FROM [seg].[UsuarioUOTPermiso]
    WHERE usuario_uot_id=@UsuarioUOTId AND permiso_id=@PermisoId AND estado=1
      AND fecha_desde<=SYSUTCDATETIME()
      AND (fecha_hasta IS NULL OR fecha_hasta>SYSUTCDATETIME())
    ORDER BY usuario_uot_permiso_id DESC;

    -- No heredar permisos especiales de roles compartidos ni de una UOT distinta.
    IF EXISTS (SELECT 1 FROM [seg].[ModuloEspecialPermiso] WHERE permiso_id=@PermisoId)
        RETURN ISNULL(@Override, 0);

    IF @Override IS NOT NULL RETURN @Override;

    IF EXISTS (
        SELECT 1 FROM [seg].[UsuarioUOTRol] UUR
        JOIN [seg].[Rol] R ON R.rol_id=UUR.rol_id AND R.estado=1
        JOIN [seg].[RolPermiso] RP
             ON RP.rol_id=R.rol_id AND RP.permiso_id=@PermisoId AND RP.estado=1
        WHERE UUR.usuario_uot_id=@UsuarioUOTId AND UUR.estado=1
          AND UUR.fecha_desde<=SYSUTCDATETIME()
          AND (UUR.fecha_hasta IS NULL OR UUR.fecha_hasta>SYSUTCDATETIME())
    ) SET @R=1;
    RETURN @R;
END;
GO
