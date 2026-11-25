IF OBJECT_ID(N'[org].[FN_Ruc_Naturaleza]') IS NOT NULL
    DROP FUNCTION [org].[FN_Ruc_Naturaleza];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Función       : org.FN_Ruc_Naturaleza
' Descripción            : Determina la naturaleza del contribuyente a partir de un RUC válido.
' Aplicativo / Módulo    : DESCO / Organización
*******************************************************************************************************/
CREATE FUNCTION [org].[FN_Ruc_Naturaleza]
(
    @cRuc VARCHAR(30)
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @c VARCHAR(30)=NULLIF(LTRIM(RTRIM(@cRuc)),'');

    IF [org].[FN_Ruc_EsValido](@c)=0
        RETURN NULL;

    IF LEFT(@c,2) IN ('10','15','17') RETURN 'NATURAL';
    IF LEFT(@c,2)='20' RETURN 'JURIDICA';

    RETURN 'OTRO';
END;
GO
