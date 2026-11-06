-- E3: mediciones individuales de materia seca, con valores e historia inmutables.
-- Se agrega sin transformar censos históricos ni modificar V435/V436.
IF OBJECT_ID(N'prod.PlantaMedicionE3', N'U') IS NULL
BEGIN
    CREATE TABLE prod.PlantaMedicionE3 (
        medicion_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E3_Medicion PRIMARY KEY,
        planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
        visita_tecnica_id BIGINT NOT NULL REFERENCES campo.VisitaTecnica(visita_tecnica_id),
        porcentaje DECIMAL(6,3) NOT NULL,
        observacion NVARCHAR(1000) NULL,
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_hecho DATETIME2(0) NOT NULL,
        fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_E3_Medicion_Rango CHECK(porcentaje BETWEEN 0 AND 100)
    );
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'prod.PlantaMedicionE3')
   AND name=N'IX_E3_Medicion_PlantaFecha')
    CREATE INDEX IX_E3_Medicion_PlantaFecha ON prod.PlantaMedicionE3(planta_id, fecha_hecho DESC, medicion_id DESC);
GO
CREATE OR ALTER TRIGGER prod.TR_E3_MedicionInmutable
ON prod.PlantaMedicionE3 AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 51186, N'Las mediciones históricas no se pueden modificar ni eliminar.', 1;
END;
GO
