IF OBJECT_ID(N'[prod].[TR_E4_SecaGlobalInmutable]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E4_SecaGlobalInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E4_SecaGlobalInmutable
' Descripción            : Protege la integridad de e4 seca global inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   TRIGGER prod.TR_E4_SecaGlobalInmutable
ON prod.PredioMateriaSecaGlobalE4 AFTER DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51384,N'La materia seca del fundo se conserva: use inactivación.',1;
END;
GO
