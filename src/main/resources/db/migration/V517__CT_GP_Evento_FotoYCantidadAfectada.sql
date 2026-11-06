-- GP general: incidencia agregada y fotografia en almacenamiento local; APAPPSS independiente.
IF COL_LENGTH('prod.GPEvento', 'cantidad_afectada') IS NULL
  ALTER TABLE prod.GPEvento ADD cantidad_afectada INT NULL;
GO
IF COL_LENGTH('prod.GPEvento', 'afectados_aproximado') IS NULL
  ALTER TABLE prod.GPEvento ADD afectados_aproximado BIT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('prod.GPEvento') AND name='CK_GPEvento_CantidadAfectada')
  ALTER TABLE prod.GPEvento ADD CONSTRAINT CK_GPEvento_CantidadAfectada CHECK (
      (cantidad_afectada IS NULL AND afectados_aproximado IS NULL) OR
      (cantidad_afectada >= 0 AND afectados_aproximado IS NOT NULL));
GO
IF OBJECT_ID('prod.GPEventoFoto','U') IS NULL
BEGIN
 CREATE TABLE prod.GPEventoFoto (
   foto_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GPEventoFoto PRIMARY KEY,
   evento_id BIGINT NOT NULL CONSTRAINT FK_GPEventoFoto_Evento REFERENCES prod.GPEvento(evento_id),
   archivo_interno VARCHAR(65) NOT NULL,
   mime_type VARCHAR(30) NOT NULL,
   tamano_bytes BIGINT NOT NULL,
   usuario_creacion_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
   fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
   CONSTRAINT UQ_GPEventoFoto_Evento UNIQUE(evento_id),
   CONSTRAINT UQ_GPEventoFoto_Archivo UNIQUE(archivo_interno),
   CONSTRAINT CK_GPEventoFoto_Tamano CHECK(tamano_bytes>0 AND tamano_bytes<=5242880),
   CONSTRAINT CK_GPEventoFoto_Mime CHECK(mime_type IN('image/jpeg','image/png','image/webp'))
 );
END;
GO
