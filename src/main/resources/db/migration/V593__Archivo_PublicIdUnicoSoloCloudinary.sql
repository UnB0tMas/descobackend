/* SQL Server admite un único NULL en una restricción UNIQUE.
   Los archivos locales no tienen public_id de Cloudinary; su unicidad solo aplica a valores presentes. */
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'archivo.Archivo') AND name=N'UQ_Archivo_PublicId')
    ALTER TABLE archivo.Archivo DROP CONSTRAINT UQ_Archivo_PublicId;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'archivo.Archivo') AND name=N'UX_Archivo_PublicIdPresente')
    CREATE UNIQUE INDEX UX_Archivo_PublicIdPresente ON archivo.Archivo(cloudinary_public_id) WHERE cloudinary_public_id IS NOT NULL;
GO
