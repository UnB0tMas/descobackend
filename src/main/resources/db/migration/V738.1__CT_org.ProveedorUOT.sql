-- Catálogo de proveedores por UOT. La identidad permanece en org.Persona/org.Empresa.
IF OBJECT_ID(N'org.ProveedorUOT', N'U') IS NOT NULL
BEGIN
    DROP TABLE org.ProveedorUOT;
END;
GO
CREATE TABLE org.ProveedorUOT
(
    proveedor_uot_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProveedorUOT PRIMARY KEY,
    uot_id BIGINT NOT NULL,
    persona_id BIGINT NULL,
    empresa_id BIGINT NULL,
    estado BIT NOT NULL CONSTRAINT DF_ProveedorUOT_Estado DEFAULT (1),
    usuario_creacion_id BIGINT NOT NULL,
    fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_ProveedorUOT_Fecha DEFAULT (SYSUTCDATETIME()),
    usuario_actualizacion_id BIGINT NULL,
    fecha_actualizacion DATETIME2(0) NULL,
    CONSTRAINT CK_ProveedorUOT_Identidad CHECK
        ((CASE WHEN persona_id IS NULL THEN 0 ELSE 1 END) +
         (CASE WHEN empresa_id IS NULL THEN 0 ELSE 1 END) = 1),
    CONSTRAINT FK_ProveedorUOT_UOT FOREIGN KEY (uot_id) REFERENCES org.UOT(uot_id),
    CONSTRAINT FK_ProveedorUOT_Persona FOREIGN KEY (persona_id) REFERENCES org.Persona(persona_id),
    CONSTRAINT FK_ProveedorUOT_Empresa FOREIGN KEY (empresa_id) REFERENCES org.Empresa(empresa_id),
    CONSTRAINT FK_ProveedorUOT_Usuario FOREIGN KEY (usuario_creacion_id) REFERENCES seg.Usuario(usuario_id)
);
GO
CREATE UNIQUE INDEX UX_ProveedorUOT_Persona
    ON org.ProveedorUOT(uot_id, persona_id) WHERE persona_id IS NOT NULL;
GO
CREATE UNIQUE INDEX UX_ProveedorUOT_Empresa
    ON org.ProveedorUOT(uot_id, empresa_id) WHERE empresa_id IS NOT NULL;
GO
