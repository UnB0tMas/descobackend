IF OBJECT_ID(N'[comercial].[TR_CampaniaJabaPlan_CompatibilidadOperativo]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_CampaniaJabaPlan_CompatibilidadOperativo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_CampaniaJabaPlan_CompatibilidadOperativo
' Descripción            : Controla las modificaciones de campania jaba plan compatibilidad operativo mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_CampaniaJabaPlan_CompatibilidadOperativo
ON comercial.JabaAsignacion AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK) ON K.campania_venta_id=O.campania_venta_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS2 ON OS2.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O2 ON O2.operativo_venta_id=OS2.operativo_venta_id
    WHERE O2.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51422,N'Las jabas reservadas en campaña más las asignadas al operativo exceden el cupo.',1;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
  JOIN comercial.JabaStockUotE4 S WITH(UPDLOCK,HOLDLOCK) ON S.uot_id=C.uot_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    JOIN comercial.CampaniaVenta K ON K.campania_venta_id=P.campania_venta_id
    WHERE K.uot_id=S.uot_id AND K.origen_jabas='UOT' AND J.activo=1 AND J.estado='ENTREGADA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) cantidad
    FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio X ON X.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta OV ON OV.operativo_venta_id=X.operativo_venta_id
    JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=OV.campania_venta_id
    LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
    WHERE CV.uot_id=S.uot_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>S.existencia_certificada)
  THROW 51423,N'Las jabas entregadas y las retenidas superan las existencias certificadas.',1;
END;
GO
