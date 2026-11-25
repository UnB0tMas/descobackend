IF OBJECT_ID(N'[campo].[SalidaDocumentoVinculo]', N'U') IS NOT NULL
    DROP TABLE [campo].[SalidaDocumentoVinculo];
GO

-- Un expediente E2 general corresponde a un solo hilo documental existente.
CREATE TABLE campo.SalidaDocumentoVinculo
(
    salida_campo_id BIGINT NOT NULL PRIMARY KEY REFERENCES campo.SalidaE2(salida_campo_id),
    documento_origen_id BIGINT NOT NULL UNIQUE REFERENCES doc.Documento(documento_id),
    hilo_id BIGINT NOT NULL UNIQUE REFERENCES doc.Hilo(hilo_id),
    uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
    clave_idempotencia UNIQUEIDENTIFIER NOT NULL UNIQUE,
    hash_peticion VARBINARY(32) NOT NULL,
    fecha_vinculo DATETIME2(0) NOT NULL CONSTRAINT DF_SalidaDocVinculo_Fecha DEFAULT SYSUTCDATETIME()
);
GO
