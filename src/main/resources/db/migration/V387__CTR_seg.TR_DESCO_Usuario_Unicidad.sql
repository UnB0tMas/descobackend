IF OBJECT_ID(N'[seg].[TR_DESCO_Usuario_Unicidad]', N'TR') IS NOT NULL
    DROP TRIGGER [seg].[TR_DESCO_Usuario_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : seg.TR_DESCO_Usuario_Unicidad
' Descripción              : Controla la unicidad de usuarios.
' Tabla asociada          : seg.Usuario
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre seg.Usuario.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[seg].[TR_DESCO_Usuario_Unicidad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER seg.TR_DESCO_Usuario_Unicidad ON seg.Usuario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.usuario_id=I.usuario_id
  WHERE I.usuario_clave_desco IS NOT NULL
    AND (D.usuario_id IS NULL OR ISNULL(I.usuario_clave_desco,'')<>ISNULL(D.usuario_clave_desco,''))
    AND EXISTS(SELECT 1 FROM seg.Usuario X WITH(UPDLOCK,HOLDLOCK) WHERE X.usuario_clave_desco=I.usuario_clave_desco AND X.usuario_id<>I.usuario_id)
 ) THROW 51024,N'El nombre de usuario ya está registrado.',1;
END;
GO
