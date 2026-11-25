IF OBJECT_ID(N'[finanzas].[TR_E5_Liquidacion_BloqueoAprobadas]') IS NOT NULL
    DROP TRIGGER [finanzas].[TR_E5_Liquidacion_BloqueoAprobadas];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : finanzas.TR_E5_Liquidacion_BloqueoAprobadas
' Descripción            : Protege la integridad de e5 liquidacion bloqueo aprobadas ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / finanzas
*******************************************************************************************************/
CREATE   TRIGGER finanzas.TR_E5_Liquidacion_BloqueoAprobadas
ON finanzas.LiquidacionSocio AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- La liquidación aún calculada puede observarse; una aprobada jamás se anula
    -- para recalcular, ni puede cambiar sus montos. Sus pagos se registran aparte.
    IF EXISTS (
        SELECT 1 FROM inserted I
        JOIN deleted D ON D.liquidacion_socio_id=I.liquidacion_socio_id
        WHERE D.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
          AND (I.estado_proceso NOT IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
            OR I.importe_bruto<>D.importe_bruto OR I.importe_neto<>D.importe_neto
            OR I.total_gastos<>D.total_gastos OR I.total_ajustes<>D.total_ajustes
            OR I.total_bonificaciones<>D.total_bonificaciones OR I.estado<>D.estado)
    ) THROW 51702,N'La liquidación aprobada es inmutable, incluso para administradores.',1;
    IF EXISTS (
        SELECT 1 FROM inserted I
        JOIN finanzas.LiquidacionSocio L ON L.participacion_campania_socio_id=I.participacion_campania_socio_id
          AND L.liquidacion_socio_id<>I.liquidacion_socio_id AND L.estado=1
          AND L.estado_proceso IN ('APROBADA','PAGADA_PARCIAL','PAGADA')
        WHERE NOT EXISTS (SELECT 1 FROM deleted D WHERE D.liquidacion_socio_id=I.liquidacion_socio_id)
    ) THROW 51703,N'El socio ya tiene una liquidación aprobada; no se permite otra versión.',1;
    IF EXISTS (
        SELECT 1 FROM inserted I
        JOIN comercial.ParticipacionCampaniaSocio PC ON PC.participacion_campania_socio_id=I.participacion_campania_socio_id
        JOIN finanzas.GastoCampania G ON G.campania_venta_id=PC.campania_venta_id AND G.estado=1
        WHERE I.estado=1 AND I.estado_proceso='CALCULADA' AND G.estado_proceso<>'APROBADO'
    ) THROW 51704,N'Apruebe primero todos los gastos y sus repartos antes de liquidar.',1;
END;
GO
