IF OBJECT_ID(N'[prod].[TR_DESCO_PredioTitularidad_Vigencia]') IS NOT NULL
    DROP TRIGGER [prod].[TR_DESCO_PredioTitularidad_Vigencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_DESCO_PredioTitularidad_Vigencia
' Descripción            : Controla las modificaciones de desco predio titularidad vigencia mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_DESCO_PredioTitularidad_Vigencia ON prod.PredioTitularidad AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN prod.PredioTitularidad X WITH(UPDLOCK,HOLDLOCK)
       ON X.predio_id=I.predio_id AND X.persona_id=I.persona_id AND X.predio_titularidad_id<>I.predio_titularidad_id
       WHERE I.estado=1 AND I.fecha_hasta IS NULL AND X.estado=1 AND X.fecha_hasta IS NULL)
     THROW 51030,N'El titular ya tiene una vigencia abierta en el predio.',1;
END;
GO
