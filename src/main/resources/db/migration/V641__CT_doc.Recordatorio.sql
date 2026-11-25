-- Se registra cada aviso sin duplicar encargos ni documentos.
IF OBJECT_ID(N'doc.Recordatorio',N'U') IS NULL
BEGIN
    CREATE TABLE doc.Recordatorio
    (
        recordatorio_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DocRecordatorio PRIMARY KEY,
        documento_id BIGINT NOT NULL REFERENCES doc.Documento(documento_id),
        emisor_usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        destinatario_usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_envio DATETIME2(0) NOT NULL CONSTRAINT DF_DocRecordatorio_Fecha DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_DocRecordatorio_Limite ON doc.Recordatorio(documento_id,destinatario_usuario_id,fecha_envio DESC);
END;
GO
