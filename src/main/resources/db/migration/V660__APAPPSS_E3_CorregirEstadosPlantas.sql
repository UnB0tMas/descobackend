-- APAPPSS E3: el estado SIN_EVALUAR debe ser activo al crear plantas.
-- ELIMINADA es inactivo; SANA y ENFERMA son activos; MUERTA es inactivo.
SET XACT_ABORT ON;
GO
IF OBJECT_ID(N'prod.PlantaPaltaE3', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE parent_object_id = OBJECT_ID(N'prod.PlantaPaltaE3')
          AND name = N'CK_E3_PlantaActivo'
    )
        ALTER TABLE prod.PlantaPaltaE3 DROP CONSTRAINT CK_E3_PlantaActivo;

    ALTER TABLE prod.PlantaPaltaE3 WITH CHECK
    ADD CONSTRAINT CK_E3_PlantaActivo CHECK (
        (estado_actual IN ('SIN_EVALUAR', 'SANA', 'ENFERMA') AND activo = 1)
        OR (estado_actual IN ('MUERTA', 'ELIMINADA') AND activo = 0)
    );
END;
GO
