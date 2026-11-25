-- Registro independiente de lectura y atención del destinatario.
IF COL_LENGTH(N'doc.Destinatario',N'fecha_atencion') IS NULL
BEGIN
    ALTER TABLE doc.Destinatario ADD fecha_atencion DATETIME2(0) NULL;
END;
GO
