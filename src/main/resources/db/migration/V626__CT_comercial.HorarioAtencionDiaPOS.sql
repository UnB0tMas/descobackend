-- Excepciones semanales de atención por UOT; los días restantes heredan el horario general.
IF OBJECT_ID(N'[comercial].[HorarioAtencionDiaPOS]', N'U') IS NULL
BEGIN
    CREATE TABLE comercial.HorarioAtencionDiaPOS
    (
        uot_id BIGINT NOT NULL,
        dia_semana TINYINT NOT NULL,
        hora_inicio TIME(0) NOT NULL,
        hora_fin TIME(0) NOT NULL,
        usuario_actualizacion_id BIGINT NOT NULL,
        fecha_actualizacion DATETIME2(3) NOT NULL CONSTRAINT DF_HorarioAtencionDiaPOS_Fecha DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_HorarioAtencionDiaPOS PRIMARY KEY (uot_id, dia_semana),
        CONSTRAINT FK_HorarioAtencionDiaPOS_UOT FOREIGN KEY (uot_id) REFERENCES org.UOT(uot_id),
        CONSTRAINT CK_HorarioAtencionDiaPOS_Dia CHECK (dia_semana BETWEEN 1 AND 7),
        CONSTRAINT CK_HorarioAtencionDiaPOS_Horas CHECK (hora_inicio < hora_fin)
    );
END;
GO
