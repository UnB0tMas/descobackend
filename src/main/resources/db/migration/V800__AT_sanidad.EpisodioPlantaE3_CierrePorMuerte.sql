-- Resultado terminal distinto de recuperación. Los episodios recuperados previos no cambian.
ALTER TABLE sanidad.EpisodioPlantaE3 ADD cierre_por_muerte BIT NOT NULL
 CONSTRAINT DF_E3_EpisodioCierrePorMuerte DEFAULT (0);
GO
ALTER TABLE sanidad.EpisodioPlantaE3 WITH CHECK ADD CONSTRAINT CK_E3_EpisodioCierrePorMuerte
 CHECK (cierre_por_muerte=0 OR fin IS NOT NULL);
GO
-- Regularizar únicamente bajas históricas con actuación de muerte y fecha coherentes.
UPDATE E SET cierre_por_muerte=1,fin=H.fecha_hecho,usuario_cierre_id=H.usuario_id,
 motivo_cierre=LEFT(COALESCE(NULLIF(TRIM(H.observacion),N''),N'Cierre histórico por muerte de la planta.'),600)
FROM sanidad.EpisodioPlantaE3 E
JOIN prod.PlantaPaltaE3 P ON P.planta_id=E.planta_id AND P.estado_actual='MUERTA'
CROSS APPLY (SELECT TOP(1) X.fecha_hecho,X.usuario_id,X.observacion
 FROM prod.PlantaEventoE3 X WHERE X.planta_id=P.planta_id AND X.estado_nuevo='MUERTA'
 ORDER BY X.fecha_hecho DESC,X.evento_id DESC) H
WHERE E.activo=1 AND E.fin IS NULL AND H.fecha_hecho>=E.inicio
 AND NOT EXISTS(SELECT 1 FROM sanidad.TratamientoPlantaE3 T
  WHERE T.episodio_id=E.episodio_id AND T.fecha_aplicacion>H.fecha_hecho);
GO
