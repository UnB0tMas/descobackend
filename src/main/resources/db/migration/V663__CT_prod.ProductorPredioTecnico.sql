IF OBJECT_ID(N'[prod].[ProductorPredioTecnico]', N'U') IS NOT NULL
    DROP TABLE [prod].[ProductorPredioTecnico];
GO

-- Relación interna para parcelas directas; no reemplaza predios históricos.
CREATE TABLE prod.ProductorPredioTecnico
(
    persona_id BIGINT NOT NULL,
    uot_id BIGINT NOT NULL,
    predio_id BIGINT NOT NULL,
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_GP_ProductorPredioTecnico_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_GP_ProductorPredioTecnico PRIMARY KEY (persona_id, uot_id),
    CONSTRAINT UQ_GP_ProductorPredioTecnico_Predio UNIQUE (predio_id),
    CONSTRAINT FK_GP_ProductorPredioTecnico_Persona FOREIGN KEY (persona_id) REFERENCES org.Persona(persona_id),
    CONSTRAINT FK_GP_ProductorPredioTecnico_Uot FOREIGN KEY (uot_id) REFERENCES org.UOT(uot_id),
    CONSTRAINT FK_GP_ProductorPredioTecnico_Predio FOREIGN KEY (predio_id) REFERENCES prod.Predio(predio_id)
);
GO
