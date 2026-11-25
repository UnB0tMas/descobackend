IF OBJECT_ID(N'[logistica].[TR_DESCO_Suministro_Integridad]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_DESCO_Suministro_Integridad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_DESCO_Suministro_Integridad
' Descripción            : Valida reglas de integridad de los suministros.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_DESCO_Suministro_Integridad
ON logistica.Suministro AFTER INSERT,UPDATE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN deleted D ON D.suministro_id=I.suministro_id
  WHERE I.unidad_medida<>D.unidad_medida AND EXISTS(SELECT 1 FROM logistica.SuministroMovimiento M WHERE M.suministro_id=I.suministro_id))
  THROW 51100,N'DESCO_UNIDAD_CON_MOVIMIENTOS',1;
 INSERT logistica.SuministroSaldo(suministro_id)
 SELECT I.suministro_id FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM logistica.SuministroSaldo S WHERE S.suministro_id=I.suministro_id);
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.SuministroSaldo S ON S.suministro_id=I.suministro_id
  WHERE I.estado=0 AND (S.stock_actual<>0 OR S.stock_reservado<>0))
  THROW 51100,N'DESCO_RECURSO_NO_DISPONIBLE',1;
END;
GO
