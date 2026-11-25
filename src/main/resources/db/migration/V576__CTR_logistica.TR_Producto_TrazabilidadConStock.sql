IF OBJECT_ID(N'[logistica].[TR_Producto_TrazabilidadConStock]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_Producto_TrazabilidadConStock];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_Producto_TrazabilidadConStock
' Descripción            : Controla las modificaciones de producto trazabilidad con stock mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE   TRIGGER logistica.TR_Producto_TrazabilidadConStock
ON logistica.Producto AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT (UPDATE(unidad_medida) OR UPDATE(requiere_lote) OR UPDATE(controla_vencimiento)) RETURN;
    IF EXISTS (
        SELECT 1 FROM inserted I INNER JOIN deleted D ON D.producto_id=I.producto_id
        WHERE (I.unidad_medida<>D.unidad_medida OR I.requiere_lote<>D.requiere_lote OR I.controla_vencimiento<>D.controla_vencimiento)
          AND EXISTS (SELECT 1 FROM logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK)
                      WHERE S.producto_id=I.producto_id AND (S.stock_actual>0 OR S.stock_reservado>0))
    ) THROW 51080,N'No puede cambiar la unidad, el control de lotes ni el vencimiento mientras exista stock o reservas.',1;
END;
GO
