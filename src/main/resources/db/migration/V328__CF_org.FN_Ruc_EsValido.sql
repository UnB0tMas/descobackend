IF OBJECT_ID(N'[org].[FN_Ruc_EsValido]', N'FN') IS NOT NULL
   OR OBJECT_ID(N'[org].[FN_Ruc_EsValido]', N'IF') IS NOT NULL
   OR OBJECT_ID(N'[org].[FN_Ruc_EsValido]', N'TF') IS NOT NULL
    DROP FUNCTION [org].[FN_Ruc_EsValido];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Función           : org.FN_Ruc_EsValido
' Descripción              : Comprueba la validez formal y el dígito verificador de un RUC.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT [org].[FN_Ruc_EsValido]('20123456789') AS EsValido;
*******************************************************************************************************/
CREATE FUNCTION [org].[FN_Ruc_EsValido]
(
    @cRuc VARCHAR(30)
)
RETURNS BIT
AS
BEGIN
    DECLARE @c VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cRuc)),'');
    DECLARE @nSuma INT;
    DECLARE @nDv INT;

    IF @c IS NULL OR LEN(@c)<>11 OR @c LIKE '%[^0-9]%'
        RETURN 0;

    SET @nSuma=
          CONVERT(INT,SUBSTRING(@c,1,1))*5
        + CONVERT(INT,SUBSTRING(@c,2,1))*4
        + CONVERT(INT,SUBSTRING(@c,3,1))*3
        + CONVERT(INT,SUBSTRING(@c,4,1))*2
        + CONVERT(INT,SUBSTRING(@c,5,1))*7
        + CONVERT(INT,SUBSTRING(@c,6,1))*6
        + CONVERT(INT,SUBSTRING(@c,7,1))*5
        + CONVERT(INT,SUBSTRING(@c,8,1))*4
        + CONVERT(INT,SUBSTRING(@c,9,1))*3
        + CONVERT(INT,SUBSTRING(@c,10,1))*2;

    SET @nDv=11-(@nSuma%11);
    IF @nDv=10 SET @nDv=0;
    ELSE IF @nDv=11 SET @nDv=1;

    RETURN CASE WHEN @nDv=CONVERT(INT,RIGHT(@c,1)) THEN 1 ELSE 0 END;
END;
GO
