IF OBJECT_ID(N'[finanzas].[TR_DESCO_LiquidacionSocio_Unicidad]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_DESCO_LiquidacionSocio_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_DESCO_LiquidacionSocio_Unicidad
' Descripción            : Valida reglas de unicidad para liquidaciones de socios.
' Aplicativo / Módulo    : DESCO / Finanzas
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_DESCO_LiquidacionSocio_Unicidad ON finanzas.LiquidacionSocio AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.liquidacion_socio_id=I.liquidacion_socio_id
  WHERE I.estado=1 AND I.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA')
    AND (D.liquidacion_socio_id IS NULL OR I.participacion_campania_socio_id<>D.participacion_campania_socio_id OR I.estado<>D.estado OR ISNULL(I.estado_proceso,'')<>ISNULL(D.estado_proceso,''))
    AND EXISTS(SELECT 1 FROM finanzas.LiquidacionSocio X WITH(UPDLOCK,HOLDLOCK) WHERE X.participacion_campania_socio_id=I.participacion_campania_socio_id AND X.estado=1 AND X.estado_proceso IN('APROBADA','PAGADA_PARCIAL','PAGADA') AND X.liquidacion_socio_id<>I.liquidacion_socio_id)
 ) THROW 51038,N'Ya existe una liquidación vigente para esta participación.',1;
END;
GO
