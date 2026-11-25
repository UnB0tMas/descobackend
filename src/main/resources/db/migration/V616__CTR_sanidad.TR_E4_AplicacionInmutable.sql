IF OBJECT_ID(N'[sanidad].[TR_E4_AplicacionInmutable]') IS NOT NULL
    DROP TRIGGER [sanidad].[TR_E4_AplicacionInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : sanidad.TR_E4_AplicacionInmutable
' Descripción            : Protege la integridad de e4 aplicacion inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / sanidad
*******************************************************************************************************/
CREATE TRIGGER sanidad.TR_E4_AplicacionInmutable ON sanidad.TratamientoAplicacionE4 AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51382,N'Las aplicaciones de tratamientos son inmutables.',1;
END;
GO
