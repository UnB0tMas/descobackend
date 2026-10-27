/* DESCO / catálogo compartido y elegibilidad comercial; migración no destructiva. */
IF COL_LENGTH('logistica.Producto', 'permite_venta') IS NULL
BEGIN
    ALTER TABLE [logistica].[Producto]
      ADD [permite_venta] BIT NOT NULL CONSTRAINT [DF_Producto_PermiteVenta] DEFAULT ((0));
END;
GO
/* Mantener vendibles los artículos que ya tenían precios históricos para no romper POS. */
UPDATE P SET permite_venta=1
FROM logistica.Producto P
WHERE P.permite_venta=0
AND EXISTS (SELECT 1 FROM logistica.ProductoPrecio PP WHERE PP.producto_id=P.producto_id);
GO
