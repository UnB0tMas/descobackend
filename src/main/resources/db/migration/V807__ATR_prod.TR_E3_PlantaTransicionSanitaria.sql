IF OBJECT_ID(N'[prod].[TR_E3_PlantaTransicionSanitaria]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E3_PlantaTransicionSanitaria];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E3_PlantaTransicionSanitaria
' Descripción            : Controla las modificaciones de e3 planta transicion sanitaria mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   TRIGGER prod.TR_E3_PlantaTransicionSanitaria
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
    AND (D.estado_actual<>'ENFERMA' OR EXISTS (SELECT 1 FROM sanidad.EpisodioPlantaE3 A WHERE A.planta_id=I.planta_id AND A.activo=1 AND A.fin IS NULL) OR NOT EXISTS (
      SELECT 1 FROM sanidad.EpisodioPlantaE3 E
      WHERE E.planta_id=I.planta_id AND E.activo=1 AND E.cierre_por_muerte=1 AND E.fin IS NOT NULL
    ))
 ) THROW 51230,N'La muerte requiere cerrar las enfermedades vigentes como no controladas.',1;

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
