IF OBJECT_ID(N'[sanidad].[TR_E3_TratamientoInmutable]') IS NOT NULL
    DROP TRIGGER [sanidad].[TR_E3_TratamientoInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : sanidad.TR_E3_TratamientoInmutable
' Descripción            : Protege la integridad de e3 tratamiento inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / sanidad
*******************************************************************************************************/
CREATE TRIGGER sanidad.TR_E3_TratamientoInmutable
ON sanidad.TratamientoPlantaE3 AFTER UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 THROW 51184,N'Los tratamientos son inmutables.',1;
END;
GO
