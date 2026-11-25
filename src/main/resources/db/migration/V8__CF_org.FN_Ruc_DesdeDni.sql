IF OBJECT_ID(N'[org].[FN_Ruc_DesdeDni]') IS NOT NULL
    DROP FUNCTION [org].[FN_Ruc_DesdeDni];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : org.FN_Ruc_DesdeDni
' Descripción            : Calcula el RUC de persona natural a partir de un DNI.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE FUNCTION [org].[FN_Ruc_DesdeDni]
(
    @cDni VARCHAR(30)
)
RETURNS VARCHAR(11)
AS
BEGIN
    DECLARE @c VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cDni)),'');
    DECLARE @cBase VARCHAR(10);
    DECLARE @nSuma INT;
    DECLARE @nDv INT;

    IF @c IS NULL OR LEN(@c)<>8 OR @c LIKE '%[^0-9]%'
        RETURN NULL;

    SET @cBase='10'+@c;
    SET @nSuma=
          CONVERT(INT,SUBSTRING(@cBase,1,1))*5
        + CONVERT(INT,SUBSTRING(@cBase,2,1))*4
        + CONVERT(INT,SUBSTRING(@cBase,3,1))*3
        + CONVERT(INT,SUBSTRING(@cBase,4,1))*2
        + CONVERT(INT,SUBSTRING(@cBase,5,1))*7
        + CONVERT(INT,SUBSTRING(@cBase,6,1))*6
        + CONVERT(INT,SUBSTRING(@cBase,7,1))*5
        + CONVERT(INT,SUBSTRING(@cBase,8,1))*4
        + CONVERT(INT,SUBSTRING(@cBase,9,1))*3
        + CONVERT(INT,SUBSTRING(@cBase,10,1))*2;

    SET @nDv=11-(@nSuma%11);
    IF @nDv=10 SET @nDv=0;
    ELSE IF @nDv=11 SET @nDv=1;

    RETURN @cBase+CONVERT(VARCHAR(1),@nDv);
END;
GO
