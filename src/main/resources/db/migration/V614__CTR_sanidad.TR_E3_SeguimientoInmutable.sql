IF OBJECT_ID(N'[sanidad].[TR_E3_SeguimientoInmutable]') IS NOT NULL
    DROP TRIGGER [sanidad].[TR_E3_SeguimientoInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : sanidad.TR_E3_SeguimientoInmutable
' Descripción            : Protege la integridad de e3 seguimiento inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / sanidad
*******************************************************************************************************/
CREATE TRIGGER sanidad.TR_E3_SeguimientoInmutable ON sanidad.PlantaSeguimientoE3 AFTER UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51188,N'El historial de seguimientos es inmutable.',1;
END;
GO
