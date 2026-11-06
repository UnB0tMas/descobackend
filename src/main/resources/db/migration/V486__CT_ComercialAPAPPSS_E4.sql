-- E4: control granular y económico de APAPPSS. Las tablas originales y sus triggers permanecen vigentes.
IF OBJECT_ID(N'comercial.CampaniaControlE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.CampaniaControlE4 (
 campania_venta_id BIGINT NOT NULL PRIMARY KEY REFERENCES comercial.CampaniaVenta(campania_venta_id),
 cupo_jabas INT NOT NULL CHECK(cupo_jabas BETWEEN 1 AND 100000),
 tara_kg DECIMAL(10,3) NOT NULL CHECK(tara_kg>=0 AND tara_kg<10),
 version BIGINT NOT NULL CONSTRAINT DF_CampaniaControlE4_version DEFAULT(1),
 usuario_id BIGINT NOT NULL, actualizado_en DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
IF OBJECT_ID(N'comercial.JabaUnidadE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.JabaUnidadE4 (
 unidad_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_JabaUnidadE4 PRIMARY KEY,
 jaba_asignacion_id BIGINT NOT NULL REFERENCES comercial.JabaAsignacion(jaba_asignacion_id),
 numero INT NOT NULL CHECK(numero>0),
 peso_bruto_kg DECIMAL(14,3) NULL,
 tara_kg DECIMAL(10,3) NULL,
 peso_neto_kg AS (peso_bruto_kg-tara_kg) PERSISTED,
 variedad_palta_id SMALLINT NULL REFERENCES prod.VariedadPalta(variedad_palta_id),
 condicion_comercial_id BIGINT NULL REFERENCES comercial.CondicionComercial(condicion_comercial_id),
 precio_comercial_id BIGINT NULL REFERENCES comercial.PrecioComercial(precio_comercial_id),
 precio_base DECIMAL(14,4) NULL,
 pesaje_estado VARCHAR(16) NOT NULL DEFAULT 'SIN_PESAJE',
 retorno_estado VARCHAR(16) NOT NULL DEFAULT 'PENDIENTE',
 usuario_pesaje_id BIGINT NULL, fecha_pesaje DATETIME2(0) NULL,
 usuario_retorno_id BIGINT NULL, fecha_retorno DATETIME2(0) NULL,
 entrega_socio_id BIGINT NULL REFERENCES comercial.EntregaSocio(entrega_socio_id),
 version BIGINT NOT NULL DEFAULT 1,
 CONSTRAINT UQ_JabaUnidadE4_asignacion_numero UNIQUE(jaba_asignacion_id,numero),
 CONSTRAINT CK_JabaUnidadE4_pesaje CHECK(pesaje_estado IN('SIN_PESAJE','PESADA') AND retorno_estado IN('PENDIENTE','DEVUELTA_LLENA','DEVUELTA_VACIA','FALTANTE') AND
  ((pesaje_estado='SIN_PESAJE' AND peso_bruto_kg IS NULL AND tara_kg IS NULL AND precio_base IS NULL) OR
   (pesaje_estado='PESADA' AND peso_bruto_kg>tara_kg AND tara_kg>=0 AND variedad_palta_id IS NOT NULL AND condicion_comercial_id IS NOT NULL AND precio_base>=0)))
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'comercial.JabaUnidadE4') AND name=N'IX_JabaUnidadE4_retorno')
CREATE INDEX IX_JabaUnidadE4_retorno ON comercial.JabaUnidadE4(jaba_asignacion_id,retorno_estado,pesaje_estado) INCLUDE(peso_bruto_kg,tara_kg);
IF OBJECT_ID(N'comercial.SancionSocioE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.SancionSocioE4 (
 sancion_id BIGINT IDENTITY PRIMARY KEY,
 entrega_socio_id BIGINT NOT NULL REFERENCES comercial.EntregaSocio(entrega_socio_id),
 condicion_comercial_id BIGINT NULL REFERENCES comercial.CondicionComercial(condicion_comercial_id),
 variedad_palta_id SMALLINT NULL REFERENCES prod.VariedadPalta(variedad_palta_id),
 kilos_afectados DECIMAL(14,3) NOT NULL CHECK(kilos_afectados>0),
 precio_original DECIMAL(14,4) NOT NULL CHECK(precio_original>=0),
 precio_nuevo DECIMAL(14,4) NOT NULL CHECK(precio_nuevo>=0),
 diferencia AS CONVERT(DECIMAL(19,4),kilos_afectados*(precio_original-precio_nuevo)) PERSISTED,
 motivo NVARCHAR(400) NOT NULL,
 usuario_id BIGINT NOT NULL,fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 estado BIT NOT NULL DEFAULT 1
);
END;
IF OBJECT_ID(N'comercial.CargoConceptoE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.CargoConceptoE4 (
 concepto_id SMALLINT IDENTITY PRIMARY KEY,
 codigo VARCHAR(40) NOT NULL UNIQUE,
 nombre NVARCHAR(120) NOT NULL,
 activo BIT NOT NULL DEFAULT 1
);
END;
IF OBJECT_ID(N'comercial.CargoTarifaE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.CargoTarifaE4 (
 tarifa_id BIGINT IDENTITY PRIMARY KEY,
 concepto_id SMALLINT NOT NULL REFERENCES comercial.CargoConceptoE4(concepto_id),
 precio_unitario DECIMAL(14,4) NOT NULL CHECK(precio_unitario>=0),
 vigente_desde DATETIME2(0) NOT NULL,
 vigente_hasta DATETIME2(0) NULL,
 usuario_id BIGINT NULL,
 CONSTRAINT CK_CargoTarifaE4_vigencia CHECK(vigente_hasta IS NULL OR vigente_hasta>vigente_desde)
);
END;
IF OBJECT_ID(N'comercial.CargoIndividualE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.CargoIndividualE4 (
 cargo_id BIGINT IDENTITY PRIMARY KEY,
 jaba_asignacion_id BIGINT NOT NULL REFERENCES comercial.JabaAsignacion(jaba_asignacion_id),
 concepto_id SMALLINT NOT NULL REFERENCES comercial.CargoConceptoE4(concepto_id),
 tarifa_id BIGINT NOT NULL REFERENCES comercial.CargoTarifaE4(tarifa_id),
 cantidad INT NOT NULL CHECK(cantidad>0),
 precio_unitario DECIMAL(14,4) NOT NULL CHECK(precio_unitario>=0),
 importe AS CONVERT(DECIMAL(19,4),cantidad*precio_unitario) PERSISTED,
 motivo NVARCHAR(400) NOT NULL,
 usuario_id BIGINT NOT NULL,fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 estado BIT NOT NULL DEFAULT 1,
 CONSTRAINT UQ_CargoIndividualE4_unico UNIQUE(jaba_asignacion_id,concepto_id)
);
END;
IF OBJECT_ID(N'comercial.IncidenciaFaltanteE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.IncidenciaFaltanteE4 (
 incidencia_id BIGINT IDENTITY PRIMARY KEY,
 jaba_asignacion_id BIGINT NOT NULL UNIQUE REFERENCES comercial.JabaAsignacion(jaba_asignacion_id),
 cantidad INT NOT NULL CHECK(cantidad>0),
 estado VARCHAR(16) NOT NULL DEFAULT 'REGISTRADA' CHECK(estado IN('REGISTRADA','CONFIRMADA')),
 registrado_por BIGINT NOT NULL,registrado_en DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 confirmado_por BIGINT NULL,confirmado_en DATETIME2(0) NULL,observacion NVARCHAR(400) NULL
);
END;
IF OBJECT_ID(N'comercial.SolicitudE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.SolicitudE4 (
 usuario_id BIGINT NOT NULL, clave UNIQUEIDENTIFIER NOT NULL,
 accion VARCHAR(32) NOT NULL, huella VARBINARY(32) NOT NULL,
 respuesta NVARCHAR(MAX) NULL, fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_SolicitudE4 PRIMARY KEY(usuario_id,clave)
);
END;
IF OBJECT_ID(N'comercial.EventoE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.EventoE4 (
 evento_id BIGINT IDENTITY PRIMARY KEY,
 campania_venta_id BIGINT NOT NULL REFERENCES comercial.CampaniaVenta(campania_venta_id),
 entidad VARCHAR(40) NOT NULL, entidad_id BIGINT NOT NULL,
 accion VARCHAR(40) NOT NULL, detalle NVARCHAR(MAX) NULL,
 usuario_id BIGINT NOT NULL, fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
-- Catálogo E4: conservar el concepto ya registrado por las migraciones locales anteriores.
IF NOT EXISTS (
    SELECT 1
    FROM comercial.CargoConceptoE4 WITH (UPDLOCK, HOLDLOCK)
    WHERE codigo = 'JABA_PERDIDA'
)
BEGIN
    INSERT INTO comercial.CargoConceptoE4(codigo,nombre)
    VALUES ('JABA_PERDIDA', N'Jaba perdida');
END;
-- La tarifa inicial no se inventa: el responsable debe registrarla con una acción autorizada.
