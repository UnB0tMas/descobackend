IF OBJECT_ID(N'[prod].[TR_E1_AmbitoRegistrarProductorUOT]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E1_AmbitoRegistrarProductorUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E1_AmbitoRegistrarProductorUOT
' Descripción            : Controla las modificaciones de e1 ambito registrar productor uot mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E1_AmbitoRegistrarProductorUOT
ON prod.PredioAmbito
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT org.ProductorUOT(persona_id, uot_id, fecha_desde, usuario_creacion_id)
    SELECT T.persona_id, I.uot_id, MIN(T.fecha_desde), I.usuario_creacion_id
    FROM inserted I
    JOIN prod.PredioTitularidad T ON T.predio_id = I.predio_id
        AND T.estado = 1 AND T.fecha_hasta IS NULL
    JOIN org.Productor P ON P.persona_id = T.persona_id
    WHERE I.estado = 1
      AND NOT EXISTS
      (
          SELECT 1 FROM org.ProductorUOT X WITH (UPDLOCK, HOLDLOCK)
          WHERE X.persona_id = T.persona_id AND X.uot_id = I.uot_id
            AND X.estado = 1 AND X.fecha_hasta IS NULL
      )
    GROUP BY T.persona_id, I.uot_id, I.usuario_creacion_id;
END;
GO
