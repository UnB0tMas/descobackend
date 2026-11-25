IF OBJECT_ID(N'[logistica].[TR_DESCO_SuministroMovimiento_Unicidad]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_SuministroMovimiento_Unicidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DESCO_SuministroMovimiento_Unicidad
' Descripción            : Valida la unicidad de movimientos de suministros.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_SuministroMovimiento_Unicidad ON logistica.SuministroMovimiento AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.suministro_movimiento_id=I.suministro_movimiento_id
  WHERE I.recurso_movimiento_id IS NOT NULL
    AND (D.suministro_movimiento_id IS NULL OR ISNULL(I.recurso_movimiento_id,-1)<>ISNULL(D.recurso_movimiento_id,-1))
    AND EXISTS(SELECT 1 FROM logistica.SuministroMovimiento X WITH(UPDLOCK,HOLDLOCK) WHERE X.recurso_movimiento_id=I.recurso_movimiento_id AND X.suministro_movimiento_id<>I.suministro_movimiento_id)
 ) THROW 51034,N'El movimiento ya fue registrado.',1;
 IF EXISTS(
  SELECT 1 FROM inserted I LEFT JOIN deleted D ON D.suministro_movimiento_id=I.suministro_movimiento_id
  WHERE I.movimiento_origen_id IS NOT NULL
    AND (D.suministro_movimiento_id IS NULL OR ISNULL(I.movimiento_origen_id,-1)<>ISNULL(D.movimiento_origen_id,-1))
    AND EXISTS(SELECT 1 FROM logistica.SuministroMovimiento X WITH(UPDLOCK,HOLDLOCK) WHERE X.movimiento_origen_id=I.movimiento_origen_id AND X.suministro_movimiento_id<>I.suministro_movimiento_id)
 ) THROW 51035,N'El movimiento ya fue anulado.',1;
END;
GO
