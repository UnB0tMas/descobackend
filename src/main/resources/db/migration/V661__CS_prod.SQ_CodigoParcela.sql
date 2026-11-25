-- Secuencia para códigos PAR- de 12 dígitos.
-- Solo se crea cuando falta: nunca reiniciar una secuencia existente.
IF SCHEMA_ID(N'prod') IS NULL
BEGIN
    THROW 51660, N'El esquema prod no existe.', 1;
END;

IF OBJECT_ID(N'prod.SQ_CodigoParcela') IS NOT NULL
   AND OBJECT_ID(N'prod.SQ_CodigoParcela', N'SO') IS NULL
BEGIN
    THROW 51661, N'El nombre de la secuencia está ocupado por otro objeto.', 1;
END;

IF OBJECT_ID(N'prod.SQ_CodigoParcela', N'SO') IS NULL
BEGIN
    DECLARE @nUltimoCodigo BIGINT;
    DECLARE @nInicio BIGINT;
    DECLARE @cSql NVARCHAR(MAX);

    -- Conservar los códigos existentes, incluso de registros inactivos.
    SELECT @nUltimoCodigo = MAX(TRY_CONVERT(BIGINT, SUBSTRING(P.codigo, 5, 12)))
    FROM prod.Parcela AS P
    WHERE LEN(P.codigo) = 16
      AND LEFT(P.codigo, 4) = 'PAR-'
      AND SUBSTRING(P.codigo, 5, 12) NOT LIKE '%[^0-9]%';

    SET @nInicio = ISNULL(@nUltimoCodigo, 0) + 1;

    IF @nInicio > 999999999999
    BEGIN
        THROW 51662, N'Se agotó el espacio de códigos de 12 dígitos.', 1;
    END;

    SET @cSql = N'CREATE SEQUENCE prod.SQ_CodigoParcela AS BIGINT '
              + N'START WITH ' + CONVERT(NVARCHAR(20), @nInicio)
              + N' INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999999999 NO CYCLE NO CACHE;';

    EXEC sys.sp_executesql @cSql;
END;
