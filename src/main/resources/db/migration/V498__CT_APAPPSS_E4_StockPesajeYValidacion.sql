-- DESCO E4: stock físico certificado por UOT, validación de retornos, pesajes versionados.
-- Los censos, campañas, entrega y kardex existentes permanecen intactos.
IF OBJECT_ID(N'comercial.JabaStockUotE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.JabaStockUotE4 (
    uot_id BIGINT NOT NULL CONSTRAINT PK_JabaStockUotE4 PRIMARY KEY,
    existencia_certificada INT NOT NULL CHECK (existencia_certificada>=0),
    version BIGINT NOT NULL CONSTRAINT DF_JabaStockUotE4_Version DEFAULT (1),
    actualizado_por BIGINT NOT NULL,
    actualizado_en DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
GO
IF OBJECT_ID(N'comercial.JabaStockHistorialE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.JabaStockHistorialE4 (
    historial_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    uot_id BIGINT NOT NULL REFERENCES comercial.JabaStockUotE4(uot_id),
    existencia_anterior INT NULL,
    existencia_nueva INT NOT NULL,
    motivo NVARCHAR(400) NOT NULL,
    usuario_id BIGINT NOT NULL,
    fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
GO
IF OBJECT_ID(N'comercial.JabaRetornoValidadoE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.JabaRetornoValidadoE4 (
    jaba_asignacion_id BIGINT NOT NULL PRIMARY KEY REFERENCES comercial.JabaAsignacion(jaba_asignacion_id),
    cantidad_validada INT NOT NULL CHECK(cantidad_validada>=0),
    observacion NVARCHAR(400) NULL,
    validado_por BIGINT NOT NULL,
    validado_en DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
GO
IF OBJECT_ID(N'comercial.JabaPesajeHistorialE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.JabaPesajeHistorialE4 (
    historial_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    unidad_id BIGINT NOT NULL REFERENCES comercial.JabaUnidadE4(unidad_id),
    version_anterior BIGINT NOT NULL,
    version_nueva BIGINT NOT NULL,
    estado_anterior VARCHAR(16) NOT NULL,
    estado_nuevo VARCHAR(16) NOT NULL,
    peso_anterior DECIMAL(14,3) NULL,
    peso_nuevo DECIMAL(14,3) NULL,
    tara_anterior DECIMAL(10,3) NULL,
    tara_nueva DECIMAL(10,3) NULL,
    precio_anterior DECIMAL(14,4) NULL,
    precio_nuevo DECIMAL(14,4) NULL,
    motivo NVARCHAR(400) NULL,
    usuario_id BIGINT NULL,
    fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'comercial.JabaPesajeHistorialE4') AND name=N'IX_JabaPesajeHistorialE4_Unidad')
CREATE INDEX IX_JabaPesajeHistorialE4_Unidad ON comercial.JabaPesajeHistorialE4(unidad_id,historial_id);
GO
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE parent_object_id=OBJECT_ID(N'comercial.JabaUnidadE4')
      AND name=N'CK_JabaUnidadE4_pesaje'
)
    ALTER TABLE comercial.JabaUnidadE4 DROP CONSTRAINT CK_JabaUnidadE4_pesaje;
GO
ALTER TABLE comercial.JabaUnidadE4 WITH CHECK ADD CONSTRAINT CK_JabaUnidadE4_pesaje CHECK (
    pesaje_estado IN('SIN_PESAJE','PRELIMINAR','PESADA','ANULADA')
    AND retorno_estado IN('PENDIENTE','DEVUELTA_LLENA','DEVUELTA_VACIA','FALTANTE')
    AND (
        (pesaje_estado IN('SIN_PESAJE','ANULADA') AND peso_bruto_kg IS NULL AND tara_kg IS NULL
            AND precio_base IS NULL AND precio_comercial_id IS NULL)
        OR (pesaje_estado='PRELIMINAR' AND peso_bruto_kg>tara_kg AND tara_kg>=0
            AND precio_base IS NULL AND precio_comercial_id IS NULL)
        OR (pesaje_estado='PESADA' AND peso_bruto_kg>tara_kg AND tara_kg>=0
            AND variedad_palta_id IS NOT NULL AND condicion_comercial_id IS NOT NULL AND precio_base>=0)
    )
);
GO
IF OBJECT_ID(N'comercial.TR_JabaUnidadE4_Historial', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_JabaUnidadE4_Historial;
GO
CREATE TRIGGER comercial.TR_JabaUnidadE4_Historial
ON comercial.JabaUnidadE4 AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO comercial.JabaPesajeHistorialE4
        (unidad_id,version_anterior,version_nueva,estado_anterior,estado_nuevo,
         peso_anterior,peso_nuevo,tara_anterior,tara_nueva,precio_anterior,precio_nuevo,motivo,usuario_id)
    SELECT I.unidad_id,D.version,I.version,D.pesaje_estado,I.pesaje_estado,
        D.peso_bruto_kg,I.peso_bruto_kg,D.tara_kg,I.tara_kg,D.precio_base,I.precio_base,
        TRY_CONVERT(NVARCHAR(400),SESSION_CONTEXT(N'e4_motivo')),I.usuario_pesaje_id
    FROM inserted I JOIN deleted D ON D.unidad_id=I.unidad_id
    WHERE I.pesaje_estado<>D.pesaje_estado OR ISNULL(I.peso_bruto_kg,-1)<>ISNULL(D.peso_bruto_kg,-1)
       OR ISNULL(I.tara_kg,-1)<>ISNULL(D.tara_kg,-1)
       OR ISNULL(I.precio_base,-1)<>ISNULL(D.precio_base,-1);
END;
GO
-- Una sanción con precio efectivo debe ser inconfundible y E5 no restará nuevamente su diferencia.
IF COL_LENGTH('comercial.SancionSocioE4','aplicada_detalle') IS NULL
    ALTER TABLE comercial.SancionSocioE4 ADD aplicada_detalle BIT NOT NULL DEFAULT(0);
GO
IF COL_LENGTH('comercial.CargoTarifaE4','campania_venta_id') IS NULL
    ALTER TABLE comercial.CargoTarifaE4 ADD campania_venta_id BIGINT NULL REFERENCES comercial.CampaniaVenta(campania_venta_id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'comercial.CargoTarifaE4') AND name=N'IX_CargoTarifaE4_Campania')
CREATE INDEX IX_CargoTarifaE4_Campania ON comercial.CargoTarifaE4(campania_venta_id,concepto_id,vigente_hasta);
GO
-- El número visible de una unidad es permanente dentro de la asignación.
-- No se genera etiqueta física ni se altera el kardex que mantiene sus propios triggers.
GO
IF OBJECT_ID(N'comercial.TR_E4_JabaAsignacion_StockGlobal', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E4_JabaAsignacion_StockGlobal;
GO
CREATE TRIGGER comercial.TR_E4_JabaAsignacion_StockGlobal
ON comercial.JabaAsignacion AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF ROWCOUNT_BIG()=0 RETURN;
    DECLARE @ambitos TABLE(uot_id BIGINT PRIMARY KEY);
    INSERT @ambitos(uot_id)
    SELECT DISTINCT C.uot_id
    FROM inserted I
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
    JOIN comercial.CampaniaControlE4 K ON K.campania_venta_id=C.campania_venta_id;
    IF EXISTS (SELECT 1 FROM @ambitos U LEFT JOIN comercial.JabaStockUotE4 S WITH(UPDLOCK,HOLDLOCK)
          ON S.uot_id=U.uot_id WHERE S.uot_id IS NULL)
        THROW 51300,N'Certifique previamente la existencia real de jabas de la UOT.',1;
    IF EXISTS(SELECT 1 FROM @ambitos U
       JOIN comercial.JabaStockUotE4 S WITH(UPDLOCK,HOLDLOCK) ON S.uot_id=U.uot_id
       CROSS APPLY (
           SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) AS retenidas
           FROM comercial.JabaAsignacion A
           JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
           JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
           JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
           LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
           WHERE C.uot_id=U.uot_id AND A.estado=1
       ) C WHERE C.retenidas>S.existencia_certificada)
       THROW 51301,N'No hay stock físico certificado disponible para esta asignación.',1;
END;
GO
