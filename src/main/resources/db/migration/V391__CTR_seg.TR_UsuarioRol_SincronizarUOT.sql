IF OBJECT_ID(N'[seg].[TR_UsuarioRol_SincronizarUOT]', N'TR') IS NOT NULL
    DROP TRIGGER [seg].[TR_UsuarioRol_SincronizarUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : seg.TR_UsuarioRol_SincronizarUOT
' Descripción              : Sincroniza roles de usuario con la UOT.
' Tabla asociada          : seg.UsuarioRol
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Seguridad
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre seg.UsuarioRol.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[seg].[TR_UsuarioRol_SincronizarUOT]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER seg.TR_UsuarioRol_SincronizarUOT
ON seg.UsuarioRol AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT seg.UsuarioUOTRol(usuario_uot_id,rol_id,fecha_desde,fecha_hasta,estado,asignado_por_usuario_id)
    SELECT UU.usuario_uot_id,I.rol_id,COALESCE(I.fecha_desde,SYSUTCDATETIME()),I.fecha_hasta,I.estado,I.asignado_por_usuario_id
    FROM inserted I JOIN seg.UsuarioUOT UU ON UU.usuario_id=I.usuario_id AND UU.estado=1 AND UU.fecha_hasta IS NULL
    WHERE I.estado=1 AND I.fecha_hasta IS NULL
      AND NOT EXISTS(SELECT 1 FROM seg.UsuarioUOTRol X WHERE X.usuario_uot_id=UU.usuario_uot_id AND X.rol_id=I.rol_id AND X.estado=1 AND X.fecha_hasta IS NULL);
END;
GO
