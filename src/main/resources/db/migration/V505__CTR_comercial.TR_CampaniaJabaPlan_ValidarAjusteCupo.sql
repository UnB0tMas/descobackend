IF OBJECT_ID(N'[comercial].[TR_CampaniaJabaPlan_ValidarAjusteCupo]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_CampaniaJabaPlan_ValidarAjusteCupo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_CampaniaJabaPlan_ValidarAjusteCupo
' Descripción            : Valida las reglas de campania jaba plan validar ajuste cupo al modificar registros.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_CampaniaJabaPlan_ValidarAjusteCupo
ON comercial.CampaniaJabaPlan AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted I
  JOIN comercial.ParticipacionCampaniaSocio PX ON PX.participacion_campania_socio_id=I.participacion_campania_socio_id
  JOIN comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK) ON K.campania_venta_id=PX.campania_venta_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+
    CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51439,N'Las jabas solicitadas exceden el cupo de la campaña.',1;
END;
GO
