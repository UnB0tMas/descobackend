IF OBJECT_ID(N'[prod].[TR_E1_PredioVersion_CompletarProgresivo]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E1_PredioVersion_CompletarProgresivo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E1_PredioVersion_CompletarProgresivo
' Descripción            : Controla las modificaciones de e1 predio version completar progresivo mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E1_PredioVersion_CompletarProgresivo
ON prod.PredioVersion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE V
       SET area_total_ha = COALESCE(V.area_total_ha, A.area_total_ha),
           area_cultivable_ha = COALESCE(V.area_cultivable_ha, A.area_cultivable_ha),
           tipo_riego = COALESCE(NULLIF(V.tipo_riego, ''), A.tipo_riego),
           fuente_agua = COALESCE(NULLIF(V.fuente_agua, N''), A.fuente_agua),
           infraestructura = COALESCE(NULLIF(V.infraestructura, N''), A.infraestructura),
           observacion = COALESCE(NULLIF(V.observacion, N''), A.observacion)
    FROM prod.PredioVersion V
    JOIN inserted I ON I.predio_version_id = V.predio_version_id
    OUTER APPLY
    (
        SELECT TOP (1) X.area_total_ha, X.area_cultivable_ha, X.tipo_riego,
               X.fuente_agua, X.infraestructura, X.observacion
        FROM prod.PredioVersion X
        WHERE X.predio_id = I.predio_id
          AND X.predio_version_id <> I.predio_version_id
        ORDER BY X.fecha_desde DESC, X.revision DESC, X.predio_version_id DESC
    ) A;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN prod.PredioVersion V ON V.predio_version_id = I.predio_version_id
        WHERE V.area_total_ha IS NULL
          AND V.area_cultivable_ha IS NULL
          AND NULLIF(V.tipo_riego, '') IS NULL
          AND NULLIF(V.fuente_agua, N'') IS NULL
          AND NULLIF(V.infraestructura, N'') IS NULL
          AND NULLIF(V.observacion, N'') IS NULL
    )
        THROW 51066, N'La ficha técnica no contiene cambios para guardar.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN prod.PredioVersion V ON V.predio_version_id = I.predio_version_id
        WHERE V.area_total_ha IS NOT NULL AND V.area_total_ha <= 0
           OR V.area_cultivable_ha IS NOT NULL AND
              (V.area_cultivable_ha < 0 OR V.area_total_ha IS NOT NULL AND V.area_cultivable_ha > V.area_total_ha)
    )
        THROW 51067, N'Las áreas de la ficha técnica no son válidas.', 1;
END;
GO
