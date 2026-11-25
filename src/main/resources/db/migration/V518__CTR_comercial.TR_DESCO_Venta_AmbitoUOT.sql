IF OBJECT_ID(N'[comercial].[TR_DESCO_Venta_AmbitoUOT]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_Venta_AmbitoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_DESCO_Venta_AmbitoUOT
' Descripción            : Valida pertenencia UOT de ventas sobre almacenes.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_Venta_AmbitoUOT
ON comercial.Venta AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.Almacen A ON A.almacen_id=I.almacen_id
 WHERE I.uot_id<>A.uot_propietaria_id)
   THROW 51213,N'La venta no corresponde al almacén de la UOT.',1;
END;
GO
