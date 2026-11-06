-- E4: integridad adicional y acceso eficiente. No modifica los objetos Flyway V437/V438.
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_SancionSocioE4_Precio')
BEGIN
    ALTER TABLE comercial.SancionSocioE4 WITH CHECK
    ADD CONSTRAINT CK_SancionSocioE4_Precio CHECK (precio_nuevo <= precio_original);
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'comercial.JabaUnidadE4') AND name = N'IX_JabaUnidadE4_Entrega')
BEGIN
    CREATE INDEX IX_JabaUnidadE4_Entrega ON comercial.JabaUnidadE4(entrega_socio_id, pesaje_estado)
    INCLUDE (peso_bruto_kg, tara_kg, precio_base);
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'comercial.CargoTarifaE4') AND name = N'IX_CargoTarifaE4_Actual')
BEGIN
    CREATE INDEX IX_CargoTarifaE4_Actual ON comercial.CargoTarifaE4(concepto_id, vigente_hasta, vigente_desde DESC)
    INCLUDE (precio_unitario);
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'comercial.SancionSocioE4') AND name = N'IX_SancionSocioE4_Entrega')
BEGIN
    CREATE INDEX IX_SancionSocioE4_Entrega ON comercial.SancionSocioE4(entrega_socio_id, estado)
    INCLUDE (kilos_afectados, precio_original, precio_nuevo);
END;
GO
IF OBJECT_ID(N'comercial.TR_E4_JabaAsignacion_CupoUnidades', N'TR') IS NOT NULL DROP TRIGGER comercial.TR_E4_JabaAsignacion_CupoUnidades;
GO
CREATE TRIGGER comercial.TR_E4_JabaAsignacion_CupoUnidades
ON comercial.JabaAsignacion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF ROWCOUNT_BIG()=0 RETURN;

    -- Inactive legacy campaigns remain unaffected. Confirmed E4 facts cannot be silently cancelled.
    IF EXISTS (
        SELECT 1 FROM inserted I JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
        JOIN comercial.JabaUnidadE4 U ON U.jaba_asignacion_id=I.jaba_asignacion_id
        WHERE D.estado=1 AND I.estado=0
          AND (U.pesaje_estado='PESADA' OR U.retorno_estado<>'PENDIENTE'
               OR U.entrega_socio_id IS NOT NULL)
    )
        THROW 51250,N'La asignación con pesajes o devoluciones requiere reversión autorizada.',1;

    DECLARE @limites TABLE(campania_venta_id BIGINT NOT NULL PRIMARY KEY,cupo_jabas INT NOT NULL);
    INSERT INTO @limites(campania_venta_id,cupo_jabas)
    SELECT K.campania_venta_id,K.cupo_jabas
    FROM comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK)
    WHERE EXISTS(SELECT 1 FROM inserted I
       JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
       JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
       WHERE O.campania_venta_id=K.campania_venta_id);

    IF EXISTS (
        SELECT 1 FROM @limites K
        CROSS APPLY (
            SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) AS asignadas
            FROM comercial.JabaAsignacion A
            JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
            JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
            WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1
        ) S
        WHERE S.asignadas>K.cupo_jabas
    )
        THROW 51251,N'La asignación excede el cupo físico configurado para la campaña.',1;

    -- Exactly one assignment-unit per crate, also for an assignment made through the legacy API.
    INSERT INTO comercial.JabaUnidadE4(jaba_asignacion_id,numero)
    SELECT I.jaba_asignacion_id, N.numero
    FROM inserted I
    LEFT JOIN deleted D ON D.jaba_asignacion_id=I.jaba_asignacion_id
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    JOIN @limites K ON K.campania_venta_id=O.campania_venta_id
    CROSS APPLY (
       SELECT TOP (I.cantidad_asignada)
          CONVERT(INT,ROW_NUMBER() OVER(ORDER BY A.object_id,B.object_id)) numero
       FROM sys.all_objects A CROSS JOIN sys.all_objects B
    ) N
    WHERE D.jaba_asignacion_id IS NULL AND I.estado=1;
END;
GO

-- Distribución por unidad; las columnas económicas son snapshots inmutables una vez entregados.
IF OBJECT_ID(N'comercial.JabaClasificacionE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.JabaClasificacionE4 (
 clasificacion_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_JabaClasificacionE4 PRIMARY KEY,
 unidad_id BIGINT NOT NULL REFERENCES comercial.JabaUnidadE4(unidad_id),
 numero INT NOT NULL CHECK(numero>0),
 peso_kg DECIMAL(14,3) NOT NULL CHECK(peso_kg>0),
 rechazada BIT NOT NULL,
 variedad_palta_id SMALLINT NULL REFERENCES prod.VariedadPalta(variedad_palta_id),
 condicion_comercial_id BIGINT NULL REFERENCES comercial.CondicionComercial(condicion_comercial_id),
 precio_comercial_id BIGINT NULL REFERENCES comercial.PrecioComercial(precio_comercial_id),
 precio_base DECIMAL(14,4) NULL,
 usuario_id BIGINT NULL,fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT UQ_JabaClasificacionE4_Orden UNIQUE(unidad_id,numero),
 CONSTRAINT CK_JabaClasificacionE4_Tipo CHECK (
   (rechazada=1 AND precio_comercial_id IS NULL AND precio_base IS NULL) OR
   (rechazada=0 AND variedad_palta_id IS NOT NULL AND condicion_comercial_id IS NOT NULL
      AND precio_comercial_id IS NOT NULL AND precio_base>=0))
);
END;
GO
IF OBJECT_ID(N'comercial.JabaClasificacionHistorialE4', N'U') IS NULL
BEGIN
CREATE TABLE comercial.JabaClasificacionHistorialE4 (
 historial_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 unidad_id BIGINT NOT NULL REFERENCES comercial.JabaUnidadE4(unidad_id),
 version BIGINT NOT NULL,
 anterior NVARCHAR(MAX) NULL, actual NVARCHAR(MAX) NOT NULL,
 motivo NVARCHAR(400) NOT NULL,usuario_id BIGINT NOT NULL,
 fecha DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'comercial.JabaClasificacionHistorialE4') AND name=N'IX_JabaClasificacionHistorialE4_Unidad')
CREATE INDEX IX_JabaClasificacionHistorialE4_Unidad
 ON comercial.JabaClasificacionHistorialE4(unidad_id,version);
GO
-- Conserva la clasificación de pesajes registrados por V438 sin alterar el histórico.
INSERT INTO comercial.JabaClasificacionE4
 (unidad_id,numero,peso_kg,rechazada,variedad_palta_id,condicion_comercial_id,
  precio_comercial_id,precio_base,usuario_id)
SELECT U.unidad_id,1,U.peso_neto_kg,0,U.variedad_palta_id,U.condicion_comercial_id,
 U.precio_comercial_id,U.precio_base,U.usuario_pesaje_id
FROM comercial.JabaUnidadE4 U
WHERE U.pesaje_estado='PESADA' AND U.peso_neto_kg>0
 AND NOT EXISTS (SELECT 1 FROM comercial.JabaClasificacionE4 C WHERE C.unidad_id=U.unidad_id);
GO
