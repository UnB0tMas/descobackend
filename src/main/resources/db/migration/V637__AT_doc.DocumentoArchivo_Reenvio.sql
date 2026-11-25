-- Un archivo de un mensaje puede conservarse también en sus reenvíos.
IF EXISTS (SELECT 1 FROM sys.key_constraints
    WHERE name=N'UQ_DocDocumentoArchivo_Archivo' AND parent_object_id=OBJECT_ID(N'doc.DocumentoArchivo'))
BEGIN
    ALTER TABLE doc.DocumentoArchivo DROP CONSTRAINT UQ_DocDocumentoArchivo_Archivo;
END;
GO
