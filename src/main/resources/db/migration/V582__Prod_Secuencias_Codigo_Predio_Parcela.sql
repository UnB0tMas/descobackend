-- V582: restituye las secuencias necesarias para el alta de predios y parcelas.
-- Aplicar despues de V581. No modifica procedimientos, registros ni codigos existentes.
-- Es idempotente: solo crea cada secuencia si no existe.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
SET NOCOUNT ON;

IF SCHEMA_ID(N'prod') IS NULL
    THROW 51582, N'No existe el esquema prod.', 1;
IF OBJECT_ID(N'prod.Predio', N'U') IS NULL
    THROW 51582, N'No existe la tabla prod.Predio.', 1;
IF OBJECT_ID(N'prod.Parcela', N'U') IS NULL
    THROW 51582, N'No existe la tabla prod.Parcela.', 1;

DECLARE @inicioPredio BIGINT;
DECLARE @inicioParcela BIGINT;
DECLARE @sql NVARCHAR(MAX);

-- El PA usa PRE- seguido de doce digitos. No reutilizar numeros ya registrados.
SELECT @inicioPredio = ISNULL(MAX(TRY_CONVERT(BIGINT, SUBSTRING(P.codigo, 5, 36))), 0) + 1
FROM prod.Predio AS P
WHERE LEFT(P.codigo, 4) = 'PRE-';

-- El PA usa PAR- seguido de doce digitos.
SELECT @inicioParcela = ISNULL(MAX(TRY_CONVERT(BIGINT, SUBSTRING(P.codigo, 5, 36))), 0) + 1
FROM prod.Parcela AS P
WHERE LEFT(P.codigo, 4) = 'PAR-';

IF @inicioPredio > 999999999999 OR @inicioParcela > 999999999999
    THROW 51582, N'Se ha alcanzado el limite de codigos de doce digitos.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.sequences AS S
    INNER JOIN sys.schemas AS E ON E.schema_id = S.schema_id
    WHERE E.name = N'prod' AND S.name = N'SQ_CodigoPredio'
)
BEGIN
    SET @sql = N'CREATE SEQUENCE prod.SQ_CodigoPredio AS BIGINT START WITH '
             + CONVERT(NVARCHAR(20), @inicioPredio)
             + N' INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999999999 NO CYCLE NO CACHE;';
    EXEC sys.sp_executesql @sql;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.sequences AS S
    INNER JOIN sys.schemas AS E ON E.schema_id = S.schema_id
    WHERE E.name = N'prod' AND S.name = N'SQ_CodigoParcela'
)
BEGIN
    SET @sql = N'CREATE SEQUENCE prod.SQ_CodigoParcela AS BIGINT START WITH '
             + CONVERT(NVARCHAR(20), @inicioParcela)
             + N' INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999999999 NO CYCLE NO CACHE;';
    EXEC sys.sp_executesql @sql;
END;
GO

-- QA de existencia sin consumir valores de las secuencias.
IF (SELECT COUNT_BIG(*)
    FROM sys.sequences AS S
    INNER JOIN sys.schemas AS E ON E.schema_id = S.schema_id
    WHERE E.name = N'prod' AND S.name IN (N'SQ_CodigoPredio', N'SQ_CodigoParcela')) <> 2
    THROW 51582, N'Falta alguna secuencia de codigos de predios o parcelas.', 1;

SELECT E.name AS esquema,
       S.name AS secuencia,
       S.start_value AS valor_inicial,
       S.current_value AS valor_actual,
       S.increment AS incremento
FROM sys.sequences AS S
INNER JOIN sys.schemas AS E ON E.schema_id = S.schema_id
WHERE E.name = N'prod'
  AND S.name IN (N'SQ_CodigoPredio', N'SQ_CodigoParcela')
ORDER BY S.name;
GO
