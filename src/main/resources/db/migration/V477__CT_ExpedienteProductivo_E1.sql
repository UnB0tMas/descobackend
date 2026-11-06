-- E1: fundamentos productivos. Evolución compatible con V1 y V410.
-- No modifica migraciones ejecutadas ni elimina titularidades/cultivos existentes.
IF COL_LENGTH('prod.PredioTitularidad', 'persona_id') IS NULL
    ALTER TABLE prod.PredioTitularidad ADD persona_id BIGINT NULL;
GO
UPDATE T SET persona_id = T.socio_id
FROM prod.PredioTitularidad T
WHERE T.persona_id IS NULL AND T.socio_id IS NOT NULL;
GO
IF EXISTS (SELECT 1 FROM prod.PredioTitularidad WHERE persona_id IS NULL)
    THROW 51050, N'Existen titulares sin persona válida; concilie los datos antes de migrar.', 1;
-- La unicidad histórica sobre socio_id impide dos titulares no socios (NULL).
-- Se sustituye por identidad de persona sin perder claves ni valores antiguos.
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.PredioTitularidad') AND name='UX_DESCO_PredioTitularidad_Vigente')
    DROP INDEX UX_DESCO_PredioTitularidad_Vigente ON prod.PredioTitularidad;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.PredioTitularidad') AND name='IX_DESCO_PredioTitularidad_Vigencia')
    DROP INDEX IX_DESCO_PredioTitularidad_Vigencia ON prod.PredioTitularidad;
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID('prod.PredioTitularidad') AND name='UQ_PredioTitularidad_Periodo')
    ALTER TABLE prod.PredioTitularidad DROP CONSTRAINT UQ_PredioTitularidad_Periodo;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('prod.PredioTitularidad') AND name='FK_PredioTitularidad_Socio')
    ALTER TABLE prod.PredioTitularidad DROP CONSTRAINT FK_PredioTitularidad_Socio;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('prod.PredioTitularidad') AND name='socio_id' AND is_nullable=0)
    ALTER TABLE prod.PredioTitularidad ALTER COLUMN socio_id BIGINT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('prod.PredioTitularidad') AND name='FK_PredioTitularidad_Socio')
    ALTER TABLE prod.PredioTitularidad WITH CHECK ADD CONSTRAINT FK_PredioTitularidad_Socio FOREIGN KEY(socio_id) REFERENCES org.Socio(socio_id);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.PredioTitularidad') AND name='UX_E1_TitularVigente')
    CREATE UNIQUE INDEX UX_E1_TitularVigente ON prod.PredioTitularidad(predio_id,persona_id) WHERE estado=1 AND fecha_hasta IS NULL;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.PredioTitularidad') AND name='UX_E1_TitularPeriodo')
    CREATE UNIQUE INDEX UX_E1_TitularPeriodo ON prod.PredioTitularidad(predio_id,persona_id,fecha_desde);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.PredioTitularidad') AND name='IX_E1_TitularSocio')
    CREATE INDEX IX_E1_TitularSocio ON prod.PredioTitularidad(predio_id,socio_id,estado,fecha_hasta);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_E1_Titular_Persona')
    ALTER TABLE prod.PredioTitularidad WITH CHECK ADD CONSTRAINT FK_E1_Titular_Persona FOREIGN KEY(persona_id) REFERENCES org.Persona(persona_id);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_E1_Titular_Identidad')
    ALTER TABLE prod.PredioTitularidad WITH CHECK ADD CONSTRAINT CK_E1_Titular_Identidad CHECK(persona_id IS NOT NULL);
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('prod.PredioVersion') AND name='area_total_ha' AND is_nullable=0)
    ALTER TABLE prod.PredioVersion ALTER COLUMN area_total_ha DECIMAL(10,4) NULL;
-- Un predio admite varias ampliaciones fechadas el mismo día, cada una con revisión propia.
IF COL_LENGTH('prod.PredioVersion','revision') IS NULL
    ALTER TABLE prod.PredioVersion ADD revision INT NOT NULL CONSTRAINT DF_E1_PredioVersionRevision DEFAULT (1);
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID('prod.PredioVersion') AND name='UQ_PredioVersion_Periodo')
    ALTER TABLE prod.PredioVersion DROP CONSTRAINT UQ_PredioVersion_Periodo;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('prod.PredioVersion') AND name='UX_E1_PredioVersionRevision')
    CREATE UNIQUE INDEX UX_E1_PredioVersionRevision ON prod.PredioVersion(predio_id,fecha_desde,revision);
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('prod.Parcela') AND name='area_ha' AND is_nullable=0)
    ALTER TABLE prod.Parcela ALTER COLUMN area_ha DECIMAL(10,4) NULL;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('prod.ParcelaCultivo') AND name='FK_ParcelaCultivo_Variedad')
    ALTER TABLE prod.ParcelaCultivo DROP CONSTRAINT FK_ParcelaCultivo_Variedad;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('prod.ParcelaCultivo') AND name='variedad_palta_id' AND is_nullable=0)
    ALTER TABLE prod.ParcelaCultivo ALTER COLUMN variedad_palta_id SMALLINT NULL;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('prod.ParcelaCultivo') AND name='FK_ParcelaCultivo_Variedad')
    ALTER TABLE prod.ParcelaCultivo WITH CHECK ADD CONSTRAINT FK_ParcelaCultivo_Variedad FOREIGN KEY(variedad_palta_id) REFERENCES prod.VariedadPalta(variedad_palta_id);
IF COL_LENGTH('prod.ParcelaCultivo','cultivo_id') IS NULL
    ALTER TABLE prod.ParcelaCultivo ADD cultivo_id INT NULL;
GO
UPDATE PC SET cultivo_id=VC.cultivo_id
FROM prod.ParcelaCultivo PC JOIN prod.VariedadCultivo VC ON VC.variedad_cultivo_id=PC.variedad_cultivo_id
WHERE PC.cultivo_id IS NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_E1_ParcelaCultivo_Cultivo')
    ALTER TABLE prod.ParcelaCultivo WITH CHECK ADD CONSTRAINT FK_E1_ParcelaCultivo_Cultivo FOREIGN KEY(cultivo_id) REFERENCES prod.Cultivo(cultivo_id);
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_E1_ParcelaCultivo_Identificacion')
    ALTER TABLE prod.ParcelaCultivo WITH CHECK ADD CONSTRAINT CK_E1_ParcelaCultivo_Identificacion CHECK(cultivo_id IS NOT NULL OR variedad_cultivo_id IS NOT NULL OR variedad_palta_id IS NOT NULL);
IF NOT EXISTS (SELECT 1 FROM prod.Cultivo WHERE codigo='MAIZ') INSERT prod.Cultivo(codigo,nombre) VALUES ('MAIZ',N'Maíz');
GO
IF OBJECT_ID('prod.PredioAmbito','U') IS NULL
BEGIN
    CREATE TABLE prod.PredioAmbito (
        predio_ambito_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
        uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
        convenio_uot_organizacion_id BIGINT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
        estado BIT NOT NULL CONSTRAINT DF_E1_AmbitoEstado DEFAULT 1,
        fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_E1_AmbitoFecha DEFAULT SYSUTCDATETIME(),
        usuario_creacion_id BIGINT NULL REFERENCES seg.Usuario(usuario_id),
        CONSTRAINT UQ_E1_PredioAmbito UNIQUE(predio_id,uot_id,convenio_uot_organizacion_id)
    );
END;
GO

-- Sólo se asignan ámbitos históricos si la UOT de origen consta en el predio.
INSERT prod.PredioAmbito(predio_id,uot_id,usuario_creacion_id)
SELECT P.predio_id,P.uot_id,NULL FROM prod.Predio P
WHERE P.uot_id IS NOT NULL AND NOT EXISTS(
 SELECT 1 FROM prod.PredioAmbito A WHERE A.predio_id=P.predio_id AND A.uot_id=P.uot_id AND A.convenio_uot_organizacion_id IS NULL);
GO
-- Evita duplicados de ámbito tradicional cuando la FK convenio es NULL.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_E1_AmbitoTradicional' AND object_id=OBJECT_ID('prod.PredioAmbito'))
    CREATE UNIQUE INDEX UX_E1_AmbitoTradicional ON prod.PredioAmbito(predio_id,uot_id) WHERE convenio_uot_organizacion_id IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_E1_AmbitoUOT' AND object_id=OBJECT_ID('prod.PredioAmbito'))
    CREATE INDEX IX_E1_AmbitoUOT ON prod.PredioAmbito(uot_id,convenio_uot_organizacion_id,predio_id) INCLUDE(estado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_E1_TitularPersona' AND object_id=OBJECT_ID('prod.PredioTitularidad'))
    CREATE INDEX IX_E1_TitularPersona ON prod.PredioTitularidad(persona_id,predio_id,fecha_hasta);
GO
IF OBJECT_ID('prod.PredioIdentidad','U') IS NULL
BEGIN
    CREATE TABLE prod.PredioIdentidad (
        persona_id BIGINT NOT NULL REFERENCES org.Persona(persona_id),
        distrito_codigo CHAR(6) NOT NULL REFERENCES geo.Distrito(distrito_codigo),
        nombre_normalizado NVARCHAR(150) NOT NULL,
        predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
        CONSTRAINT PK_E1_PredioIdentidad PRIMARY KEY(persona_id,distrito_codigo,nombre_normalizado)
    );
END;
GO
-- Conciliación conservadora: una identidad duplicada preexistente se deja para revisión,
-- sin eliminar predios históricos ni reasignar sus titulares.
;WITH C AS (
 SELECT T.persona_id,U.distrito_codigo,UPPER(LTRIM(RTRIM(P.nombre))) nombre_normalizado,
        MIN(P.predio_id) predio_id
 FROM prod.Predio P JOIN prod.PredioTitularidad T ON T.predio_id=P.predio_id
 JOIN geo.Ubicacion U ON U.ubicacion_id=P.ubicacion_id
 WHERE T.persona_id IS NOT NULL AND T.estado=1 AND T.fecha_hasta IS NULL
 GROUP BY T.persona_id,U.distrito_codigo,UPPER(LTRIM(RTRIM(P.nombre)))
)
INSERT prod.PredioIdentidad(persona_id,distrito_codigo,nombre_normalizado,predio_id)
SELECT C.persona_id,C.distrito_codigo,C.nombre_normalizado,C.predio_id
FROM C WHERE NOT EXISTS(SELECT 1 FROM prod.PredioIdentidad X
 WHERE X.persona_id=C.persona_id AND X.distrito_codigo=C.distrito_codigo AND X.nombre_normalizado=C.nombre_normalizado);
GO
IF OBJECT_ID('prod.EspeciePecuaria','U') IS NULL
BEGIN
    CREATE TABLE prod.EspeciePecuaria (
        especie_pecuaria_id INT IDENTITY(1,1) PRIMARY KEY,
        codigo VARCHAR(30) NOT NULL UNIQUE,
        nombre NVARCHAR(90) NOT NULL,
        estado BIT NOT NULL DEFAULT 1
    );
END;
IF NOT EXISTS (SELECT 1 FROM prod.EspeciePecuaria WHERE codigo='PORCINO') INSERT prod.EspeciePecuaria(codigo,nombre) VALUES('PORCINO',N'Cerdos');
IF NOT EXISTS (SELECT 1 FROM prod.EspeciePecuaria WHERE codigo='CUY') INSERT prod.EspeciePecuaria(codigo,nombre) VALUES('CUY',N'Cuyes');
IF OBJECT_ID('prod.CrianzaLote','U') IS NULL
BEGIN
    CREATE TABLE prod.CrianzaLote (
        crianza_lote_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
        especie_pecuaria_id INT NOT NULL REFERENCES prod.EspeciePecuaria(especie_pecuaria_id),
        nombre NVARCHAR(100) NULL,
        fecha_inicio DATE NOT NULL CONSTRAINT DF_E1_LoteFecha DEFAULT CONVERT(date,SYSUTCDATETIME()),
        fecha_fin DATE NULL,
        estado BIT NOT NULL DEFAULT 1,
        CONSTRAINT CK_E1_CrianzaVigencia CHECK(fecha_fin IS NULL OR fecha_fin>=fecha_inicio)
    );
END;
IF OBJECT_ID('prod.CrianzaConteo','U') IS NULL
BEGIN
    CREATE TABLE prod.CrianzaConteo (
        crianza_conteo_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        crianza_lote_id BIGINT NOT NULL REFERENCES prod.CrianzaLote(crianza_lote_id),
        cantidad INT NULL,
        fecha_observacion DATE NOT NULL,
        observacion NVARCHAR(1000) NULL,
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_E1_CantidadNoNegativa CHECK(cantidad IS NULL OR cantidad>=0)
    );
END;
IF OBJECT_ID('prod.ExpedienteActuacion','U') IS NULL
BEGIN
    CREATE TABLE prod.ExpedienteActuacion (
        expediente_actuacion_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
        uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
        convenio_uot_organizacion_id BIGINT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
        parcela_cultivo_id BIGINT NULL REFERENCES prod.ParcelaCultivo(parcela_cultivo_id),
        crianza_lote_id BIGINT NULL REFERENCES prod.CrianzaLote(crianza_lote_id),
        tipo VARCHAR(40) NOT NULL,
        observacion NVARCHAR(2000) NOT NULL,
        fecha_hecho DATETIME2(0) NOT NULL,
        fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        salida_campo_id BIGINT NULL,
        visita_tecnica_id BIGINT NULL,
        correlacion_id UNIQUEIDENTIFIER NULL,
        CONSTRAINT CK_E1_ActuacionTipo CHECK(tipo IN('GENERAL','CULTIVO','CRIANZA','SANIDAD','NECESIDAD','SEGUIMIENTO'))
    );
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_E1_ActuacionPredio' AND object_id=OBJECT_ID('prod.ExpedienteActuacion'))
    CREATE INDEX IX_E1_ActuacionPredio ON prod.ExpedienteActuacion(predio_id,uot_id,fecha_hecho DESC,expediente_actuacion_id DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_E1_CrianzaLotePredio' AND object_id=OBJECT_ID('prod.CrianzaLote'))
    CREATE INDEX IX_E1_CrianzaLotePredio ON prod.CrianzaLote(predio_id,especie_pecuaria_id,estado);
GO
-- Se prohíbe establecer un socio sin que corresponda a la persona titular.
IF OBJECT_ID(N'prod.TR_E1_TitularValidarPersona', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E1_TitularValidarPersona;
GO
CREATE TRIGGER prod.TR_E1_TitularValidarPersona
ON prod.PredioTitularidad AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted I WHERE I.persona_id IS NULL
       OR (I.socio_id IS NOT NULL AND I.socio_id<>I.persona_id))
        THROW 51051,N'La titularidad debe referirse a la misma persona.',1;
END;
GO

-- La regla de vigencia también usa persona_id, no socio_id (el cual puede ser NULL).
IF OBJECT_ID(N'prod.TR_DESCO_PredioTitularidad_Vigencia', N'TR') IS NOT NULL DROP TRIGGER prod.TR_DESCO_PredioTitularidad_Vigencia;
GO
CREATE TRIGGER prod.TR_DESCO_PredioTitularidad_Vigencia ON prod.PredioTitularidad AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN prod.PredioTitularidad X WITH(UPDLOCK,HOLDLOCK)
       ON X.predio_id=I.predio_id AND X.persona_id=I.persona_id AND X.predio_titularidad_id<>I.predio_titularidad_id
       WHERE I.estado=1 AND I.fecha_hasta IS NULL AND X.estado=1 AND X.fecha_hasta IS NULL)
     THROW 51030,N'El titular ya tiene una vigencia abierta en el predio.',1;
END;
GO
