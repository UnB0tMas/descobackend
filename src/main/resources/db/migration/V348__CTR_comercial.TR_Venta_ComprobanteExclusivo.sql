IF OBJECT_ID(N'[comercial].[TR_Venta_ComprobanteExclusivo]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_Venta_ComprobanteExclusivo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_Venta_ComprobanteExclusivo
' Descripción              : Evita comprobantes de venta incompatibles o duplicados entre boleta y factura.
' Tabla asociada          : comercial.Boleta
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
    -- Se ejecuta automáticamente mediante AFTER INSERT,UPDATE sobre comercial.Boleta.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_Venta_ComprobanteExclusivo]', N'TR');
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
