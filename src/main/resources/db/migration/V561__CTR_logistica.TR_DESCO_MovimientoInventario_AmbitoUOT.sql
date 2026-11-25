IF OBJECT_ID(N'[logistica].[TR_DESCO_MovimientoInventario_AmbitoUOT]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_MovimientoInventario_AmbitoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DESCO_MovimientoInventario_AmbitoUOT
' Descripción            : Valida pertenencia UOT de todo movimiento registrado.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_MovimientoInventario_AmbitoUOT
ON logistica.MovimientoInventario AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.Almacen A ON A.almacen_id=I.almacen_id
 WHERE I.uot_id<>A.uot_propietaria_id)
   THROW 51212,N'El movimiento no pertenece a la UOT del almacén.',1;
END;
GO
