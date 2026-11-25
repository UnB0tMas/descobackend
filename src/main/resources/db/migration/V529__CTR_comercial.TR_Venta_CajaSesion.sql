IF OBJECT_ID(N'[comercial].[TR_Venta_CajaSesion]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_Venta_CajaSesion];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_Venta_CajaSesion
' Descripción            : Controla las modificaciones de venta caja sesion mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_Venta_CajaSesion
ON comercial.Venta AFTER INSERT
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I WHERE comercial.FN_Pos_HorarioVigente(I.vendedor_usuario_id,I.uot_id)=0)
  THROW 51325,N'No tienes un horario vigente para vender.',1;
 IF EXISTS(SELECT 1 FROM inserted I WHERE
   seg.FN_Usuario_TienePermisoUOT(I.vendedor_usuario_id,I.uot_id,'POS_SIN_CAJA')<>1
   AND NOT EXISTS(SELECT 1 FROM comercial.CajaSesion S WITH(UPDLOCK,HOLDLOCK)
     JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
     JOIN comercial.CajaSesionOperador A ON A.caja_sesion_id=S.caja_sesion_id AND A.usuario_id=I.vendedor_usuario_id AND A.activo=1
     WHERE S.estado='ABIERTA' AND C.estado=1 AND C.uot_id=I.uot_id))
  THROW 51326,N'No tienes una caja abierta asignada.',1;
 UPDATE V SET caja_sesion_id=X.caja_sesion_id
 FROM comercial.Venta V JOIN inserted I ON I.venta_id=V.venta_id
 OUTER APPLY(SELECT TOP(1) S.caja_sesion_id FROM comercial.CajaSesion S WITH(UPDLOCK,HOLDLOCK)
   JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
   JOIN comercial.CajaSesionOperador A ON A.caja_sesion_id=S.caja_sesion_id AND A.usuario_id=I.vendedor_usuario_id AND A.activo=1
   WHERE S.estado='ABIERTA' AND C.estado=1 AND C.uot_id=I.uot_id ORDER BY S.caja_sesion_id DESC) X;
END;
GO
