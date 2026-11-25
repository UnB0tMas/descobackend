IF OBJECT_ID(N'[finanzas].[TR_E5_RepartoLinea_NoCambiarLiquidado]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_RepartoLinea_NoCambiarLiquidado];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_RepartoLinea_NoCambiarLiquidado
' Descripción            : Controla las modificaciones de e5 reparto linea no cambiar liquidado mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_E5_RepartoLinea_NoCambiarLiquidado
ON finanzas.GastoRepartoLineaE5 AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM (SELECT reparto_id FROM inserted UNION SELECT reparto_id FROM deleted) X
  JOIN finanzas.GastoRepartoVersionE5 R ON R.reparto_id=X.reparto_id
  JOIN finanzas.GastoCampania G ON G.gasto_campania_id=R.gasto_campania_id
  JOIN comercial.ParticipacionCampaniaSocio PC ON PC.campania_venta_id=G.campania_venta_id
  JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=PC.participacion_campania_socio_id
  WHERE L.estado=1 AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
 ) THROW 51706,N'Las cuotas distribuidas no pueden cambiar después de aprobar una liquidación.',1;
END;
GO
