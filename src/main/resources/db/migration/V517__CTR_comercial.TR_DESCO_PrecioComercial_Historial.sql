IF OBJECT_ID(N'[comercial].[TR_DESCO_PrecioComercial_Historial]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_PrecioComercial_Historial];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_DESCO_PrecioComercial_Historial
' Descripción            : Protege la integridad del historial de precios comerciales.
' Aplicativo / Módulo    : DESCO / Comercial
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
