IF OBJECT_ID(N'[finanzas].[TR_E5_Liquidacion_Cierre]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Liquidacion_Cierre];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Liquidacion_Cierre
' Descripción            : Controla las condiciones de cierre de e5 liquidacion cierre.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE TRIGGER finanzas.TR_E5_Liquidacion_Cierre
ON finanzas.LiquidacionSocio AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM (SELECT participacion_campania_socio_id FROM inserted UNION SELECT participacion_campania_socio_id FROM deleted) X
  JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=X.participacion_campania_socio_id
  JOIN comercial.CierreCampaniaE5 C ON C.campania_venta_id=P.campania_venta_id)
 THROW 51503,N'La campaña cerrada no permite modificar liquidaciones.',1;
END;
GO
