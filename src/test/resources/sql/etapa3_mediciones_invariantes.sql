-- E3: diagnóstico no destructivo después de V439/V440. No simula transacciones de usuario.
SET NOCOUNT ON;
IF OBJECT_ID(N'prod.PlantaMedicionE3', N'U') IS NULL
    THROW 51190, N'Falta la tabla de materia seca E3.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE object_id=OBJECT_ID(N'prod.PlantaMedicionE3') AND name=N'IX_E3_Medicion_PlantaFecha')
    THROW 51191, N'Falta el índice histórico de mediciones.', 1;
IF EXISTS (SELECT 1 FROM prod.PlantaMedicionE3 M
    JOIN prod.PlantaPaltaE3 P ON P.planta_id=M.planta_id
    WHERE M.porcentaje NOT BETWEEN 0 AND 100 OR P.planta_id IS NULL)
    THROW 51192, N'Existe una medición fuera de rango.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.triggers
    WHERE parent_id=OBJECT_ID(N'prod.PlantaMedicionE3') AND name=N'TR_E3_MedicionInmutable' AND is_disabled=0)
    THROW 51193, N'Falta el bloqueo de edición de mediciones.', 1;
SELECT P.predio_id, P.variedad_palta_id, COUNT_BIG(*) plantas,
       SUM(CASE WHEN P.estado_actual='SIN_EVALUAR' THEN 1 ELSE 0 END) sin_evaluar
FROM prod.PlantaPaltaE3 P
GROUP BY P.predio_id, P.variedad_palta_id
ORDER BY P.predio_id, P.variedad_palta_id;
PRINT 'Verificación estructural E3 completada: ejecutar T08-T12 con usuarios y visitas reales.';
