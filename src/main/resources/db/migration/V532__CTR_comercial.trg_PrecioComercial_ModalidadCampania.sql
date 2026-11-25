IF OBJECT_ID(N'[comercial].[trg_PrecioComercial_ModalidadCampania]') IS NOT NULL
    DROP TRIGGER [comercial].[trg_PrecioComercial_ModalidadCampania];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : comercial.trg_PrecioComercial_ModalidadCampania
' Descripción            : Controla las modificaciones de precio comercial modalidad campania mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   TRIGGER comercial.trg_PrecioComercial_ModalidadCampania
ON comercial.PrecioComercial AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM inserted I
  JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=I.campania_venta_id
  LEFT JOIN comercial.CondicionComercial C ON C.condicion_comercial_id=I.condicion_comercial_id
  WHERE CV.modalidad_venta_id IS NOT NULL
    AND (C.modalidad_venta_id IS NULL OR C.modalidad_venta_id<>CV.modalidad_venta_id)
 ) THROW 51607,N'El precio no corresponde a la modalidad de venta de la campaña.',1;
 IF EXISTS (
  SELECT 1 FROM inserted I
  LEFT JOIN deleted D ON D.precio_comercial_id=I.precio_comercial_id
  JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=I.campania_venta_id
  JOIN comercial.PrecioComercial P ON P.campania_venta_id=I.campania_venta_id
    AND P.variedad_palta_id=I.variedad_palta_id AND P.precio_comercial_id<>I.precio_comercial_id
    AND ((P.operativo_venta_id=I.operativo_venta_id) OR (P.operativo_venta_id IS NULL AND I.operativo_venta_id IS NULL))
    AND P.estado=1 AND P.fecha_vigencia_hasta IS NULL
  WHERE D.precio_comercial_id IS NULL AND CV.modalidad_venta_id IS NOT NULL AND I.estado=1 AND I.fecha_vigencia_hasta IS NULL
 ) THROW 51608,N'Ya existe un precio para esta variedad de la campaña.',1;
END;
GO
