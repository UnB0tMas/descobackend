IF OBJECT_ID(N'[comercial].[TR_Venta_ComprobanteExclusivoFactura]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_Venta_ComprobanteExclusivoFactura];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_Venta_ComprobanteExclusivoFactura
' Descripción            : Evita comprobantes de venta incompatibles o duplicados entre factura y boleta.
' Aplicativo / Módulo    : DESCO / Comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_Venta_ComprobanteExclusivoFactura
ON comercial.Factura AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.Boleta B ON B.venta_id=I.venta_id AND B.estado=1 WHERE I.estado=1)
        THROW 51041,N'La venta ya tiene una boleta activa.',1;
END;
GO
