IF OBJECT_ID(N'[prod].[GPProductorSolicitud]', N'U') IS NOT NULL
    DROP TABLE [prod].[GPProductorSolicitud];
GO

-- Control de reintentos para modificación y retiro del productor.
CREATE TABLE prod.GPProductorSolicitud
(
    solicitud_id UNIQUEIDENTIFIER NOT NULL,
    accion VARCHAR(16) NOT NULL,
    persona_id BIGINT NOT NULL,
    uot_id BIGINT NOT NULL,
    hash_datos VARBINARY(32) NOT NULL,
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_GP_ProductorSolicitud_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_GP_ProductorSolicitud PRIMARY KEY (solicitud_id)
);
GO
