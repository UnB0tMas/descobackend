-- E5 conserva deuda neta explícita (saldo deudor) y el estado OBSERVADA; conserva otros controles.
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'finanzas.LiquidacionSocio') AND name=N'CK_LiquidacionSocio_Importes')
 ALTER TABLE finanzas.LiquidacionSocio DROP CONSTRAINT CK_LiquidacionSocio_Importes;
GO
ALTER TABLE finanzas.LiquidacionSocio WITH CHECK ADD CONSTRAINT CK_LiquidacionSocio_Importes
 CHECK(importe_bruto>=0 AND total_gastos>=0 AND total_bonificaciones>=0);
GO
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'finanzas.LiquidacionSocio') AND name=N'CK_LiquidacionSocio_EstadoProceso')
 ALTER TABLE finanzas.LiquidacionSocio DROP CONSTRAINT CK_LiquidacionSocio_EstadoProceso;
GO
ALTER TABLE finanzas.LiquidacionSocio WITH CHECK ADD CONSTRAINT CK_LiquidacionSocio_EstadoProceso
 CHECK(estado_proceso IN('BORRADOR','CALCULADA','OBSERVADA','APROBADA','PAGADA_PARCIAL','PAGADA','ANULADA'));
GO
-- E5: anexos de versionado sobre entidades financieras existentes. No migra ni reemplaza históricos.
IF OBJECT_ID(N'finanzas.GastoRepartoVersionE5', N'U') IS NULL
BEGIN
CREATE TABLE finanzas.GastoRepartoVersionE5 (
 reparto_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 gasto_campania_id BIGINT NOT NULL REFERENCES finanzas.GastoCampania(gasto_campania_id),
 version INT NOT NULL, importe DECIMAL(19,4) NOT NULL,
 moneda CHAR(3) NOT NULL, vendedores INT NOT NULL CHECK(vendedores>0),
 estado VARCHAR(20) NOT NULL CHECK(estado IN('PROPUESTO','APROBADO','RECTIFICADO')),
 observacion NVARCHAR(500) NULL, usuario_id BIGINT NOT NULL,
 creado DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 aprobado_por BIGINT NULL, aprobado DATETIME2(0) NULL,
 CONSTRAINT UQ_GastoRepartoVersionE5 UNIQUE(gasto_campania_id,version)
);
END;
GO
IF OBJECT_ID(N'finanzas.GastoRepartoLineaE5', N'U') IS NULL
BEGIN
CREATE TABLE finanzas.GastoRepartoLineaE5 (
 reparto_id BIGINT NOT NULL REFERENCES finanzas.GastoRepartoVersionE5(reparto_id),
 participacion_id BIGINT NOT NULL REFERENCES comercial.ParticipacionCampaniaSocio(participacion_campania_socio_id),
 monto DECIMAL(19,4) NOT NULL CHECK(monto>=0),
 PRIMARY KEY(reparto_id,participacion_id)
);
END;
GO
IF OBJECT_ID(N'finanzas.LiquidacionSnapshotE5', N'U') IS NULL
BEGIN
CREATE TABLE finanzas.LiquidacionSnapshotE5 (
 liquidacion_socio_id BIGINT NOT NULL PRIMARY KEY REFERENCES finanzas.LiquidacionSocio(liquidacion_socio_id),
 campania_venta_id BIGINT NOT NULL REFERENCES comercial.CampaniaVenta(campania_venta_id),
 peso_aceptado_kg DECIMAL(19,3) NOT NULL,
 bruto_referencial DECIMAL(19,4) NOT NULL,
 ajuste_precio DECIMAL(19,4) NOT NULL,
 descuentos_adicionales DECIMAL(19,4) NOT NULL,
 cargos DECIMAL(19,4) NOT NULL,
 gastos DECIMAL(19,4) NOT NULL,
 bonificaciones DECIMAL(19,4) NOT NULL,
 ajuste_redondeo DECIMAL(19,4) NOT NULL DEFAULT 0,
 venta_ajustada DECIMAL(19,4) NOT NULL,
 neto DECIMAL(19,4) NOT NULL,
 fuente_hash VARBINARY(32) NOT NULL,
 moneda CHAR(3) NOT NULL,
 creado_por BIGINT NOT NULL,
 creado DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 aprobado_por BIGINT NULL, aprobado DATETIME2(0) NULL,
 observacion NVARCHAR(500) NULL
);
END;
GO
IF OBJECT_ID(N'finanzas.EventoPagoE5', N'U') IS NULL
BEGIN
CREATE TABLE finanzas.EventoPagoE5 (
 evento_id BIGINT IDENTITY(1,1) PRIMARY KEY,
 pago_socio_id BIGINT NOT NULL REFERENCES finanzas.PagoSocio(pago_socio_id),
 accion VARCHAR(30) NOT NULL CHECK(accion IN('PAGAR','REVERSAR')),
 importe DECIMAL(19,4) NOT NULL, usuario_id BIGINT NOT NULL,
 motivo NVARCHAR(500) NULL, fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
GO
IF OBJECT_ID(N'comercial.CierreCampaniaE5', N'U') IS NULL
BEGIN
CREATE TABLE comercial.CierreCampaniaE5 (
 campania_venta_id BIGINT NOT NULL PRIMARY KEY REFERENCES comercial.CampaniaVenta(campania_venta_id),
 fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 usuario_id BIGINT NOT NULL,
 observacion NVARCHAR(800) NOT NULL,
 excepcion_autorizada BIT NOT NULL DEFAULT 0,
 motivo_excepcion NVARCHAR(800) NULL,
 balance_final NVARCHAR(MAX) NOT NULL,
 CONSTRAINT CK_CierreCampaniaE5_Excepcion CHECK(excepcion_autorizada=0 OR NULLIF(LTRIM(RTRIM(motivo_excepcion)),N'') IS NOT NULL)
);
END;
GO
IF OBJECT_ID(N'finanzas.SolicitudE5', N'U') IS NULL
BEGIN
CREATE TABLE finanzas.SolicitudE5 (
 usuario_id BIGINT NOT NULL, clave UNIQUEIDENTIFIER NOT NULL,
 accion VARCHAR(40) NOT NULL, huella VARBINARY(32) NOT NULL,
 respuesta NVARCHAR(MAX) NOT NULL, fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 PRIMARY KEY(usuario_id,clave)
);
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'finanzas.LiquidacionSnapshotE5') AND name=N'IX_LiquidacionSnapshotE5_Campania')
CREATE INDEX IX_LiquidacionSnapshotE5_Campania ON finanzas.LiquidacionSnapshotE5(campania_venta_id);
GO
-- El cierre físico impide escrituras financieras heredadas silenciosas.
IF OBJECT_ID(N'finanzas.TR_E5_Pago_Saldo', N'TR') IS NOT NULL DROP TRIGGER finanzas.TR_E5_Pago_Saldo;
GO
CREATE TRIGGER finanzas.TR_E5_Pago_Saldo
ON finanzas.PagoSocio AFTER INSERT, UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
   SELECT 1 FROM (SELECT DISTINCT liquidacion_socio_id FROM inserted) I
   JOIN finanzas.LiquidacionSocio L WITH(UPDLOCK,HOLDLOCK) ON L.liquidacion_socio_id=I.liquidacion_socio_id
   CROSS APPLY(SELECT COALESCE(SUM(P.importe),0) pagado FROM finanzas.PagoSocio P
     WHERE P.liquidacion_socio_id=I.liquidacion_socio_id AND P.estado=1 AND P.estado_proceso='CONFIRMADO') T
   WHERE L.importe_neto<0 OR T.pagado>L.importe_neto
 ) THROW 51501,N'El pago excede el saldo autorizado.',1;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=I.liquidacion_socio_id
  JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
  JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=P.campania_venta_id)
 THROW 51502,N'La campaña cerrada no permite modificar pagos.',1;
END;
GO
IF OBJECT_ID(N'finanzas.TR_E5_Liquidacion_Cierre', N'TR') IS NOT NULL DROP TRIGGER finanzas.TR_E5_Liquidacion_Cierre;
GO
CREATE TRIGGER finanzas.TR_E5_Liquidacion_Cierre
ON finanzas.LiquidacionSocio AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT participacion_campania_socio_id FROM inserted UNION SELECT participacion_campania_socio_id FROM deleted) X
  JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=X.participacion_campania_socio_id
  JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=P.campania_venta_id)
 THROW 51503,N'La campaña cerrada no permite modificar liquidaciones.',1;
END;
GO
IF OBJECT_ID(N'finanzas.TR_E5_Gasto_Cierre', N'TR') IS NOT NULL DROP TRIGGER finanzas.TR_E5_Gasto_Cierre;
GO
CREATE TRIGGER finanzas.TR_E5_Gasto_Cierre
ON finanzas.GastoCampania AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT campania_venta_id FROM inserted UNION SELECT campania_venta_id FROM deleted) X
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=X.campania_venta_id)
 THROW 51504,N'La campaña cerrada no permite modificar gastos.',1;
END;
GO
IF OBJECT_ID(N'comercial.TR_E5_Entrega_Cierre', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E5_Entrega_Cierre;
GO
CREATE TRIGGER comercial.TR_E5_Entrega_Cierre
ON comercial.EntregaDetalle AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT entrega_socio_id FROM inserted UNION SELECT entrega_socio_id FROM deleted) X
 JOIN comercial.EntregaSocio E ON E.entrega_socio_id=X.entrega_socio_id
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51505,N'La campaña cerrada no permite modificar detalles comerciales.',1;
END;
GO
IF OBJECT_ID(N'comercial.TR_E5_Cargos_Cierre', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E5_Cargos_Cierre;
GO
CREATE TRIGGER comercial.TR_E5_Cargos_Cierre
ON comercial.CargoIndividualE4 AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT jaba_asignacion_id FROM inserted UNION SELECT jaba_asignacion_id FROM deleted) X
 JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=X.jaba_asignacion_id
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51506,N'La campaña cerrada no permite modificar cargos.',1;
END;
GO
IF OBJECT_ID(N'comercial.TR_E5_Sanciones_Cierre', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E5_Sanciones_Cierre;
GO
CREATE TRIGGER comercial.TR_E5_Sanciones_Cierre
ON comercial.SancionSocioE4 AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT entrega_socio_id FROM inserted UNION SELECT entrega_socio_id FROM deleted) X
 JOIN comercial.EntregaSocio E ON E.entrega_socio_id=X.entrega_socio_id
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51507,N'La campaña cerrada no permite modificar sanciones.',1;
END;
GO

-- No permitir que escrituras externas alteren el importe o el ámbito de un snapshot aprobado.
GO
IF OBJECT_ID(N'finanzas.TR_E5_Liquidacion_ImporteCongelado', N'TR') IS NOT NULL DROP TRIGGER finanzas.TR_E5_Liquidacion_ImporteCongelado;
GO
CREATE TRIGGER finanzas.TR_E5_Liquidacion_ImporteCongelado
ON finanzas.LiquidacionSocio AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.liquidacion_socio_id=I.liquidacion_socio_id
  JOIN finanzas.LiquidacionSnapshotE5 S ON S.liquidacion_socio_id=I.liquidacion_socio_id
  WHERE S.aprobado IS NOT NULL AND
   (I.importe_neto<>D.importe_neto OR I.importe_bruto<>D.importe_bruto
    OR I.participacion_campania_socio_id<>D.participacion_campania_socio_id OR I.version<>D.version
    OR I.moneda<>D.moneda))
 THROW 51508,N'Una liquidación aprobada conserva importes, versión y moneda inmutables.',1;
END;
GO
IF OBJECT_ID(N'comercial.TR_E5_JabaUnidad_Cierre', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E5_JabaUnidad_Cierre;
GO
CREATE TRIGGER comercial.TR_E5_JabaUnidad_Cierre
ON comercial.JabaUnidadE4 AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT jaba_asignacion_id FROM inserted UNION SELECT jaba_asignacion_id FROM deleted) X
 JOIN comercial.JabaAsignacion A ON A.jaba_asignacion_id=X.jaba_asignacion_id
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51509,N'Las jabas de campañas cerradas son inmutables.',1;
END;
GO
IF OBJECT_ID(N'comercial.TR_E5_EntregaSocio_Cierre', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E5_EntregaSocio_Cierre;
GO
CREATE TRIGGER comercial.TR_E5_EntregaSocio_Cierre
ON comercial.EntregaSocio AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT operativo_socio_id FROM inserted UNION SELECT operativo_socio_id FROM deleted) X
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=X.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51510,N'Las entregas de campañas cerradas son inmutables.',1;
END;
GO
IF OBJECT_ID(N'finanzas.TR_E5_Gasto_VersionCongelada', N'TR') IS NOT NULL DROP TRIGGER finanzas.TR_E5_Gasto_VersionCongelada;
GO
CREATE TRIGGER finanzas.TR_E5_Gasto_VersionCongelada
ON finanzas.GastoCampania AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.gasto_campania_id=I.gasto_campania_id
   WHERE EXISTS(SELECT 1 FROM finanzas.GastoRepartoVersionE5 V
                 WHERE V.gasto_campania_id=I.gasto_campania_id AND V.estado='APROBADO')
      AND (I.importe<>D.importe OR I.moneda<>D.moneda OR I.campania_venta_id<>D.campania_venta_id))
 THROW 51511,N'El gasto con reparto aprobado conserva importe y moneda históricos.',1;
END;
GO
IF OBJECT_ID(N'comercial.TR_E5_JabaAsignacion_Cierre', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E5_JabaAsignacion_Cierre;
GO
CREATE TRIGGER comercial.TR_E5_JabaAsignacion_Cierre
ON comercial.JabaAsignacion AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT operativo_socio_id FROM inserted UNION SELECT operativo_socio_id FROM deleted) X
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=X.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=O.campania_venta_id)
 THROW 51512,N'Las asignaciones de campañas cerradas son inmutables.',1;
END;
GO
