IF OBJECT_ID(N'[prod].[TR_DESCO_ParcelaCultivo_Vigencia]') IS NOT NULL
    DROP TRIGGER [prod].[TR_DESCO_ParcelaCultivo_Vigencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_DESCO_ParcelaCultivo_Vigencia
' Descripción            : Controla la vigencia de cultivos asociados a parcelas.
' Aplicativo / Módulo    : DESCO / Producción
*******************************************************************************************************/
CREATE TRIGGER prod.TR_DESCO_ParcelaCultivo_Vigencia ON prod.ParcelaCultivo AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.parcela_cultivo_id=I.parcela_cultivo_id
  WHERE I.estado=1 AND I.fecha_fin IS NULL AND I.situacion_cultivo='ACTIVO'
    AND (D.parcela_cultivo_id IS NULL OR I.parcela_id<>D.parcela_id OR I.estado<>D.estado OR ISNULL(I.fecha_fin,'99991231')<>ISNULL(D.fecha_fin,'99991231') OR ISNULL(I.situacion_cultivo,'')<>ISNULL(D.situacion_cultivo,''))
    AND EXISTS(SELECT 1 FROM prod.ParcelaCultivo X WITH(UPDLOCK,HOLDLOCK) WHERE X.parcela_id=I.parcela_id AND X.estado=1 AND X.fecha_fin IS NULL AND X.situacion_cultivo='ACTIVO' AND X.parcela_cultivo_id<>I.parcela_cultivo_id)
 ) THROW 51031,N'La parcela ya tiene un cultivo activo.',1;
END;
GO
