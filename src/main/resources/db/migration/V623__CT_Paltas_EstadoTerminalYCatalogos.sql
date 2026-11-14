-- Árboles individuales. Mantener los historiales y las claves ya registradas.
SET XACT_ABORT ON;
GO
IF COL_LENGTH('prod.PlantaPaltaE3','activo') IS NULL
 ALTER TABLE prod.PlantaPaltaE3 ADD activo BIT NOT NULL CONSTRAINT DF_E3_PlantaActivo DEFAULT(1);
GO
IF COL_LENGTH('sanidad.EpisodioPlantaE3','gp_problema_id') IS NULL
 ALTER TABLE sanidad.EpisodioPlantaE3 ADD gp_problema_id INT NULL;
IF COL_LENGTH('sanidad.TratamientoPlantaE3','gp_tratamiento_id') IS NULL
 ALTER TABLE sanidad.TratamientoPlantaE3 ADD gp_tratamiento_id INT NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_E3_Episodio_GPProblema')
 ALTER TABLE sanidad.EpisodioPlantaE3 WITH CHECK ADD CONSTRAINT FK_E3_Episodio_GPProblema
 FOREIGN KEY(gp_problema_id) REFERENCES prod.GPProblema(problema_id);
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_E3_Tratamiento_GPTratamiento')
 ALTER TABLE sanidad.TratamientoPlantaE3 WITH CHECK ADD CONSTRAINT FK_E3_Tratamiento_GPTratamiento
 FOREIGN KEY(gp_tratamiento_id) REFERENCES prod.GPTratamiento(tratamiento_id);
GO
-- Los casos anteriores conservan su diagnóstico original; los nuevos usan el catálogo de palta.
ALTER TABLE sanidad.EpisodioPlantaE3 ALTER COLUMN tipo_problema_fitosanitario_id SMALLINT NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('sanidad.EpisodioPlantaE3') AND name='IX_E3_Episodio_GPProblema')
 CREATE INDEX IX_E3_Episodio_GPProblema ON sanidad.EpisodioPlantaE3(gp_problema_id,planta_id,inicio DESC);
GO
-- Regularización de plantas antiguas sin evaluación. Conservar su alta original.
INSERT INTO prod.PlantaEventoE3(planta_id,tipo,estado_anterior,estado_nuevo,observacion,usuario_id,fecha_hecho)
 SELECT P.planta_id,'EVALUACION','SIN_EVALUAR','SANA',N'Regularización automática del estado inicial.',P.creado_por_usuario_id,SYSUTCDATETIME()
 FROM prod.PlantaPaltaE3 P WHERE P.estado_actual='SIN_EVALUAR';
UPDATE prod.PlantaPaltaE3 SET estado_actual='SANA',version=version+1 WHERE estado_actual='SIN_EVALUAR';
UPDATE prod.PlantaPaltaE3 SET activo=0 WHERE estado_actual='MUERTA' AND activo<>0;
GO
IF EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID('prod.PlantaPaltaE3') AND name='DF_E3_PlantaEstado')
 ALTER TABLE prod.PlantaPaltaE3 DROP CONSTRAINT DF_E3_PlantaEstado;
ALTER TABLE prod.PlantaPaltaE3 ADD CONSTRAINT DF_E3_PlantaEstado DEFAULT('SANA') FOR estado_actual;
GO
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('prod.PlantaPaltaE3') AND name='CK_E3_PlantaEstado')
 ALTER TABLE prod.PlantaPaltaE3 DROP CONSTRAINT CK_E3_PlantaEstado;
ALTER TABLE prod.PlantaPaltaE3 WITH CHECK ADD CONSTRAINT CK_E3_PlantaEstado
 CHECK(estado_actual IN('SANA','ENFERMA','MUERTA'));
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('prod.PlantaPaltaE3') AND name='CK_E3_PlantaActivo')
 ALTER TABLE prod.PlantaPaltaE3 WITH CHECK ADD CONSTRAINT CK_E3_PlantaActivo
 CHECK((estado_actual='MUERTA' AND activo=0) OR (estado_actual IN('SANA','ENFERMA') AND activo=1));
GO
-- Una planta muerta no puede reactivarse, editarse ni sufrir modificaciones posteriores.
CREATE OR ALTER TRIGGER prod.TR_E3_PlantaMuertaTerminal ON prod.PlantaPaltaE3 AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.planta_id=I.planta_id WHERE D.estado_actual='MUERTA')
  THROW 51182,N'Una planta muerta no se puede modificar.',1;
END;
GO
