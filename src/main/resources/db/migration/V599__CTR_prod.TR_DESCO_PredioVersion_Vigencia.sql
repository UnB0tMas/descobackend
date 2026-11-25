IF OBJECT_ID(N'[prod].[TR_DESCO_PredioVersion_Vigencia]') IS NOT NULL
    DROP TRIGGER [prod].[TR_DESCO_PredioVersion_Vigencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_DESCO_PredioVersion_Vigencia
' Descripción            : Controla la vigencia de versiones de predios.
' Aplicativo / Módulo    : DESCO / Producción
*******************************************************************************************************/
CREATE TRIGGER prod.TR_DESCO_PredioVersion_Vigencia ON prod.PredioVersion AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.predio_version_id=I.predio_version_id
  WHERE I.estado=1 AND I.fecha_hasta IS NULL
    AND (D.predio_version_id IS NULL OR I.predio_id<>D.predio_id OR I.estado<>D.estado OR ISNULL(I.fecha_hasta,'99991231')<>ISNULL(D.fecha_hasta,'99991231'))
    AND EXISTS(SELECT 1 FROM prod.PredioVersion X WITH(UPDLOCK,HOLDLOCK) WHERE X.predio_id=I.predio_id AND X.estado=1 AND X.fecha_hasta IS NULL AND X.predio_version_id<>I.predio_version_id)
 ) THROW 51029,N'El predio ya tiene una versión vigente.',1;
END;
GO
