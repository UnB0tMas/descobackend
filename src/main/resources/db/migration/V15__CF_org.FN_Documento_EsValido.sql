IF OBJECT_ID(N'[org].[FN_Documento_EsValido]') IS NOT NULL
    DROP FUNCTION [org].[FN_Documento_EsValido];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : org.FN_Documento_EsValido
' Descripción            : Valida el formato de un documento según su tipo.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE FUNCTION [org].[FN_Documento_EsValido]
(
    @cTipoDocumento VARCHAR(15),
    @cNumeroDocumento VARCHAR(30)
)
RETURNS BIT
AS
BEGIN
    DECLARE @cTipo VARCHAR(15)=UPPER(NULLIF(LTRIM(RTRIM(@cTipoDocumento)),''));
    DECLARE @cDoc VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cNumeroDocumento)),'');

    IF @cTipo='DNI'
        RETURN CASE WHEN @cDoc IS NOT NULL
                          AND LEN(@cDoc)=8
                          AND @cDoc NOT LIKE '%[^0-9]%'
                    THEN 1 ELSE 0 END;

    IF @cTipo='RUC'
        RETURN [org].[FN_Ruc_EsValido](@cDoc);

    IF @cTipo IN ('CE','PASAPORTE','OTRO')
        RETURN CASE WHEN @cDoc IS NOT NULL THEN 1 ELSE 0 END;

    RETURN 0;
END;
GO
