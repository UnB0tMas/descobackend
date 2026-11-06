-- E2: esquema de autorización y custodia, compatible con salidas históricas y kardex.
IF OBJECT_ID('campo.SalidaE2','U') IS NULL
BEGIN
 CREATE TABLE campo.SalidaE2(
   salida_campo_id BIGINT NOT NULL CONSTRAINT PK_SalidaE2 PRIMARY KEY REFERENCES campo.SalidaCampo(salida_campo_id),
   nombre NVARCHAR(180) NOT NULL,
   solicitante_empleado_id BIGINT NOT NULL REFERENCES org.Empleado(empleado_id),
   uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
   convenio_id BIGINT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
   fecha_fin_prevista DATETIME2(0) NULL,
   estado VARCHAR(24) NOT NULL CONSTRAINT DF_E2_SalidaEstado DEFAULT 'SOLICITADA',
   fecha_solicitud DATETIME2(0) NOT NULL CONSTRAINT DF_E2_SalidaSolicitud DEFAULT SYSUTCDATETIME(),
   fecha_aprobacion DATETIME2(0) NULL,
   fecha_retorno_declarado DATETIME2(0) NULL,
   fecha_cierre DATETIME2(0) NULL,
   usuario_aprobador BIGINT NULL REFERENCES seg.Usuario(usuario_id),
   CONSTRAINT CK_E2_Estado CHECK(estado IN('SOLICITADA','OBSERVADA','APROBADA','RECHAZADA','EN_EJECUCION','EN_RETORNO','CERRADA','CANCELADA'))
 );
END;
GO
IF OBJECT_ID('campo.SalidaDestinoE2','U') IS NULL
BEGIN
 CREATE TABLE campo.SalidaDestinoE2(
  destino_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  salida_campo_id BIGINT NOT NULL REFERENCES campo.SalidaCampo(salida_campo_id),
  predio_id BIGINT NULL REFERENCES prod.Predio(predio_id),
  referencia NVARCHAR(250) NULL,
  orden INT NOT NULL,
  CONSTRAINT CK_E2_Destino CHECK(predio_id IS NOT NULL OR NULLIF(LTRIM(RTRIM(referencia)),N'') IS NOT NULL),
  CONSTRAINT UQ_E2_DestinoOrden UNIQUE(salida_campo_id,orden)
 );
 IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'campo.SalidaDestinoE2') AND name=N'IX_E2_DestinoPredio')
 CREATE INDEX IX_E2_DestinoPredio ON campo.SalidaDestinoE2(predio_id,salida_campo_id) WHERE predio_id IS NOT NULL;
END;
GO
IF OBJECT_ID('campo.SalidaRecursoE2','U') IS NULL
BEGIN
 CREATE TABLE campo.SalidaRecursoE2(
  solicitud_recurso_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  salida_campo_id BIGINT NOT NULL REFERENCES campo.SalidaCampo(salida_campo_id),
  bien_inventario_id BIGINT NOT NULL REFERENCES logistica.BienInventario(bien_inventario_id),
  recurso_programado_id BIGINT NULL REFERENCES logistica.RecursoProgramado(recurso_programado_id),
  estado VARCHAR(24) NOT NULL DEFAULT 'SOLICITADO',
  resultado_declarado VARCHAR(24) NULL,
  observacion NVARCHAR(500) NULL,
  resultado_validado VARCHAR(24) NULL,
  fecha_validacion DATETIME2(0) NULL,
  usuario_validacion BIGINT NULL REFERENCES seg.Usuario(usuario_id),
  CONSTRAINT UQ_E2_SalidaRecurso UNIQUE(salida_campo_id,bien_inventario_id),
  CONSTRAINT CK_E2_RecursoEstado CHECK (estado IN('SOLICITADO','ENTREGADO','VALIDADO','INCIDENCIA')),
  CONSTRAINT CK_E2_RecursoDeclarado CHECK (resultado_declarado IS NULL OR resultado_declarado IN('CONFORME','DANADO','FALTANTE')),
  CONSTRAINT CK_E2_RecursoValidado CHECK (resultado_validado IS NULL OR resultado_validado IN('CONFORME','DANADO','FALTANTE'))
 );
 IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'campo.SalidaRecursoE2') AND name=N'UX_E2_RecursoProgramado')
 CREATE UNIQUE INDEX UX_E2_RecursoProgramado ON campo.SalidaRecursoE2(recurso_programado_id) WHERE recurso_programado_id IS NOT NULL;
END;
GO
IF OBJECT_ID('campo.SalidaEventoE2','U') IS NULL
BEGIN
 CREATE TABLE campo.SalidaEventoE2(
  evento_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  salida_campo_id BIGINT NOT NULL REFERENCES campo.SalidaCampo(salida_campo_id),
  tipo VARCHAR(30) NOT NULL,
  detalle NVARCHAR(1200) NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_hora DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  correlacion_id UNIQUEIDENTIFIER NULL
 );
 IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'campo.SalidaEventoE2') AND name=N'IX_E2_EventosFecha')
 CREATE INDEX IX_E2_EventosFecha ON campo.SalidaEventoE2(salida_campo_id,evento_id);
END;
GO
IF OBJECT_ID('campo.TipoVisitaE2','U') IS NULL
BEGIN
 CREATE TABLE campo.TipoVisitaE2(tipo_visita_id INT IDENTITY(1,1) PRIMARY KEY,codigo VARCHAR(40) NOT NULL UNIQUE,nombre NVARCHAR(100) NOT NULL,estado BIT NOT NULL DEFAULT 1);
END;
GO
INSERT campo.TipoVisitaE2(codigo,nombre)
SELECT V.codigo,V.nombre FROM (VALUES
 ('CONOCIMIENTO',N'Conocimiento'),('SEGUIMIENTO',N'Seguimiento'),('ASESORIA',N'Asesoría'),
 ('MATERIA_SECA',N'Materia seca'),('SANIDAD',N'Control sanitario')) V(codigo,nombre)
WHERE NOT EXISTS (SELECT 1 FROM campo.TipoVisitaE2 T WHERE T.codigo=V.codigo);
GO
IF OBJECT_ID('campo.SalidaVisitaE2','U') IS NULL
BEGIN
 CREATE TABLE campo.SalidaVisitaE2(
   visita_tecnica_id BIGINT NOT NULL PRIMARY KEY REFERENCES campo.VisitaTecnica(visita_tecnica_id),
   destino_id BIGINT NOT NULL REFERENCES campo.SalidaDestinoE2(destino_id),
   tipo_visita_id INT NOT NULL REFERENCES campo.TipoVisitaE2(tipo_visita_id)
 );
END;
GO
IF OBJECT_ID('campo.SalidaRetornoE2','U') IS NULL
BEGIN
 CREATE TABLE campo.SalidaRetornoE2(
  salida_campo_id BIGINT NOT NULL PRIMARY KEY REFERENCES campo.SalidaCampo(salida_campo_id),
  observacion_general NVARCHAR(1500) NOT NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_hora DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
 );
END;
GO
IF OBJECT_ID('campo.SalidaOperacionE2','U') IS NULL
BEGIN
 CREATE TABLE campo.SalidaOperacionE2(
  operacion_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  tipo VARCHAR(35) NOT NULL,
  idempotencia UNIQUEIDENTIFIER NOT NULL,
  hash_peticion VARBINARY(32) NOT NULL,
  respuesta NVARCHAR(MAX) NULL,
  fecha_hora DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UX_E2_Operacion UNIQUE(usuario_id,tipo,idempotencia)
 );
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'campo.SalidaE2') AND name=N'IX_E2_SalidaUotEstado')
CREATE INDEX IX_E2_SalidaUotEstado ON campo.SalidaE2(uot_id,convenio_id,estado,fecha_solicitud DESC);
GO
