IF OBJECT_ID(N'[org].[FN_Ruc_Naturaleza]', N'FN') IS NOT NULL
   OR OBJECT_ID(N'[org].[FN_Ruc_Naturaleza]', N'IF') IS NOT NULL
   OR OBJECT_ID(N'[org].[FN_Ruc_Naturaleza]', N'TF') IS NOT NULL
    DROP FUNCTION [org].[FN_Ruc_Naturaleza];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Función           : org.FN_Ruc_Naturaleza
' Descripción              : Determina la naturaleza del contribuyente a partir de un RUC válido.
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
    SELECT [org].[FN_Ruc_Naturaleza]('20123456789') AS Naturaleza;
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
