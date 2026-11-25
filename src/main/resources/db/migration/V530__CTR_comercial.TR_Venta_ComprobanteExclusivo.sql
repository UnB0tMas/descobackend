IF OBJECT_ID(N'[comercial].[TR_Venta_ComprobanteExclusivo]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_Venta_ComprobanteExclusivo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_Venta_ComprobanteExclusivo
' Descripción            : Evita comprobantes de venta incompatibles o duplicados entre boleta y factura.
' Aplicativo / Módulo    : DESCO / Comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_Venta_ComprobanteExclusivo
ON comercial.Boleta AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.Factura F ON F.venta_id=I.venta_id AND F.estado=1 WHERE I.estado=1)
        THROW 51040,N'La venta ya tiene una factura activa.',1;
END;
GO
