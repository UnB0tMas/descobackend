IF OBJECT_ID(N'[comercial].[TR_CampaniaJabaPlan_ValidarCupo]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_CampaniaJabaPlan_ValidarCupo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_CampaniaJabaPlan_ValidarCupo
' Descripción            : Valida las reglas de campania jaba plan validar cupo al modificar registros.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_CampaniaJabaPlan_ValidarCupo
ON comercial.CampaniaControlE4 AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM inserted K
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51420,N'El nuevo cupo es inferior a las jabas reservadas o asignadas.',1;
END;
GO
