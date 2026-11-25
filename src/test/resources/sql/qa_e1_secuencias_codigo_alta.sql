-- QA: comprobar códigos y secuencias sin consumir consecutivos.
SET NOCOUNT ON;

IF OBJECT_ID(N'prod.SQ_CodigoPredio', N'SO') IS NULL
   OR OBJECT_ID(N'prod.SQ_CodigoParcela', N'SO') IS NULL
BEGIN
    THROW 51663, N'Faltan las secuencias para generar códigos.', 1;
END;

SELECT S.name AS secuencia,
       CONVERT(BIGINT, S.current_value) AS valor_actual,
       CONVERT(BIGINT, S.increment) AS incremento,
       CONVERT(BIGINT, S.maximum_value) AS limite,
       S.is_cycling AS reinicio_automatico
FROM sys.sequences AS S
JOIN sys.schemas AS H ON H.schema_id = S.schema_id
WHERE H.name = N'prod'
  AND S.name IN (N'SQ_CodigoPredio', N'SQ_CodigoParcela')
ORDER BY S.name;

-- Verificar que los códigos existentes respeten la unicidad por registro.
SELECT P.codigo, COUNT_BIG(*) AS duplicados
FROM prod.Predio AS P
GROUP BY P.codigo
HAVING COUNT_BIG(*) > 1;

SELECT P.predio_id, P.codigo, COUNT_BIG(*) AS duplicados
FROM prod.Parcela AS P
GROUP BY P.predio_id, P.codigo
HAVING COUNT_BIG(*) > 1;

-- No modificar las secuencias: NEXT VALUE FOR consume números.
PRINT N'QA finalizado: ejecutar el alta de un fundo en DEV.';
