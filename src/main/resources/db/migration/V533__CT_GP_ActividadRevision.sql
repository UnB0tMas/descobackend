-- Registro append-only de modificaciones de la información general de cada actividad.
IF OBJECT_ID(N'prod.GPActividadRevision',N'U') IS NULL
BEGIN
 CREATE TABLE prod.GPActividadRevision (
   revision_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPActividadRevision PRIMARY KEY,
   actividad_id BIGINT NOT NULL REFERENCES prod.GPActividad(actividad_id),
   nombre_anterior NVARCHAR(120) NULL,
   nombre_nuevo NVARCHAR(120) NULL,
   estado_anterior BIT NOT NULL,
   estado_nuevo BIT NOT NULL,
   motivo NVARCHAR(1000) NOT NULL,
   usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
   fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
   solicitud_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT UQ_GPActividadRevision_Solicitud UNIQUE
 );
 CREATE INDEX IX_GPActividadRevision_Actividad ON prod.GPActividadRevision(actividad_id,revision_id DESC);
END;
GO
