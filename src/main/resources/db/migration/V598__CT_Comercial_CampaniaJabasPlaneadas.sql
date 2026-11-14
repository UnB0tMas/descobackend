-- DESCO / APAPPSS: reserva de jabas por participante antes de crear operativos.
-- Mantiene el inventario E4 como fuente de verdad: no genera JabaAsignacion ni pesajes duplicados.
IF OBJECT_ID(N'comercial.CampaniaJabaPlan',N'U') IS NULL
BEGIN
 CREATE TABLE comercial.CampaniaJabaPlan (
  campania_jaba_plan_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CampaniaJabaPlan PRIMARY KEY,
  participacion_campania_socio_id BIGINT NOT NULL
   CONSTRAINT FK_CampaniaJabaPlan_Participante REFERENCES comercial.ParticipacionCampaniaSocio(participacion_campania_socio_id),
  cantidad INT NOT NULL CONSTRAINT CK_CampaniaJabaPlan_Cantidad CHECK(cantidad BETWEEN 1 AND 100000),
  estado VARCHAR(20) NOT NULL CONSTRAINT DF_CampaniaJabaPlan_Estado DEFAULT('PENDIENTE_RECOJO')
   CONSTRAINT CK_CampaniaJabaPlan_Estado CHECK(estado IN('PENDIENTE_RECOJO','ENTREGADA','DEVUELTA')),
  activo BIT NOT NULL CONSTRAINT DF_CampaniaJabaPlan_Activo DEFAULT(1),
  version BIGINT NOT NULL CONSTRAINT DF_CampaniaJabaPlan_Version DEFAULT(1),
  usuario_registro_id BIGINT NOT NULL, usuario_modifica_id BIGINT NULL,
  fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_CampaniaJabaPlan_Fecha DEFAULT(SYSUTCDATETIME()),
  fecha_entrega DATETIME2(0) NULL, fecha_devolucion DATETIME2(0) NULL,
  CONSTRAINT UQ_CampaniaJabaPlan_Participante UNIQUE(participacion_campania_socio_id),
  CONSTRAINT CK_CampaniaJabaPlan_Fechas CHECK (
   (estado='PENDIENTE_RECOJO' AND fecha_entrega IS NULL AND fecha_devolucion IS NULL) OR
   (estado='ENTREGADA' AND fecha_entrega IS NOT NULL AND fecha_devolucion IS NULL) OR
   (estado='DEVUELTA' AND fecha_entrega IS NOT NULL AND fecha_devolucion IS NOT NULL))
 );
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'comercial.CampaniaJabaPlan') AND name='IX_CampaniaJabaPlan_Estado')
 CREATE INDEX IX_CampaniaJabaPlan_Estado ON comercial.CampaniaJabaPlan(estado,activo) INCLUDE(cantidad);
GO
-- Al reducir el cupo no se pueden ignorar reservas aún vigentes ni asignaciones E4.
CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaPlan_ValidarCupo
ON comercial.CampaniaControlE4 AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM inserted K
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51420,N'El nuevo cupo es inferior a las jabas reservadas o asignadas.',1;
END;
GO
-- Impedir retiro de socio con reserva vigente; debe cancelar primero su asignación pendiente.
CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaPlan_ValidarParticipante
ON comercial.ParticipacionCampaniaSocio AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted P
  JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id
  WHERE (P.estado=0 OR P.estado_participacion<>'ACTIVO') AND J.activo=1 AND J.estado<>'DEVUELTA')
  THROW 51421,N'No se puede retirar al socio mientras tenga jabas asignadas.',1;
END;
GO
-- Los movimientos de E4 y los anticipos de campaña comparten el mismo cupo.
CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaPlan_CompatibilidadOperativo
ON comercial.JabaAsignacion AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK) ON K.campania_venta_id=O.campania_venta_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS2 ON OS2.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O2 ON O2.operativo_venta_id=OS2.operativo_venta_id
    WHERE O2.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51422,N'Las jabas reservadas en campaña más las asignadas al operativo exceden el cupo.',1;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
  JOIN comercial.JabaStockUotE4 S WITH(UPDLOCK,HOLDLOCK) ON S.uot_id=C.uot_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    JOIN comercial.CampaniaVenta K ON K.campania_venta_id=P.campania_venta_id
    WHERE K.uot_id=S.uot_id AND J.activo=1 AND J.estado='ENTREGADA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) cantidad
    FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio X ON X.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta OV ON OV.operativo_venta_id=X.operativo_venta_id
    JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=OV.campania_venta_id
    LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
    WHERE CV.uot_id=S.uot_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>S.existencia_certificada)
  THROW 51423,N'Las jabas entregadas y las retenidas superan las existencias certificadas.',1;
END;
GO
-- Inventario E4 jamás puede reducirse por debajo de las entregas anticipadas.
CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaPlan_ValidarStock
ON comercial.JabaStockUotE4 AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted S
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id
    WHERE C.uot_id=S.uot_id AND J.activo=1 AND J.estado='ENTREGADA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) cantidad
    FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
    LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
    WHERE C.uot_id=S.uot_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>S.existencia_certificada)
  THROW 51424,N'El stock certificado no cubre las jabas aún retenidas.',1;
END;
GO
