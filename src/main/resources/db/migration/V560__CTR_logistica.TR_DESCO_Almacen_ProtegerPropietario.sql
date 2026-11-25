IF OBJECT_ID(N'[logistica].[TR_DESCO_Almacen_ProtegerPropietario]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_Almacen_ProtegerPropietario];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DESCO_Almacen_ProtegerPropietario
' Descripción            : Protege la UOT propietaria cuando existen operaciones históricas.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_Almacen_ProtegerPropietario
ON logistica.Almacen AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.almacen_id=I.almacen_id
  WHERE I.uot_propietaria_id<>D.uot_propietaria_id)
   THROW 51211,N'No se puede modificar la UOT propietaria de un almacén.',1;
END;
GO
