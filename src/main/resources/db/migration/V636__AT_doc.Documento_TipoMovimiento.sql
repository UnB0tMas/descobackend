-- Tipo de mensaje y solicitud expresa de respuesta; datos históricos conservados.
IF COL_LENGTH(N'doc.Documento',N'tipo_movimiento') IS NULL
BEGIN
    ALTER TABLE doc.Documento ADD tipo_movimiento VARCHAR(20) NOT NULL
        CONSTRAINT DF_DocDocumento_TipoMovimiento DEFAULT ('ENVIO');
END;
IF COL_LENGTH(N'doc.Documento',N'requiere_respuesta') IS NULL
BEGIN
    ALTER TABLE doc.Documento ADD requiere_respuesta BIT NOT NULL
        CONSTRAINT DF_DocDocumento_RequiereRespuesta DEFAULT (0);
END;
GO
