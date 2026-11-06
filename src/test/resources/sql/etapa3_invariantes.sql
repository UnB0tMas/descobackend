-- Diagnóstico de integridad E3, solo lectura; ejecutar en DESCO_DB_dev tras Flyway V435/V436.
SET NOCOUNT ON;
IF OBJECT_ID('prod.PlantaPaltaE3','U') IS NULL OR OBJECT_ID('sanidad.EpisodioPlantaE3','U') IS NULL
    THROW 51170,N'E3 no fue migrada completamente.',1;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_E3_EpisodioAbierto' AND object_id=OBJECT_ID('sanidad.EpisodioPlantaE3'))
    THROW 51171,N'Falta la protección contra episodios abiertos simultáneos.',1;
IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 WHERE estado_actual NOT IN('SIN_EVALUAR','SANA','ENFERMA','MUERTA'))
    THROW 51172,N'Estado individual inválido.',1;
IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P JOIN sanidad.EpisodioPlantaE3 E ON E.planta_id=P.planta_id
    WHERE E.fin IS NULL AND P.estado_actual<>'ENFERMA')
    THROW 51173,N'Existe episodio abierto de planta no enferma.',1;
IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P WHERE P.estado_actual='MUERTA'
 AND EXISTS(SELECT 1 FROM prod.PlantaEventoE3 E WHERE E.planta_id=P.planta_id
  AND E.estado_nuevo='SANA' AND E.evento_id>(SELECT MIN(D.evento_id) FROM prod.PlantaEventoE3 D
  WHERE D.planta_id=P.planta_id AND D.estado_nuevo='MUERTA')))
    THROW 51174,N'Hay cambios de estado posteriores a MUERTA.',1;
IF EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P LEFT JOIN prod.PredioAmbito A
  ON A.predio_id=P.predio_id AND A.uot_id=P.uot_id AND A.convenio_uot_organizacion_id=P.convenio_id AND A.estado=1
  WHERE A.predio_ambito_id IS NULL)
    THROW 51175,N'Existe planta de un ámbito que no corresponde al predio.',1;
SELECT P.predio_id,P.variedad_palta_id,COUNT_BIG(*) cantidad,
 SUM(CASE WHEN P.estado_actual='SIN_EVALUAR' THEN 1 ELSE 0 END) sin_evaluar
FROM prod.PlantaPaltaE3 P GROUP BY P.predio_id,P.variedad_palta_id ORDER BY P.predio_id,P.variedad_palta_id;
PRINT 'Invariantes E3 verificados. Ejecutar T08-T12 mediante endpoints con usuarios reales.';
