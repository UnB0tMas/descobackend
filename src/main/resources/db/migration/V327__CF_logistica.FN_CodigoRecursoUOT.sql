IF OBJECT_ID(N'[logistica].[FN_CodigoRecursoUOT]', N'FN') IS NOT NULL
   OR OBJECT_ID(N'[logistica].[FN_CodigoRecursoUOT]', N'IF') IS NOT NULL
   OR OBJECT_ID(N'[logistica].[FN_CodigoRecursoUOT]', N'TF') IS NOT NULL
    DROP FUNCTION [logistica].[FN_CodigoRecursoUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Función           : logistica.FN_CodigoRecursoUOT
' Descripción              : Genera el código de un recurso asociado a una UOT.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT [logistica].[FN_CodigoRecursoUOT](1, N'RECURSO', 1) AS Codigo;
*******************************************************************************************************/
CREATE FUNCTION [logistica].[FN_CodigoRecursoUOT]
(
    @nUotId BIGINT,
    @cNombre NVARCHAR(180),
    @nId BIGINT
)
RETURNS VARCHAR(40)
AS
BEGIN
    IF @nUotId IS NULL OR @nId IS NULL
        RETURN NULL;

    DECLARE
        @cUotNombre NVARCHAR(180),
        @cTexto NVARCHAR(300),
        @cLimpio NVARCHAR(300),
        @cPalabra NVARCHAR(100),
        @cCaracter NCHAR(1),
        @cSiglaUot VARCHAR(6) = '',
        @cSiglaRecurso VARCHAR(6) = '',
        @nPos INT,
        @nEspacio INT;

    SELECT @cUotNombre = U.nombre
    FROM org.UOT U
    WHERE U.uot_id = @nUotId;

    /* -------- UOT -------- */
    SET @cTexto = UPPER(LTRIM(RTRIM(ISNULL(@cUotNombre, N''))));
    SET @cTexto = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        @cTexto, N'Á', N'A'), N'É', N'E'), N'Í', N'I'), N'Ó', N'O'),
        N'Ú', N'U'), N'Ü', N'U'), N'Ñ', N'N');

    SET @cLimpio = N'';
    SET @nPos = 1;

    WHILE @nPos <= LEN(@cTexto)
    BEGIN
        SET @cCaracter = SUBSTRING(@cTexto, @nPos, 1);

        SET @cLimpio +=
            CASE
                WHEN @cCaracter LIKE N'[A-Z0-9]'
                     COLLATE Latin1_General_100_BIN2
                    THEN @cCaracter
                ELSE N' '
            END;

        SET @nPos += 1;
    END;

    WHILE CHARINDEX(N'  ', @cLimpio) > 0
        SET @cLimpio = REPLACE(@cLimpio, N'  ', N' ');

    SET @cTexto = LTRIM(RTRIM(@cLimpio));

    WHILE LEN(@cTexto) > 0 AND LEN(@cSiglaUot) < 6
    BEGIN
        SET @nEspacio = CHARINDEX(N' ', @cTexto + N' ');
        SET @cPalabra = LEFT(@cTexto, @nEspacio - 1);
        SET @cTexto = LTRIM(SUBSTRING(@cTexto, @nEspacio + 1, 300));

        IF @cPalabra <> N''
           AND @cPalabra NOT IN
           (
               N'UOT', N'DE', N'DEL', N'LA', N'LAS', N'EL', N'LOS',
               N'Y', N'E', N'EN', N'PARA', N'POR', N'CON', N'SIN'
           )
        BEGIN
            SET @cSiglaUot += CONVERT(VARCHAR(1), LEFT(@cPalabra, 1));
        END;
    END;

    /* -------- recurso -------- */
    SET @cTexto = UPPER(LTRIM(RTRIM(ISNULL(@cNombre, N''))));
    SET @cTexto = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        @cTexto, N'Á', N'A'), N'É', N'E'), N'Í', N'I'), N'Ó', N'O'),
        N'Ú', N'U'), N'Ü', N'U'), N'Ñ', N'N');

    SET @cLimpio = N'';
    SET @nPos = 1;

    WHILE @nPos <= LEN(@cTexto)
    BEGIN
        SET @cCaracter = SUBSTRING(@cTexto, @nPos, 1);

        SET @cLimpio +=
            CASE
                WHEN @cCaracter LIKE N'[A-Z0-9]'
                     COLLATE Latin1_General_100_BIN2
                    THEN @cCaracter
                ELSE N' '
            END;

        SET @nPos += 1;
    END;

    WHILE CHARINDEX(N'  ', @cLimpio) > 0
        SET @cLimpio = REPLACE(@cLimpio, N'  ', N' ');

    SET @cTexto = LTRIM(RTRIM(@cLimpio));

    WHILE LEN(@cTexto) > 0 AND LEN(@cSiglaRecurso) < 6
    BEGIN
        SET @nEspacio = CHARINDEX(N' ', @cTexto + N' ');
        SET @cPalabra = LEFT(@cTexto, @nEspacio - 1);
        SET @cTexto = LTRIM(SUBSTRING(@cTexto, @nEspacio + 1, 300));

        IF @cPalabra <> N''
           AND @cPalabra NOT IN
           (
               N'DE', N'DEL', N'LA', N'LAS', N'EL', N'LOS',
               N'Y', N'E', N'EN', N'PARA', N'POR', N'CON', N'SIN'
           )
        BEGIN
            SET @cSiglaRecurso +=
                CONVERT(VARCHAR(1), LEFT(@cPalabra, 1));
        END;
    END;

    IF @cSiglaUot = ''
        SET @cSiglaUot = 'U' + CONVERT(VARCHAR(5), @nUotId);

    IF @cSiglaRecurso = ''
        SET @cSiglaRecurso = 'R';

    RETURN
        LEFT(@cSiglaUot, 6)
        + '-'
        + LEFT(@cSiglaRecurso, 6)
        + '-'
        + RIGHT(
            REPLICATE('0', 7) + CONVERT(VARCHAR(20), @nId),
            7
        );
END;
GO
