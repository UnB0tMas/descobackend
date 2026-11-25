IF OBJECT_ID(N'[logistica].[TR_DESCO_Almacen_ExclusividadUOT]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_Almacen_ExclusividadUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DESCO_Almacen_ExclusividadUOT
' Descripción            : Impide dar acceso activo de un almacén a una UOT ajena.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_Almacen_ExclusividadUOT
ON logistica.AlmacenUOT AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.Almacen A ON A.almacen_id=I.almacen_id
  WHERE I.estado=1 AND (I.fecha_hasta IS NULL OR I.fecha_hasta>SYSUTCDATETIME()) AND I.uot_id<>A.uot_propietaria_id)
   THROW 51210,N'El almacén solo puede ser utilizado por su UOT propietaria.',1;
END;
GO
