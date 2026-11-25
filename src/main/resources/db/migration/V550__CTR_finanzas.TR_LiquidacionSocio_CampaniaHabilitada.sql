IF OBJECT_ID(N'[finanzas].[TR_LiquidacionSocio_CampaniaHabilitada]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_LiquidacionSocio_CampaniaHabilitada];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_LiquidacionSocio_CampaniaHabilitada
' Descripción            : Controla las modificaciones de liquidacion socio campania habilitada mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_LiquidacionSocio_CampaniaHabilitada
ON finanzas.LiquidacionSocio
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1
        FROM inserted L
        INNER JOIN comercial.ParticipacionCampaniaSocio P
            ON P.participacion_campania_socio_id=L.participacion_campania_socio_id
        INNER JOIN comercial.CampaniaVenta C
            ON C.campania_venta_id=P.campania_venta_id
        WHERE C.estado<>1
           OR C.estado_proceso NOT IN ('ACTIVA','VENCIDA','CERRADA')
           OR EXISTS (SELECT 1 FROM comercial.CierreCampaniaE5 X
                      WHERE X.campania_venta_id=C.campania_venta_id)
    )
        THROW 51701, N'La campaña no está habilitada para nuevas liquidaciones.', 1;
END;
GO
