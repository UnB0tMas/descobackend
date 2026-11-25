IF OBJECT_ID(N'[sanidad].[TR_E4_NotaInmutable]') IS NOT NULL
    DROP TRIGGER [sanidad].[TR_E4_NotaInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : sanidad.TR_E4_NotaInmutable
' Descripción            : Protege la integridad de e4 nota inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / sanidad
*******************************************************************************************************/
CREATE TRIGGER sanidad.TR_E4_NotaInmutable ON sanidad.EpisodioNotaE4 AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51381,N'Las notas de la enfermedad se conservan como historial inmutable.',1;
END;
GO
