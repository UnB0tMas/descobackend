IF OBJECT_ID(N'[prod].[TR_E3_EventoInmutable]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E3_EventoInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E3_EventoInmutable
' Descripción            : Protege la integridad de e3 evento inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E3_EventoInmutable
ON prod.PlantaEventoE3 AFTER UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 THROW 51183,N'Los eventos son inmutables; registre un nuevo evento.',1;
END;
GO
