IF OBJECT_ID(N'[org].[TR_DESCO_Empresa_Unicidad]', N'TR') IS NOT NULL
    DROP TRIGGER [org].[TR_DESCO_Empresa_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : org.TR_DESCO_Empresa_Unicidad
' Descripción              : Controla la unicidad de empresas.
' Tabla asociada          : org.Empresa
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre org.Empresa.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[org].[TR_DESCO_Empresa_Unicidad]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER org.TR_DESCO_Empresa_Unicidad ON org.Empresa AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.empresa_id=I.empresa_id
  WHERE I.correo_clave_desco IS NOT NULL AND I.correo<>''
    AND (D.empresa_id IS NULL OR ISNULL(I.correo_clave_desco,'')<>ISNULL(D.correo_clave_desco,''))
    AND EXISTS(SELECT 1 FROM org.Empresa X WITH(UPDLOCK,HOLDLOCK) WHERE X.correo_clave_desco=I.correo_clave_desco AND X.empresa_id<>I.empresa_id)
 ) THROW 51023,N'El correo ya está registrado.',1;
END;
GO
