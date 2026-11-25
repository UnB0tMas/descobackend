IF OBJECT_ID(N'[comercial].[TR_PagoVenta_CajaActiva]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_PagoVenta_CajaActiva];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_PagoVenta_CajaActiva
' Descripción            : Controla las modificaciones de pago venta caja activa mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_PagoVenta_CajaActiva
ON comercial.PagoVenta AFTER INSERT
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.Venta V ON V.venta_id=I.venta_id
   WHERE comercial.FN_Pos_HorarioVigente(I.usuario_id,V.uot_id)=0)
  THROW 51327,N'No tienes un horario vigente para registrar pagos.',1;
 IF EXISTS(SELECT 1 FROM inserted I JOIN comercial.Venta V ON V.venta_id=I.venta_id
  LEFT JOIN comercial.CajaSesion S WITH(UPDLOCK,HOLDLOCK) ON S.caja_sesion_id=V.caja_sesion_id
  LEFT JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
  WHERE seg.FN_Usuario_TienePermisoUOT(I.usuario_id,V.uot_id,'POS_SIN_CAJA')<>1
    AND (S.caja_sesion_id IS NULL OR S.estado<>'ABIERTA' OR C.estado<>1 OR C.uot_id<>V.uot_id
     OR NOT EXISTS(SELECT 1 FROM comercial.CajaSesionOperador A WHERE A.caja_sesion_id=S.caja_sesion_id AND A.usuario_id=I.usuario_id AND A.activo=1)))
  THROW 51328,N'No estás autorizado para registrar pagos en esta caja.',1;
END;
GO
