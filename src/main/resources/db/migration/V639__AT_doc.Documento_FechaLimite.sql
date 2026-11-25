-- Fecha límite opcional; conserva todos los mensajes existentes.
IF COL_LENGTH(N'doc.Documento',N'fecha_limite') IS NULL
BEGIN
    ALTER TABLE doc.Documento ADD fecha_limite DATETIME2(0) NULL;
END;
GO
