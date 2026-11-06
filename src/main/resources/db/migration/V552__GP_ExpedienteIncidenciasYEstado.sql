-- DESCO GP | migracion aditiva, historiales inmutables.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF COL_LENGTH('prod.GPActividad','estado_proceso') IS NULL
 ALTER TABLE prod.GPActividad ADD estado_proceso VARCHAR(15) NOT NULL
 CONSTRAINT DF_GPActividad_EstadoProceso DEFAULT 'ACTIVA';
GO
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('prod.GPActividad') AND name='CK_GPActividad_EstadoProceso')
 ALTER TABLE prod.GPActividad ADD CONSTRAINT CK_GPActividad_EstadoProceso CHECK(estado_proceso IN('ACTIVA','FINALIZADA'));
GO
IF OBJECT_ID('prod.GPIncidencia','U') IS NULL
BEGIN
 CREATE TABLE prod.GPIncidencia(
   incidencia_id BIGINT NOT NULL CONSTRAINT PK_GPIncidencia PRIMARY KEY
     CONSTRAINT FK_GPIncidencia_Evento REFERENCES prod.GPEvento(evento_id),
   actividad_id BIGINT NOT NULL CONSTRAINT FK_GPIncidencia_Actividad REFERENCES prod.GPActividad(actividad_id),
   problema_id INT NOT NULL REFERENCES prod.GPProblema(problema_id),
   afectada_m2 DECIMAL(14,2) NULL,
   afectados_animales INT NULL,
   estado BIT NOT NULL DEFAULT 1,
   estado_seguimiento VARCHAR(12) NOT NULL DEFAULT 'ABIERTA',
   resultado VARCHAR(18) NULL,
   perdida_m2 DECIMAL(14,2) NULL,
   perdidos_animales INT NULL,
   descripcion_cierre NVARCHAR(2000) NULL,
   fecha_cierre DATETIME2(0) NULL,
   usuario_cierre_id BIGINT NULL REFERENCES seg.Usuario(usuario_id),
   solicitud_cierre UNIQUEIDENTIFIER NULL,
   CONSTRAINT CK_GPIncidencia_Estado CHECK(estado_seguimiento IN('ABIERTA','CERRADA')),
   CONSTRAINT CK_GPIncidencia_Resultado CHECK(resultado IS NULL OR resultado IN('RECUPERADA','PERDIDA_PARCIAL','PERDIDA_TOTAL')),
   CONSTRAINT CK_GPIncidencia_Afectacion CHECK ((afectada_m2>0 AND afectados_animales IS NULL) OR
     (afectados_animales>0 AND afectada_m2 IS NULL)),
   CONSTRAINT CK_GPIncidencia_Perdida CHECK ((perdida_m2 IS NULL OR perdida_m2>=0) AND
     (perdidos_animales IS NULL OR perdidos_animales>=0))
 );
 CREATE INDEX IX_GPIncidencia_Actividad ON prod.GPIncidencia(actividad_id,estado_seguimiento,incidencia_id DESC);
 CREATE UNIQUE INDEX UX_GPIncidencia_SolicitudCierre ON prod.GPIncidencia(solicitud_cierre) WHERE solicitud_cierre IS NOT NULL;
END;
GO
IF OBJECT_ID('prod.GPIncidenciaTratamiento','U') IS NULL
BEGIN
 CREATE TABLE prod.GPIncidenciaTratamiento(
   evento_id BIGINT NOT NULL CONSTRAINT PK_GPIncidenciaTratamiento PRIMARY KEY REFERENCES prod.GPEvento(evento_id),
   incidencia_id BIGINT NOT NULL REFERENCES prod.GPIncidencia(incidencia_id),
   estado BIT NOT NULL DEFAULT 1,
   tratamiento_id INT NOT NULL REFERENCES prod.GPTratamiento(tratamiento_id),
   fecha_inicio DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
   fecha_fin_prevista DATETIME2(0) NULL,
   fecha_fin_real DATETIME2(0) NULL,
   descripcion_cierre NVARCHAR(1000) NULL,
   usuario_cierre_id BIGINT NULL REFERENCES seg.Usuario(usuario_id),
   solicitud_cierre UNIQUEIDENTIFIER NULL,
   CONSTRAINT CK_GPIncTrat_Fechas CHECK((fecha_fin_prevista IS NULL OR fecha_fin_prevista>=fecha_inicio)
       AND (fecha_fin_real IS NULL OR fecha_fin_real>=fecha_inicio))
 );
 CREATE INDEX IX_GPIncTrat_Incidencia ON prod.GPIncidenciaTratamiento(incidencia_id,fecha_inicio DESC);
 CREATE UNIQUE INDEX UX_GPIncTrat_SolicitudCierre ON prod.GPIncidenciaTratamiento(solicitud_cierre) WHERE solicitud_cierre IS NOT NULL;
END;
GO
IF OBJECT_ID('prod.GPBajaLogica','U') IS NULL
BEGIN
 CREATE TABLE prod.GPBajaLogica(
   baja_id BIGINT IDENTITY(1,1) PRIMARY KEY,
   tipo VARCHAR(12) NOT NULL CHECK(tipo IN('PREDIO','PARCELA','ACTIVIDAD')),
   registro_id BIGINT NOT NULL,
   motivo NVARCHAR(1000) NOT NULL,
   usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
   fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
   solicitud_id UNIQUEIDENTIFIER NOT NULL UNIQUE
 );
END;
GO
IF COL_LENGTH('prod.GPCenso','estado') IS NULL
 ALTER TABLE prod.GPCenso ADD estado BIT NOT NULL CONSTRAINT DF_GPCenso_Estado DEFAULT 1;
GO
IF COL_LENGTH('prod.GPEvento','estado') IS NULL
 ALTER TABLE prod.GPEvento ADD estado BIT NOT NULL CONSTRAINT DF_GPEvento_Estado DEFAULT 1;
GO
IF COL_LENGTH('prod.GPActividadRevision','estado') IS NULL
 ALTER TABLE prod.GPActividadRevision ADD estado BIT NOT NULL CONSTRAINT DF_GPActividadRevision_Estado DEFAULT 1;
GO
