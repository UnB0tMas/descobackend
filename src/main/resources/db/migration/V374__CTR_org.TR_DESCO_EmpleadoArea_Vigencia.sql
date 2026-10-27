IF OBJECT_ID(N'[org].[TR_DESCO_EmpleadoArea_Vigencia]', N'TR') IS NOT NULL
    DROP TRIGGER [org].[TR_DESCO_EmpleadoArea_Vigencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : org.TR_DESCO_EmpleadoArea_Vigencia
' Descripción              : Controla la vigencia de asignaciones de empleados a áreas.
' Tabla asociada          : org.EmpleadoArea
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre org.EmpleadoArea.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[org].[TR_DESCO_EmpleadoArea_Vigencia]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER org.TR_DESCO_EmpleadoArea_Vigencia ON org.EmpleadoArea AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.empleado_area_id=I.empleado_area_id
  WHERE I.estado=1 AND I.fecha_hasta IS NULL
    AND (D.empleado_area_id IS NULL OR I.empleado_id<>D.empleado_id OR I.estado<>D.estado OR ISNULL(I.fecha_hasta,'99991231')<>ISNULL(D.fecha_hasta,'99991231'))
    AND EXISTS(SELECT 1 FROM org.EmpleadoArea X WITH(UPDLOCK,HOLDLOCK) WHERE X.empleado_id=I.empleado_id AND X.estado=1 AND X.fecha_hasta IS NULL AND X.empleado_area_id<>I.empleado_area_id)
 ) THROW 51027,N'El empleado ya tiene una asignación de área vigente.',1;
END;
GO
