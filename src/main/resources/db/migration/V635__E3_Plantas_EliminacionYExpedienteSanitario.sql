-- APAPPSS E3: ampliar de forma aditiva; no modificar migraciones anteriores.
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_E3_PlantaEstado' AND parent_object_id=OBJECT_ID('prod.PlantaPaltaE3'))
    ALTER TABLE prod.PlantaPaltaE3 DROP CONSTRAINT CK_E3_PlantaEstado;
ALTER TABLE prod.PlantaPaltaE3 WITH CHECK ADD CONSTRAINT CK_E3_PlantaEstado
 CHECK (estado_actual IN ('SIN_EVALUAR','SANA','ENFERMA','MUERTA','ELIMINADA'));
GO
-- MUERTA sigue siendo terminal, salvo su eliminación administrativa; ELIMINADA nunca se reactiva.
CREATE OR ALTER TRIGGER prod.TR_E3_PlantaMuertaTerminal ON prod.PlantaPaltaE3 AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted I INNER JOIN deleted D ON D.planta_id=I.planta_id
               WHERE (D.estado_actual='MUERTA' AND I.estado_actual NOT IN ('MUERTA','ELIMINADA'))
                  OR (D.estado_actual='ELIMINADA' AND I.estado_actual<>'ELIMINADA'))
        THROW 51201,N'Esta planta tiene un estado terminal y no admite reactivación.',1;
END;
GO
IF OBJECT_ID('prod.PlantaComentarioE3','U') IS NULL
BEGIN
    CREATE TABLE prod.PlantaComentarioE3 (
      comentario_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_E3_PlantaComentario PRIMARY KEY,
      planta_id BIGINT NOT NULL REFERENCES prod.PlantaPaltaE3(planta_id),
      comentario NVARCHAR(1500) NOT NULL,
      usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
      creado_en DATETIME2(0) NOT NULL CONSTRAINT DF_E3_ComentarioFecha DEFAULT SYSUTCDATETIME(),
      CONSTRAINT CK_E3_ComentarioNoVacio CHECK (LEN(LTRIM(RTRIM(comentario)))>0)
    );
    CREATE INDEX IX_E3_ComentarioPlanta ON prod.PlantaComentarioE3(planta_id,comentario_id DESC);
END;
GO
IF COL_LENGTH('sanidad.EpisodioPlantaE3','activo') IS NULL
    ALTER TABLE sanidad.EpisodioPlantaE3 ADD activo BIT NOT NULL CONSTRAINT DF_E3_EpisodioActivo DEFAULT (1);
IF COL_LENGTH('sanidad.EpisodioPlantaE3','eliminado_en') IS NULL
    ALTER TABLE sanidad.EpisodioPlantaE3 ADD eliminado_en DATETIME2(0) NULL;
IF COL_LENGTH('sanidad.EpisodioPlantaE3','eliminado_por_usuario_id') IS NULL
    ALTER TABLE sanidad.EpisodioPlantaE3 ADD eliminado_por_usuario_id BIGINT NULL REFERENCES seg.Usuario(usuario_id);
IF COL_LENGTH('sanidad.EpisodioPlantaE3','motivo_cierre') IS NULL
    ALTER TABLE sanidad.EpisodioPlantaE3 ADD motivo_cierre NVARCHAR(600) NULL;
GO
-- Una planta puede tener dos enfermedades vigentes diferentes, pero nunca duplicar la misma.
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_E3_EpisodioAbierto' AND object_id=OBJECT_ID('sanidad.EpisodioPlantaE3'))
    DROP INDEX UX_E3_EpisodioAbierto ON sanidad.EpisodioPlantaE3;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_E3_EpisodioActivoProblema' AND object_id=OBJECT_ID('sanidad.EpisodioPlantaE3'))
    CREATE UNIQUE INDEX UX_E3_EpisodioActivoProblema
     ON sanidad.EpisodioPlantaE3(planta_id,gp_problema_id)
     WHERE fin IS NULL AND activo=1 AND gp_problema_id IS NOT NULL;
GO
IF COL_LENGTH('sanidad.TratamientoPlantaE3','comentario') IS NULL
    ALTER TABLE sanidad.TratamientoPlantaE3 ADD comentario NVARCHAR(1000) NULL;
GO
-- Nuevos eventos son hechos inmutables, no se reutiliza MUERTA como eliminación.
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_E3_EventoTipo' AND parent_object_id=OBJECT_ID('prod.PlantaEventoE3'))
    ALTER TABLE prod.PlantaEventoE3 DROP CONSTRAINT CK_E3_EventoTipo;
ALTER TABLE prod.PlantaEventoE3 WITH CHECK ADD CONSTRAINT CK_E3_EventoTipo
 CHECK (tipo IN ('ALTA','EVALUACION','CORRECCION','FICHA','SEGUIMIENTO','TRATAMIENTO','PRODUCCION','EVIDENCIA','ELIMINACION','COMENTARIO','ENFERMEDAD'));
GO
