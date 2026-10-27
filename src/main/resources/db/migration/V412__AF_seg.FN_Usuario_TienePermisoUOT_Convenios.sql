IF OBJECT_ID(N'[seg].[FN_Usuario_TienePermisoUOT]', N'FN') IS NOT NULL
   OR OBJECT_ID(N'[seg].[FN_Usuario_TienePermisoUOT]', N'IF') IS NOT NULL
   OR OBJECT_ID(N'[seg].[FN_Usuario_TienePermisoUOT]', N'TF') IS NOT NULL
    DROP FUNCTION [seg].[FN_Usuario_TienePermisoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Función           : seg.FN_Usuario_TienePermisoUOT
' Descripción              : Comprueba los permisos y asignaciones vigentes de un usuario dentro de una UOT.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Seguridad
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT [seg].[FN_Usuario_TienePermisoUOT](1, 1, 'CODIGO_PERMISO') AS TienePermiso;
*******************************************************************************************************/
CREATE FUNCTION seg.FN_Usuario_TienePermisoUOT(@usuario_id BIGINT,@uot_id BIGINT,@codigo_permiso VARCHAR(40))
RETURNS BIT
AS
BEGIN
    DECLARE @R BIT=0,@UsuarioUOTId BIGINT,@PermisoId BIGINT,@Override BIT;
    SELECT TOP(1) @UsuarioUOTId=usuario_uot_id FROM seg.UsuarioUOT
    WHERE usuario_id=@usuario_id AND uot_id=@uot_id AND estado=1 AND fecha_hasta IS NULL AND fecha_desde<=SYSUTCDATETIME();
    IF @UsuarioUOTId IS NULL RETURN 0;
    SELECT @PermisoId=permiso_id FROM seg.Permiso WHERE codigo=@codigo_permiso AND estado=1;
    IF @PermisoId IS NULL RETURN 0;
    -- Un permiso funcional no habilita por si solo un modulo opcional.
    -- El vinculo debe pertenecer a esta misma UOT y seguir vigente.
    IF EXISTS (
        SELECT 1 FROM seg.ModuloEspecialPermiso WHERE permiso_id=@PermisoId
    ) AND NOT EXISTS (
        SELECT 1
        FROM seg.ModuloEspecialPermiso MP
        JOIN seg.ModuloEspecial M ON M.modulo_especial_id=MP.modulo_especial_id AND M.estado=1
        JOIN org.ConvenioModuloEspecial CM ON CM.modulo_especial_id=M.modulo_especial_id AND CM.estado=1
        JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=CM.convenio_uot_organizacion_id
        JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
        WHERE MP.permiso_id=@PermisoId AND C.uot_id=@uot_id AND C.estado=1
          AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
          AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
    ) RETURN 0;
    SELECT TOP(1) @Override=permitido FROM seg.UsuarioUOTPermiso
    WHERE usuario_uot_id=@UsuarioUOTId AND permiso_id=@PermisoId AND estado=1
      AND fecha_desde<=SYSUTCDATETIME() AND (fecha_hasta IS NULL OR fecha_hasta>SYSUTCDATETIME())
    ORDER BY usuario_uot_permiso_id DESC;
    IF @Override IS NOT NULL RETURN @Override;
    IF EXISTS
    (
        SELECT 1
        FROM seg.UsuarioUOTRol UUR
        JOIN seg.Rol R ON R.rol_id=UUR.rol_id AND R.estado=1
        JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.permiso_id=@PermisoId AND RP.estado=1
        WHERE UUR.usuario_uot_id=@UsuarioUOTId AND UUR.estado=1
          AND UUR.fecha_desde<=SYSUTCDATETIME() AND (UUR.fecha_hasta IS NULL OR UUR.fecha_hasta>SYSUTCDATETIME())
    ) SET @R=1;
    RETURN @R;
END;
GO

