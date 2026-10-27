IF OBJECT_ID(N'[comercial].[TR_Venta_ComprobanteExclusivoFactura]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_Venta_ComprobanteExclusivoFactura];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_Venta_ComprobanteExclusivoFactura
' Descripción              : Evita comprobantes de venta incompatibles o duplicados entre factura y boleta.
' Tabla asociada          : comercial.Factura
' Evento que lo dispara   : AFTER INSERT,UPDATE
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de consulta/verificación:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre comercial.Factura.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_Venta_ComprobanteExclusivoFactura]', N'TR');
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
