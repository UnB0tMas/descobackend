-- Control de cargas iniciales no repetibles, independiente de la operación diaria.
IF OBJECT_ID(N'[config].[CargaInicial]', N'U') IS NULL
BEGIN
    CREATE TABLE config.CargaInicial
    (
        codigo VARCHAR(80) NOT NULL CONSTRAINT PK_CargaInicial PRIMARY KEY,
        fecha_utc DATETIME2(0) NOT NULL CONSTRAINT DF_CargaInicial_Fecha DEFAULT SYSUTCDATETIME()
    );
END;
GO
