-- Un suministro puede reutilizar la identidad de un producto comercial por UOT.
IF COL_LENGTH(N'logistica.Suministro', N'producto_id') IS NULL
BEGIN
    ALTER TABLE logistica.Suministro ADD producto_id BIGINT NULL;
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Suministro_Producto')
BEGIN
    ALTER TABLE logistica.Suministro WITH CHECK ADD
        CONSTRAINT FK_Suministro_Producto FOREIGN KEY(producto_id)
        REFERENCES logistica.Producto(producto_id);
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes
              WHERE object_id = OBJECT_ID(N'logistica.Suministro')
                AND name = 'UX_Suministro_UOT_Producto')
BEGIN
    CREATE UNIQUE INDEX UX_Suministro_UOT_Producto
        ON logistica.Suministro(uot_id,producto_id)
        WHERE producto_id IS NOT NULL;
END;
