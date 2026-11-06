-- E3. Expediente individual por árbol. No altera censos agregados ni plantas antiguas.
IF OBJECT_ID('prod.PlantaPaltaE3','U') IS NULL
BEGIN
 CREATE TABLE prod.PlantaPaltaE3 (
   planta_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E3_Planta PRIMARY KEY,
   predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
   uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
   convenio_id BIGINT NOT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
   variedad_palta_id SMALLINT NOT NULL REFERENCES prod.VariedadPalta(variedad_palta_id),
   parcela_cultivo_id BIGINT NULL REFERENCES prod.ParcelaCultivo(parcela_cultivo_id),
   secuencia INT NOT NULL,
   codigo VARCHAR(80) NOT NULL,
   estado_actual VARCHAR(16) NOT NULL CONSTRAINT DF_E3_PlantaEstado DEFAULT 'SIN_EVALUAR',
   fecha_plantacion DATE NULL,
   edad_referencia_anios SMALLINT NULL,
   fecha_referencia DATE NULL,
   creado_por_usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
   creado_en DATETIME2(0) NOT NULL CONSTRAINT DF_E3_PlantaFecha DEFAULT SYSUTCDATETIME(),
   version BIGINT NOT NULL CONSTRAINT DF_E3_PlantaVersion DEFAULT 0,
   CONSTRAINT CK_E3_PlantaEstado CHECK(estado_actual IN('SIN_EVALUAR','SANA','ENFERMA','MUERTA')),
   CONSTRAINT CK_E3_PlantaEdad CHECK(edad_referencia_anios IS NULL OR edad_referencia_anios BETWEEN 0 AND 200),
   CONSTRAINT UQ_E3_PlantaCodigo UNIQUE(codigo),
   CONSTRAINT UQ_E3_PlantaNumero UNIQUE(predio_id,variedad_palta_id,secuencia)
 );
END;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_E3_PlantaAmbito' AND object_id=OBJECT_ID('prod.PlantaPaltaE3'))
 CREATE INDEX IX_E3_PlantaAmbito ON prod.PlantaPaltaE3(convenio_id,uot_id,predio_id,variedad_palta_id,estado_actual,planta_id);
IF OBJECT_ID('prod.PlantaCorrelativoE3','U') IS NULL
 CREATE TABLE prod.PlantaCorrelativoE3(predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),variedad_palta_id SMALLINT NOT NULL REFERENCES prod.VariedadPalta(variedad_palta_id),ultimo INT NOT NULL,CONSTRAINT PK_E3_Correlativo PRIMARY KEY(predio_id,variedad_palta_id));
IF OBJECT_ID('prod.PlantaEventoE3','U') IS NULL
 CREATE TABLE prod.PlantaEventoE3(
  evento_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
  tipo VARCHAR(25) NOT NULL,
  estado_anterior VARCHAR(16) NULL,estado_nuevo VARCHAR(16) NULL,
  observacion NVARCHAR(1000) NULL,
  visita_tecnica_id BIGINT NULL REFERENCES campo.VisitaTecnica(visita_tecnica_id),
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_hecho DATETIME2(0) NOT NULL,
  fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  correlacion_id UNIQUEIDENTIFIER NULL,
  CONSTRAINT CK_E3_EventoTipo CHECK(tipo IN('ALTA','EVALUACION','FICHA','SEGUIMIENTO','TRATAMIENTO','PRODUCCION','EVIDENCIA'))
 );
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_E3_EventoPlanta' AND object_id=OBJECT_ID('prod.PlantaEventoE3'))
 CREATE INDEX IX_E3_EventoPlanta ON prod.PlantaEventoE3(planta_id,fecha_hecho DESC,evento_id DESC);
IF OBJECT_ID('sanidad.EpisodioPlantaE3','U') IS NULL
 CREATE TABLE sanidad.EpisodioPlantaE3(
  episodio_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
  tipo_problema_fitosanitario_id SMALLINT NOT NULL REFERENCES sanidad.TipoProblemaFitosanitario(tipo_problema_fitosanitario_id),
  inicio DATETIME2(0) NOT NULL, fin DATETIME2(0) NULL,
  observacion NVARCHAR(1000) NULL,
  usuario_apertura_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  usuario_cierre_id BIGINT NULL REFERENCES seg.Usuario(usuario_id),
  visita_tecnica_id BIGINT NULL REFERENCES campo.VisitaTecnica(visita_tecnica_id),
  CONSTRAINT CK_E3_EpisodioFechas CHECK(fin IS NULL OR fin>=inicio)
 );
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_E3_EpisodioAbierto' AND object_id=OBJECT_ID('sanidad.EpisodioPlantaE3'))
 CREATE UNIQUE INDEX UX_E3_EpisodioAbierto ON sanidad.EpisodioPlantaE3(planta_id) WHERE fin IS NULL;
IF OBJECT_ID('sanidad.TratamientoPlantaE3','U') IS NULL
 CREATE TABLE sanidad.TratamientoPlantaE3(
  tratamiento_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  episodio_id BIGINT NOT NULL REFERENCES sanidad.EpisodioPlantaE3(episodio_id),
  descripcion NVARCHAR(600) NOT NULL,resultado NVARCHAR(600) NULL,
  fecha_aplicacion DATETIME2(0) NOT NULL,
  visita_tecnica_id BIGINT NULL REFERENCES campo.VisitaTecnica(visita_tecnica_id),
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
 );
IF OBJECT_ID('prod.ProduccionPlantaE3','U') IS NULL
 CREATE TABLE prod.ProduccionPlantaE3(
  produccion_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
  anio SMALLINT NOT NULL,estimado_kg DECIMAL(14,3) NULL,real_kg DECIMAL(14,3) NULL,
  observacion NVARCHAR(500) NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  registrado_en DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_E3_Produccion CHECK(anio BETWEEN 2000 AND 2200 AND (estimado_kg IS NULL OR estimado_kg>=0) AND (real_kg IS NULL OR real_kg>=0))
 );
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_E3_ProduccionVersion' AND object_id=OBJECT_ID('prod.ProduccionPlantaE3'))
 CREATE INDEX IX_E3_ProduccionVersion ON prod.ProduccionPlantaE3(planta_id,anio,produccion_id DESC);
IF OBJECT_ID('prod.PlantaEvidenciaE3','U') IS NULL
 CREATE TABLE prod.PlantaEvidenciaE3(
  planta_evidencia_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
  archivo_id BIGINT NOT NULL REFERENCES archivo.Archivo(archivo_id),
  evento_id BIGINT NULL REFERENCES prod.PlantaEventoE3(evento_id),
  tipo VARCHAR(20) NOT NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_E3_Evidencia UNIQUE(planta_id,archivo_id)
 );
IF OBJECT_ID('prod.PlantaSolicitudE3','U') IS NULL
 CREATE TABLE prod.PlantaSolicitudE3(
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  accion VARCHAR(30) NOT NULL,
  clave UNIQUEIDENTIFIER NOT NULL,
  hash_peticion VARBINARY(32) NOT NULL,
  respuesta NVARCHAR(MAX) NOT NULL,
  registrado_en DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT PK_E3_Idempotencia PRIMARY KEY(usuario_id,accion,clave)
 );
GO
-- Estado MUERTA irreversible aun ante escrituras directas.
IF OBJECT_ID(N'prod.TR_E3_PlantaMuertaTerminal', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E3_PlantaMuertaTerminal;
GO
CREATE TRIGGER prod.TR_E3_PlantaMuertaTerminal
ON prod.PlantaPaltaE3 AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.planta_id=I.planta_id
           WHERE D.estado_actual='MUERTA' AND I.estado_actual<>'MUERTA')
   THROW 51182,N'El estado MUERTA es terminal.',1;
END;
GO
-- La historia de hechos no se actualiza ni borra: las correcciones agregan eventos.
IF OBJECT_ID(N'prod.TR_E3_EventoInmutable', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E3_EventoInmutable;
GO
CREATE TRIGGER prod.TR_E3_EventoInmutable
ON prod.PlantaEventoE3 AFTER UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 THROW 51183,N'Los eventos son inmutables; registre un nuevo evento.',1;
END;
GO
IF OBJECT_ID(N'sanidad.TR_E3_TratamientoInmutable', N'TR') IS NOT NULL DROP TRIGGER sanidad.TR_E3_TratamientoInmutable;
GO
CREATE TRIGGER sanidad.TR_E3_TratamientoInmutable
ON sanidad.TratamientoPlantaE3 AFTER UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 THROW 51184,N'Los tratamientos son inmutables.',1;
END;
GO
IF OBJECT_ID(N'prod.TR_E3_ProduccionInmutable', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E3_ProduccionInmutable;
GO
CREATE TRIGGER prod.TR_E3_ProduccionInmutable
ON prod.ProduccionPlantaE3 AFTER UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 THROW 51185,N'La producción histórica no se puede sobrescribir.',1;
END;
GO
