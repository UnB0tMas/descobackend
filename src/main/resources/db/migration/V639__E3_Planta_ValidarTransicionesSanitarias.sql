-- V639: responsabilidad única: impedir transiciones sanitarias inconsistentes.
-- Migración posterior a V638 comercial. No modificar V635-V638 ni PAs existentes.
CREATE OR ALTER TRIGGER prod.TR_E3_PlantaTransicionSanitaria
ON prod.PlantaPaltaE3
AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT UPDATE(estado_actual) RETURN;

 -- La muerte exige un estado anterior ENFERMA y al menos una enfermedad
 -- activa registrada para esta etapa sanitaria. El PA cierra los episodios
 -- en la misma transacción antes de modificar estado_actual.
 IF EXISTS (
  SELECT 1 FROM inserted I
  JOIN deleted D ON D.planta_id=I.planta_id
  WHERE I.estado_actual='MUERTA'
    AND (D.estado_actual<>'ENFERMA' OR NOT EXISTS (
      SELECT 1 FROM sanidad.EpisodioPlantaE3 E
      WHERE E.planta_id=I.planta_id AND E.activo=1
        AND E.inicio>=COALESCE((
          SELECT MAX(H.fecha_hecho) FROM prod.PlantaEventoE3 H
          WHERE H.planta_id=I.planta_id AND H.estado_anterior='ENFERMA' AND H.estado_nuevo='SANA'
        ),CONVERT(DATETIME2(0),'19000101'))
    ))
 ) THROW 51230,N'Solo una planta con enfermedad vigente puede declararse muerta.',1;

 -- SIN_EVALUAR -> SANA: primera evaluación permitida sin antecedentes.
 -- ENFERMA -> SANA: las enfermedades vigentes de esta etapa deben estar
 -- cerradas y disponer de tratamiento. Un diagnóstico eliminado por error
 -- (activo=0) no se considera una enfermedad recuperada.
 IF EXISTS (
  SELECT 1 FROM inserted I
  JOIN deleted D ON D.planta_id=I.planta_id
  WHERE I.estado_actual='SANA' AND D.estado_actual='ENFERMA'
    AND EXISTS (
      SELECT 1 FROM sanidad.EpisodioPlantaE3 E
      WHERE E.planta_id=I.planta_id AND E.activo=1
        AND E.inicio>=COALESCE((
          SELECT MAX(H.fecha_hecho) FROM prod.PlantaEventoE3 H
          WHERE H.planta_id=I.planta_id AND H.estado_anterior='ENFERMA' AND H.estado_nuevo='SANA'
        ),CONVERT(DATETIME2(0),'19000101'))
        AND (E.fin IS NULL OR NOT EXISTS (
          SELECT 1 FROM sanidad.TratamientoPlantaE3 T
          WHERE T.episodio_id=E.episodio_id
        ))
    )
 ) THROW 51232,N'Registre tratamientos para cada enfermedad vigente antes de declarar la planta sana.',1;
END;
GO
