IF OBJECT_ID(N'[prod].[TR_E1_TitularRegistrarProductor]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E1_TitularRegistrarProductor];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E1_TitularRegistrarProductor
' Descripción            : Controla las modificaciones de e1 titular registrar productor mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E1_TitularRegistrarProductor
ON prod.PredioTitularidad
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT org.Productor(persona_id, fecha_alta, usuario_creacion_id)
    SELECT I.persona_id, MIN(I.fecha_desde), NULL
    FROM inserted I
    JOIN org.Persona P ON P.persona_id = I.persona_id
    WHERE I.persona_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM org.Productor X WITH (UPDLOCK, HOLDLOCK) WHERE X.persona_id = I.persona_id)
    GROUP BY I.persona_id;

    INSERT org.ProductorUOT(persona_id, uot_id, fecha_desde, usuario_creacion_id)
    SELECT I.persona_id, A.uot_id, MIN(I.fecha_desde), A.usuario_creacion_id
    FROM inserted I
    JOIN prod.PredioAmbito A ON A.predio_id = I.predio_id AND A.estado = 1
    JOIN org.Productor P ON P.persona_id = I.persona_id
    WHERE I.persona_id IS NOT NULL
      AND I.estado = 1
      AND NOT EXISTS
      (
          SELECT 1 FROM org.ProductorUOT X WITH (UPDLOCK, HOLDLOCK)
          WHERE X.persona_id = I.persona_id AND X.uot_id = A.uot_id
            AND X.estado = 1 AND X.fecha_hasta IS NULL
      )
    GROUP BY I.persona_id, A.uot_id, A.usuario_creacion_id;
END;
GO
