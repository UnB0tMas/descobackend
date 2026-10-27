IF OBJECT_ID(N'[org].[TR_DESCO_Persona_Unicidad]', N'TR') IS NOT NULL
    DROP TRIGGER [org].[TR_DESCO_Persona_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : org.TR_DESCO_Persona_Unicidad
' Descripción              : Controla la unicidad de personas.
' Tabla asociada          : org.Persona
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre org.Persona.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[org].[TR_DESCO_Persona_Unicidad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER org.TR_DESCO_Persona_Unicidad ON org.Persona AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.persona_id=I.persona_id
  WHERE I.documento_clave_desco IS NOT NULL
    AND (D.persona_id IS NULL OR ISNULL(I.documento_clave_desco,'')<>ISNULL(D.documento_clave_desco,''))
    AND EXISTS(SELECT 1 FROM org.Persona X WITH(UPDLOCK,HOLDLOCK) WHERE X.documento_clave_desco=I.documento_clave_desco AND X.persona_id<>I.persona_id)
 ) THROW 51021,N'El documento ya está registrado.',1;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.persona_id=I.persona_id
  WHERE I.correo_clave_desco IS NOT NULL AND I.correo<>''
    AND (D.persona_id IS NULL OR ISNULL(I.correo_clave_desco,'')<>ISNULL(D.correo_clave_desco,''))
    AND EXISTS(SELECT 1 FROM org.Persona X WITH(UPDLOCK,HOLDLOCK) WHERE X.correo_clave_desco=I.correo_clave_desco AND X.persona_id<>I.persona_id)
 ) THROW 51022,N'El correo ya está registrado.',1;
END;
GO
