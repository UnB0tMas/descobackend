IF OBJECT_ID(N'[org].[TR_EmpleadoArea_ValidarUOT]') IS NOT NULL
    DROP TRIGGER [org].[TR_EmpleadoArea_ValidarUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : org.TR_EmpleadoArea_ValidarUOT
' Descripción            : Valida la UOT asociada a las asignaciones de empleados.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE TRIGGER org.TR_EmpleadoArea_ValidarUOT
ON org.EmpleadoArea
AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
   SELECT 1 FROM inserted I
   JOIN org.Area A ON A.area_id=I.area_id
   WHERE I.estado=1 AND I.fecha_hasta IS NULL
     AND NOT EXISTS(SELECT 1 FROM org.EmpleadoUOT EU WHERE EU.empleado_id=I.empleado_id AND EU.uot_id=A.uot_id AND EU.estado=1 AND EU.fecha_hasta IS NULL)
 ) THROW 51090,N'El empleado no pertenece a la UOT del area seleccionada.',1;
END;
GO
