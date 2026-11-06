-- Etapa 3: ampliación compatible. No migra censos agregados ni modifica V435–V446.
IF COL_LENGTH('prod.PlantaPaltaE3','socio_id') IS NULL
    ALTER TABLE prod.PlantaPaltaE3 ADD socio_id BIGINT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_E3_Planta_Socio')
    ALTER TABLE prod.PlantaPaltaE3 WITH CHECK ADD CONSTRAINT FK_E3_Planta_Socio
        FOREIGN KEY(socio_id) REFERENCES org.Socio(socio_id);
GO
-- Sólo conciliación sin ambigüedad; los casos históricos de titularidad múltiple quedan pendientes.
;WITH Unico AS (
    SELECT T.predio_id, MIN(T.socio_id) socio_id
    FROM prod.PredioTitularidad T
    WHERE T.estado=1 AND T.fecha_hasta IS NULL AND T.socio_id IS NOT NULL
    GROUP BY T.predio_id HAVING COUNT(DISTINCT T.socio_id)=1
)
UPDATE P SET socio_id=U.socio_id
FROM prod.PlantaPaltaE3 P JOIN Unico U ON U.predio_id=P.predio_id
WHERE P.socio_id IS NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_E3_PlantaSocio' AND object_id=OBJECT_ID('prod.PlantaPaltaE3'))
    CREATE INDEX IX_E3_PlantaSocio ON prod.PlantaPaltaE3(convenio_id,uot_id,socio_id,predio_id,parcela_cultivo_id,variedad_palta_id);
GO
IF OBJECT_ID('prod.PlantaFichaHistorialE3','U') IS NULL
BEGIN
    CREATE TABLE prod.PlantaFichaHistorialE3(
        ficha_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
        fecha_plantacion DATE NULL, edad_referencia_anios SMALLINT NULL,
        fecha_referencia DATE NULL,
        version BIGINT NOT NULL,
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        fecha_registro DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_E3_FichaEdad CHECK(edad_referencia_anios IS NULL OR edad_referencia_anios BETWEEN 0 AND 200),
        CONSTRAINT UX_E3_FichaVersion UNIQUE(planta_id,version)
    );
END;
GO
IF OBJECT_ID('sanidad.PlantaSeguimientoE3','U') IS NULL
BEGIN
    CREATE TABLE sanidad.PlantaSeguimientoE3(
        seguimiento_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
        episodio_id BIGINT NULL REFERENCES sanidad.EpisodioPlantaE3(episodio_id),
        evento_id BIGINT NOT NULL UNIQUE REFERENCES prod.PlantaEventoE3(evento_id),
        tipo VARCHAR(20) NOT NULL,
        observacion NVARCHAR(1000) NOT NULL,
        resultado NVARCHAR(600) NULL,
        visita_tecnica_id BIGINT NULL REFERENCES campo.VisitaTecnica(visita_tecnica_id),
        fecha_hecho DATETIME2(0) NOT NULL,
        usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
        CONSTRAINT CK_E3_SeguimientoTipo CHECK(tipo IN('SANITARIO','PREVENTIVO','PODA','RIEGO','FERTILIZACION','OTRO'))
    );
    CREATE INDEX IX_E3_SeguimientoHistorial ON sanidad.PlantaSeguimientoE3(planta_id,seguimiento_id DESC);
END;
GO
IF COL_LENGTH('prod.ProduccionPlantaE3','tipo_registro') IS NULL
    ALTER TABLE prod.ProduccionPlantaE3 ADD tipo_registro VARCHAR(12) NOT NULL
        CONSTRAINT DF_E3_ProduccionTipo DEFAULT 'LEGADO';
IF COL_LENGTH('prod.ProduccionPlantaE3','fecha_evento') IS NULL
    ALTER TABLE prod.ProduccionPlantaE3 ADD fecha_evento DATE NULL;
IF COL_LENGTH('prod.ProduccionPlantaE3','visita_tecnica_id') IS NULL
    ALTER TABLE prod.ProduccionPlantaE3 ADD visita_tecnica_id BIGINT NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_E3_ProduccionVisita')
    ALTER TABLE prod.ProduccionPlantaE3 WITH CHECK ADD CONSTRAINT FK_E3_ProduccionVisita
        FOREIGN KEY(visita_tecnica_id) REFERENCES campo.VisitaTecnica(visita_tecnica_id);
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_E3_ProduccionTipo')
    ALTER TABLE prod.ProduccionPlantaE3 WITH CHECK ADD CONSTRAINT CK_E3_ProduccionTipo
        CHECK(tipo_registro='LEGADO' OR (tipo_registro='ESTIMACION' AND estimado_kg IS NOT NULL AND real_kg IS NULL)
             OR (tipo_registro='COSECHA' AND real_kg IS NOT NULL AND estimado_kg IS NULL));
GO
IF NOT EXISTS(SELECT 1 FROM seg.Permiso WHERE codigo='APAPPSS_PLANTAS_CORREGIR')
    INSERT INTO seg.Permiso(modulo_id,codigo,nombre,descripcion,estado,accion,es_sensible,requiere_motivo)
    SELECT TOP(1) modulo_id,'APAPPSS_PLANTAS_CORREGIR',N'Corregir estado terminal de palta',
         N'Rectificación excepcional auditada de planta muerta',1,'EDITAR',1,1
    FROM seg.Permiso WHERE codigo='APAPPSS_PREDIOS_EDITAR';
GO
-- Una rectificación terminal es un evento explícito; ampliar el CHECK heredado sin reescribir V435.
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_E3_EventoTipo' AND parent_object_id=OBJECT_ID('prod.PlantaEventoE3'))
    ALTER TABLE prod.PlantaEventoE3 DROP CONSTRAINT CK_E3_EventoTipo;
ALTER TABLE prod.PlantaEventoE3 WITH CHECK ADD CONSTRAINT CK_E3_EventoTipo
    CHECK(tipo IN('ALTA','EVALUACION','CORRECCION','FICHA','SEGUIMIENTO','TRATAMIENTO','PRODUCCION','EVIDENCIA'));
GO
-- Sólo el PA, tras autorización específica, puede habilitar la corrección excepcional.
IF OBJECT_ID(N'prod.TR_E3_PlantaMuertaTerminal', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E3_PlantaMuertaTerminal;
GO
CREATE TRIGGER prod.TR_E3_PlantaMuertaTerminal ON prod.PlantaPaltaE3 AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.planta_id=I.planta_id
       WHERE D.estado_actual='MUERTA' AND I.estado_actual<>'MUERTA')
       AND ISNULL(TRY_CONVERT(INT,SESSION_CONTEXT(N'E3_CORRECCION_AUTORIZADA')),0)<>1
       THROW 51182,N'El estado MUERTA es terminal.',1;
END;
GO
IF OBJECT_ID(N'prod.TR_E3_FichaInmutable', N'TR') IS NOT NULL DROP TRIGGER prod.TR_E3_FichaInmutable;
GO
CREATE TRIGGER prod.TR_E3_FichaInmutable ON prod.PlantaFichaHistorialE3 AFTER UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51187,N'El historial de fichas es inmutable.',1;
END;
GO
IF OBJECT_ID(N'sanidad.TR_E3_SeguimientoInmutable', N'TR') IS NOT NULL DROP TRIGGER sanidad.TR_E3_SeguimientoInmutable;
GO
CREATE TRIGGER sanidad.TR_E3_SeguimientoInmutable ON sanidad.PlantaSeguimientoE3 AFTER UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51188,N'El historial de seguimientos es inmutable.',1;
END;
GO

-- Una estimación es una versión (última del periodo); cada cosecha real es un hecho sumable.
-- Los snapshots LEGADO sólo contribuyen con el último valor anual (sin duplicar cosechas).
CREATE OR ALTER VIEW prod.VW_PlantaProduccionResumenE3 AS
WITH Versiones AS (
 SELECT R.planta_id,R.anio,R.tipo_registro,R.estimado_kg,R.real_kg,
 ROW_NUMBER() OVER(PARTITION BY R.planta_id,R.anio,R.tipo_registro ORDER BY R.produccion_id DESC) orden
 FROM prod.ProduccionPlantaE3 R
)
SELECT V.planta_id,V.anio,
 COALESCE(MAX(CASE WHEN V.tipo_registro='ESTIMACION' AND V.orden=1 THEN V.estimado_kg END),
          MAX(CASE WHEN V.tipo_registro='LEGADO' AND V.orden=1 THEN V.estimado_kg END)) estimado_kg,
 SUM(CASE WHEN V.tipo_registro='COSECHA' THEN ISNULL(V.real_kg,0) ELSE 0 END)
    +ISNULL(MAX(CASE WHEN V.tipo_registro='LEGADO' AND V.orden=1 THEN V.real_kg END),0) real_kg,
 MAX(CASE WHEN V.estimado_kg IS NOT NULL AND (V.tipo_registro='ESTIMACION' OR V.tipo_registro='LEGADO') THEN 1 ELSE 0 END) tiene_estimacion,
 MAX(CASE WHEN V.real_kg IS NOT NULL AND (V.tipo_registro='COSECHA' OR V.tipo_registro='LEGADO') THEN 1 ELSE 0 END) tiene_real
FROM Versiones V GROUP BY V.planta_id,V.anio;
GO
