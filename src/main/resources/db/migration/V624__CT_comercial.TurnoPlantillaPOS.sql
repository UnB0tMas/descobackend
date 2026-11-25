-- Catálogo de turnos reutilizables por UOT. Nunca elimina horarios ya asignados.
IF OBJECT_ID(N'[comercial].[TurnoPlantillaPOS]', N'U') IS NULL
BEGIN
    CREATE TABLE comercial.TurnoPlantillaPOS
    (
        turno_plantilla_id BIGINT IDENTITY(1,1) NOT NULL,
        uot_id BIGINT NOT NULL,
        nombre NVARCHAR(80) NOT NULL,
        hora_inicio TIME(0) NOT NULL,
        hora_fin TIME(0) NOT NULL,
        estado BIT NOT NULL CONSTRAINT DF_TurnoPlantillaPOS_Estado DEFAULT(1),
        usuario_registro_id BIGINT NOT NULL,
        fecha_registro DATETIME2(3) NOT NULL CONSTRAINT DF_TurnoPlantillaPOS_Fecha DEFAULT SYSUTCDATETIME(),
        usuario_actualizacion_id BIGINT NULL,
        fecha_actualizacion DATETIME2(3) NULL,
        CONSTRAINT PK_TurnoPlantillaPOS PRIMARY KEY (turno_plantilla_id),
        CONSTRAINT FK_TurnoPlantillaPOS_UOT FOREIGN KEY (uot_id) REFERENCES org.UOT(uot_id),
        CONSTRAINT CK_TurnoPlantillaPOS_Horas CHECK (hora_inicio < hora_fin)
    );

    CREATE UNIQUE INDEX UX_TurnoPlantillaPOS_UOT_Nombre
        ON comercial.TurnoPlantillaPOS(uot_id, nombre)
        WHERE estado = 1;
END;
GO
