IF OBJECT_ID(N'[comercial].[TR_DESCO_Operativo_Jabas]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_DESCO_Operativo_Jabas];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_DESCO_Operativo_Jabas
' Descripción            : Controla relaciones de jabas con operativos de venta.
' Aplicativo / Módulo    : DESCO / Comercial
*******************************************************************************************************/
CREATE TRIGGER comercial.TR_DESCO_Operativo_Jabas
ON comercial.OperativoVenta AFTER INSERT,UPDATE AS
BEGIN
 IF ROWCOUNT_BIG()=0 RETURN;
 SET NOCOUNT ON;
 INSERT comercial.JabaSaldoOperativo(operativo_venta_id)
 SELECT I.operativo_venta_id FROM inserted I WHERE NOT EXISTS(SELECT 1 FROM comercial.JabaSaldoOperativo S WHERE S.operativo_venta_id=I.operativo_venta_id);
 IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.JabaSaldoOperativo S ON S.operativo_venta_id=I.operativo_venta_id
  WHERE I.estado_proceso IN('CERRADO','CANCELADO') AND S.pendientes<>0)
  THROW 51100,N'DESCO_OPERATIVO_PENDIENTES',1;
END;
GO
