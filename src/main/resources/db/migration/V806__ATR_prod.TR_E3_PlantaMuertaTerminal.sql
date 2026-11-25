IF OBJECT_ID(N'[prod].[TR_E3_PlantaMuertaTerminal]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E3_PlantaMuertaTerminal];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E3_PlantaMuertaTerminal
' Descripción            : Controla las modificaciones de e3 planta muerta terminal mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE   TRIGGER prod.TR_E3_PlantaMuertaTerminal ON prod.PlantaPaltaE3 AFTER UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted D LEFT JOIN inserted I ON I.planta_id=D.planta_id
               WHERE D.estado_actual='MUERTA' OR (D.estado_actual='ELIMINADA' AND (I.planta_id IS NULL OR I.estado_actual<>'ELIMINADA')))
        THROW 51201,N'Esta planta tiene un estado terminal y no admite modificaciones ni eliminación.',1;
END;
GO
