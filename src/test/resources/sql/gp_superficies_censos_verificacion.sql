-- DESCO / Gestión productiva. Diagnóstico de solo lectura tras V500 y V501.
-- Resultados esperados: cero filas en las consultas de infracciones.
SET NOCOUNT ON;
GO
IF OBJECT_ID(N'prod.PA_GP_Actividad_Ins_Registro', N'P') IS NULL
    THROW 51150, N'Falta el PA de altas productivas.', 1;
IF OBJECT_ID(N'prod.PA_GP_Censo_Ins_Registro', N'P') IS NULL
    THROW 51150, N'Falta el PA de censos versionados.', 1;
GO
-- Parcelas que actualmente exceden su metraje por la suma de actividades activas.
SELECT A.parcela_id AS parcelaId, P.nombre AS parcela, CONVERT(DECIMAL(18,2),P.area_ha)*10000 AS limiteM2,
       SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)) AS ocupadoM2
FROM prod.GPActividad A
JOIN prod.Parcela P ON P.parcela_id=A.parcela_id
OUTER APPLY (
    SELECT TOP (1) C.superficie_exacta_m2,C.superficie_aproximada_m2
    FROM prod.GPCenso C WHERE C.actividad_id=A.actividad_id
    ORDER BY C.fecha_registro DESC,C.censo_id DESC
) C
WHERE A.estado=1 AND P.estado=1
GROUP BY A.parcela_id,P.nombre,P.area_ha
HAVING SUM(COALESCE(C.superficie_exacta_m2,C.superficie_aproximada_m2,0)) > CONVERT(DECIMAL(18,2),P.area_ha)*10000;
GO
-- Versiones con razas que superan la cantidad total exacta de animales.
SELECT C.censo_id,C.actividad_id,C.cantidad_exacta, SUM(R.cantidad_exacta) AS cantidadRazas
FROM prod.GPCenso C JOIN prod.GPCensoRaza R ON R.censo_id=C.censo_id
GROUP BY C.censo_id,C.actividad_id,C.cantidad_exacta
HAVING SUM(R.cantidad_exacta)>C.cantidad_exacta;
GO
-- Versiones con variedades que exceden la superficie declarada del cultivo.
SELECT C.censo_id,C.actividad_id,C.superficie_exacta_m2,SUM(V.superficie_m2) AS superficieVariedadesM2
FROM prod.GPCenso C JOIN prod.GPCensoVariedad V ON V.censo_id=C.censo_id
GROUP BY C.censo_id,C.actividad_id,C.superficie_exacta_m2
HAVING SUM(V.superficie_m2)>C.superficie_exacta_m2;
GO
