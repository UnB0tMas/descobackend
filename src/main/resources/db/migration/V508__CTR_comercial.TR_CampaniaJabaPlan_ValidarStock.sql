IF OBJECT_ID(N'[comercial].[TR_CampaniaJabaPlan_ValidarStock]') IS NOT NULL
    DROP TRIGGER [comercial].[TR_CampaniaJabaPlan_ValidarStock];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.TR_CampaniaJabaPlan_ValidarStock
' Descripción            : Valida las reglas de campania jaba plan validar stock al modificar registros.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.TR_CampaniaJabaPlan_ValidarStock
ON comercial.JabaStockUotE4 AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted S
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id
    WHERE C.uot_id=S.uot_id AND C.origen_jabas='UOT' AND J.activo=1 AND J.estado='ENTREGADA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) cantidad
    FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
    LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
    WHERE C.uot_id=S.uot_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>S.existencia_certificada)
  THROW 51424,N'El stock certificado no cubre las jabas aún retenidas.',1;
END;
GO
