IF OBJECT_ID(N'[prod].[VW_PlantaProduccionResumenE3]') IS NOT NULL
    DROP VIEW [prod].[VW_PlantaProduccionResumenE3];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Vista         : prod.VW_PlantaProduccionResumenE3
' Descripción            : Expone la información de vw planta produccion resumen e3 para consulta.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   VIEW prod.VW_PlantaProduccionResumenE3 AS
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
