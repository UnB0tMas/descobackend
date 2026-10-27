IF OBJECT_ID(N'[comercial].[TR_DESCO_PrecioComercial_Historial]', N'TR') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_PrecioComercial_Historial];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Trigger           : comercial.TR_DESCO_PrecioComercial_Historial
' Descripción              : Protege la integridad del historial de precios comerciales.
' Tabla asociada          : comercial.PrecioComercial
' Evento que lo dispara   : AFTER UPDATE,DELETE
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
    -- Se ejecuta automáticamente mediante AFTER UPDATE,DELETE sobre comercial.PrecioComercial.
    -- Verificar existencia/estado sin modificar información:
    SELECT T.name, T.is_disabled
    FROM sys.triggers AS T
    WHERE T.object_id = OBJECT_ID(N'[comercial].[TR_DESCO_PrecioComercial_Historial]', N'TR');
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_PrecioComercial_Historial
ON comercial.PrecioComercial AFTER UPDATE,DELETE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.precio_comercial_id=D.precio_comercial_id
  WHERE (I.precio_comercial_id IS NULL OR I.moneda<>D.moneda OR I.precio<>D.precio OR I.unidad_medida<>D.unidad_medida
   OR I.campania_venta_id<>D.campania_venta_id OR ISNULL(I.operativo_venta_id,0)<>ISNULL(D.operativo_venta_id,0)
   OR I.variedad_palta_id<>D.variedad_palta_id OR I.condicion_comercial_id<>D.condicion_comercial_id)
  AND EXISTS(SELECT 1 FROM comercial.EntregaDetalle E WHERE E.precio_comercial_id=D.precio_comercial_id))
  THROW 51000,N'El precio ya fue utilizado. Registre una nueva versión.',1;
END;
GO
