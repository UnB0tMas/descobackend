IF OBJECT_ID(N'[config].[FN_CodigoCatalogo]', N'FN') IS NOT NULL
   OR OBJECT_ID(N'[config].[FN_CodigoCatalogo]', N'IF') IS NOT NULL
   OR OBJECT_ID(N'[config].[FN_CodigoCatalogo]', N'TF') IS NOT NULL
    DROP FUNCTION [config].[FN_CodigoCatalogo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Función           : config.FN_CodigoCatalogo
' Descripción              : Genera un código normalizado para un registro de catálogo.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Configuración
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT [config].[FN_CodigoCatalogo](N'CATALOGO', 1) AS Codigo;
*******************************************************************************************************/
CREATE FUNCTION [config].[FN_CodigoCatalogo]
(
    @cNombre NVARCHAR(150),
    @nId BIGINT
)
RETURNS VARCHAR(40)
AS
BEGIN
    IF @nId IS NULL
        RETURN NULL;

    DECLARE @cTexto NVARCHAR(300) =
        UPPER(LTRIM(RTRIM(ISNULL(@cNombre,N''))));

    SET @cTexto = TRANSLATE(
        @cTexto,
        N'ÁÉÍÓÚÜÑÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÇ',
        N'AEIOUUNAEIOUAEIOUAEIOUC'
    );

    DECLARE
        @cLimpio NVARCHAR(300)=N'',
        @cCaracter NCHAR(1),
        @nPos INT=1;

    WHILE @nPos <= LEN(@cTexto)
    BEGIN
        SET @cCaracter=SUBSTRING(@cTexto,@nPos,1);

        IF @cCaracter LIKE N'[A-Z0-9]' COLLATE Latin1_General_100_BIN2
            SET @cLimpio += @cCaracter;
        ELSE
            SET @cLimpio += N' ';

        SET @nPos += 1;
    END;

    WHILE CHARINDEX(N'  ',@cLimpio)>0
        SET @cLimpio=REPLACE(@cLimpio,N'  ',N' ');

    SET @cLimpio=LTRIM(RTRIM(@cLimpio));

    DECLARE
        @cSigla VARCHAR(6)='',
        @cResto NVARCHAR(300)=@cLimpio,
        @cPalabra NVARCHAR(100),
        @nEspacio INT;

    WHILE LEN(@cResto)>0 AND LEN(@cSigla)<6
    BEGIN
        SET @nEspacio=CHARINDEX(N' ',@cResto+N' ');
        SET @cPalabra=LEFT(@cResto,@nEspacio-1);
        SET @cResto=LTRIM(SUBSTRING(@cResto,@nEspacio+1,300));

        IF @cPalabra<>N''
           AND @cPalabra NOT IN
           (
               N'DE',N'DEL',N'LA',N'LAS',N'EL',N'LOS',
               N'Y',N'E',N'EN',N'PARA',N'POR',N'CON',
               N'SIN',N'A',N'AL'
           )
        BEGIN
            SET @cSigla += CONVERT(VARCHAR(1),LEFT(@cPalabra,1));
        END;
    END;

    IF @cSigla=''
        SET @cSigla='X';

    RETURN LEFT(@cSigla,6)
        + '-'
        + RIGHT(REPLICATE('0',7)+CONVERT(VARCHAR(20),@nId),7);
END;
GO
