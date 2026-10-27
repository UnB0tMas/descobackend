IF OBJECT_ID(N'[seg].[TR_DESCO_UsuarioRol_Vigencia]', N'TR') IS NOT NULL
    DROP TRIGGER [seg].[TR_DESCO_UsuarioRol_Vigencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : seg.TR_DESCO_UsuarioRol_Vigencia
' Descripción              : Controla la vigencia de roles asignados a usuarios.
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
    WHERE T.object_id = OBJECT_ID(N'[seg].[TR_DESCO_UsuarioRol_Vigencia]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER seg.TR_DESCO_UsuarioRol_Vigencia ON seg.UsuarioRol AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.usuario_rol_id=I.usuario_rol_id
  WHERE I.estado=1 AND I.fecha_hasta IS NULL
    AND (D.usuario_rol_id IS NULL OR I.usuario_id<>D.usuario_id OR I.rol_id<>D.rol_id OR I.estado<>D.estado OR ISNULL(I.fecha_hasta,'99991231')<>ISNULL(D.fecha_hasta,'99991231'))
    AND EXISTS(SELECT 1 FROM seg.UsuarioRol X WITH(UPDLOCK,HOLDLOCK) WHERE X.usuario_id=I.usuario_id AND X.rol_id=I.rol_id AND X.estado=1 AND X.fecha_hasta IS NULL AND X.usuario_rol_id<>I.usuario_rol_id)
 ) THROW 51032,N'El rol ya está asignado al usuario.',1;
END;
GO
