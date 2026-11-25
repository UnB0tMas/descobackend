/* Comprobante congelado por turno para consulta y reimpresión fiel. */
IF OBJECT_ID(N'comercial.CajaCierreReporte', N'U') IS NOT NULL
BEGIN
    DROP TABLE comercial.CajaCierreReporte;
END;
GO
CREATE TABLE comercial.CajaCierreReporte
(
    caja_sesion_id BIGINT NOT NULL,
    reporte_json NVARCHAR(MAX) NOT NULL,
    usuario_cierre_id BIGINT NOT NULL,
    fecha_registro DATETIME2(0) NOT NULL
        CONSTRAINT DF_CajaCierreReporte_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_CajaCierreReporte PRIMARY KEY (caja_sesion_id),
    CONSTRAINT FK_CajaCierreReporte_Sesion FOREIGN KEY (caja_sesion_id)
        REFERENCES comercial.CajaSesion(caja_sesion_id),
    CONSTRAINT CK_CajaCierreReporte_Json CHECK (ISJSON(reporte_json) = 1)
);
GO
