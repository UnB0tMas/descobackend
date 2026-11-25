IF OBJECT_ID(N'[prod].[TR_E4_SecaCambioInmutable]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E4_SecaCambioInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E4_SecaCambioInmutable
' Descripción            : Protege la integridad de e4 seca cambio inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E4_SecaCambioInmutable ON prod.PredioMateriaSecaCambioE4
AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51385,N'El registro de auditoría de materia seca es inmutable.',1;
END;
GO
