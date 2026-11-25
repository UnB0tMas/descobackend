IF OBJECT_ID(N'[campo].[SalidaResponsableUOT]', N'U') IS NOT NULL
    DROP TABLE [campo].[SalidaResponsableUOT];
GO

-- Responsables vigentes por UOT; las identidades y los permisos siguen en seg/org.
CREATE TABLE campo.SalidaResponsableUOT
(
    responsable_uot_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
    usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    funcion VARCHAR(20) NOT NULL,
    prioridad SMALLINT NOT NULL CONSTRAINT DF_SalidaResponsable_Prioridad DEFAULT (1),
    suplente BIT NOT NULL CONSTRAINT DF_SalidaResponsable_Suplente DEFAULT (0),
    fecha_desde DATETIME2(0) NOT NULL CONSTRAINT DF_SalidaResponsable_Desde DEFAULT SYSUTCDATETIME(),
    fecha_hasta DATETIME2(0) NULL,
    estado BIT NOT NULL CONSTRAINT DF_SalidaResponsable_Estado DEFAULT (1),
    actualizado_por BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
    fecha_actualizacion DATETIME2(0) NOT NULL CONSTRAINT DF_SalidaResponsable_Actualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_SalidaResponsable_Funcion CHECK (funcion IN ('APROBADOR','ENTREGA','INSPECTOR')),
    CONSTRAINT CK_SalidaResponsable_Prioridad CHECK (prioridad BETWEEN 1 AND 100),
    CONSTRAINT CK_SalidaResponsable_Vigencia CHECK (fecha_hasta IS NULL OR fecha_hasta > fecha_desde),
    CONSTRAINT UQ_SalidaResponsable_Identidad UNIQUE(uot_id, funcion, usuario_id)
);
GO

CREATE INDEX IX_SalidaResponsable_Vigente
    ON campo.SalidaResponsableUOT(uot_id, funcion, estado, suplente, prioridad, fecha_desde);
GO
