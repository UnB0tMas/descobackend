IF OBJECT_ID(N'[prod].[TR_E1_TitularValidarPersona]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E1_TitularValidarPersona];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E1_TitularValidarPersona
' Descripción            : Valida las reglas de e1 titular validar persona al modificar registros.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E1_TitularValidarPersona
ON prod.PredioTitularidad AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM inserted I WHERE I.persona_id IS NULL
       OR (I.socio_id IS NOT NULL AND I.socio_id<>I.persona_id))
        THROW 51051,N'La titularidad debe referirse a la misma persona.',1;
END;
GO
