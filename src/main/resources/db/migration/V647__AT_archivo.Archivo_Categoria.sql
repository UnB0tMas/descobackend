-- Incluye CORRESPONDENCIA en las categorías válidas; los binarios siguen en almacenamiento local.
IF OBJECT_ID(N'[archivo].[Archivo]', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.check_constraints CC WITH (NOLOCK)
        WHERE CC.parent_object_id = OBJECT_ID(N'[archivo].[Archivo]', N'U')
          AND CC.name = N'CK_Archivo_Categoria'
    )
    BEGIN
        ALTER TABLE [archivo].[Archivo]
            DROP CONSTRAINT [CK_Archivo_Categoria];
    END;

    ALTER TABLE [archivo].[Archivo] WITH CHECK
        ADD CONSTRAINT [CK_Archivo_Categoria]
        CHECK (
            [categoria] IS NULL OR
            [categoria] IN ('OTRO', 'COMPROBANTE', 'TICKET', 'DOCUMENTO', 'FOTOGRAFIA', 'CORRESPONDENCIA')
        );
END;
GO
