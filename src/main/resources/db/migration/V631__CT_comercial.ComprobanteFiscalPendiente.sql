-- Registro persistente de datos fiscales por venta; sin fingir aceptación tributaria.
IF OBJECT_ID(N'comercial.ComprobanteFiscalPendiente', N'U') IS NOT NULL
    DROP TABLE comercial.ComprobanteFiscalPendiente;
GO
CREATE TABLE comercial.ComprobanteFiscalPendiente
(
    venta_id BIGINT NOT NULL,
    uot_id BIGINT NOT NULL,
    tipo_documento VARCHAR(10) NULL,
    serie VARCHAR(10) NULL,
    numero BIGINT NULL,
    estado_fiscal VARCHAR(24) NOT NULL CONSTRAINT DF_ComprobanteFiscalPendiente_Estado DEFAULT ('PENDIENTE'),
    datos_json NVARCHAR(MAX) NULL,
    documento_json NVARCHAR(MAX) NULL,
    qr_contenido NVARCHAR(2000) NULL,
    hash_sunat VARCHAR(200) NULL,
    cdr_xml NVARCHAR(MAX) NULL,
    xml_firmado NVARCHAR(MAX) NULL,
    codigo_respuesta VARCHAR(60) NULL,
    mensaje_respuesta NVARCHAR(500) NULL,
    fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_ComprobanteFiscalPendiente_Creacion DEFAULT (SYSUTCDATETIME()),
    fecha_actualizacion DATETIME2(0) NULL,
    fecha_envio DATETIME2(0) NULL,
    fecha_aceptacion DATETIME2(0) NULL,
    CONSTRAINT PK_ComprobanteFiscalPendiente PRIMARY KEY (venta_id),
    CONSTRAINT FK_ComprobanteFiscalPendiente_Venta FOREIGN KEY (venta_id) REFERENCES comercial.Venta(venta_id),
    CONSTRAINT CK_ComprobanteFiscalPendiente_Estado CHECK (estado_fiscal IN
        ('PENDIENTE','ENVIANDO','ACEPTADO','OBSERVADO','RECHAZADO'))
);
GO
