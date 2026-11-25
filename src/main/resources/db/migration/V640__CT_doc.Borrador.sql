-- Borradores individuales sin efectos sobre conversaciones ni notificaciones.
IF OBJECT_ID(N'doc.Borrador',N'U') IS NULL
BEGIN
    CREATE TABLE doc.Borrador
    (
        borrador_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DocBorrador PRIMARY KEY,
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        hilo_id BIGINT NULL REFERENCES doc.Hilo(hilo_id),
        contenido NVARCHAR(MAX) NOT NULL,
        fecha_actualizacion DATETIME2(0) NOT NULL CONSTRAINT DF_DocBorrador_Fecha DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_DocBorrador_Json CHECK (ISJSON(contenido)=1)
    );
    CREATE INDEX IX_DocBorrador_Usuario ON doc.Borrador(usuario_id,fecha_actualizacion DESC);
END;
GO
