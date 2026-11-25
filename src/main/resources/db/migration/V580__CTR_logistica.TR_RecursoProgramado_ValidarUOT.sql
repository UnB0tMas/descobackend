IF OBJECT_ID(N'[logistica].[TR_RecursoProgramado_ValidarUOT]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_RecursoProgramado_ValidarUOT];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_RecursoProgramado_ValidarUOT
' Descripción            : Valida la UOT del recurso programado.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_RecursoProgramado_ValidarUOT
ON logistica.RecursoProgramado
AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1
  FROM inserted I
  LEFT JOIN comercial.CampaniaVenta C ON C.campania_venta_id=I.campania_venta_id
  LEFT JOIN comercial.OperativoVenta O ON O.operativo_venta_id=I.operativo_venta_id
  LEFT JOIN comercial.CampaniaVenta CO ON CO.campania_venta_id=O.campania_venta_id
  LEFT JOIN campo.SalidaCampo SC ON SC.salida_campo_id=I.salida_campo_id
  LEFT JOIN logistica.Suministro S ON S.suministro_id=I.suministro_id
  LEFT JOIN logistica.BienInventario B ON B.bien_inventario_id=I.bien_inventario_id
  WHERE COALESCE(C.uot_id,CO.uot_id,SC.uot_id) IS NULL
     OR (I.suministro_id IS NOT NULL AND S.uot_id<>COALESCE(C.uot_id,CO.uot_id,SC.uot_id))
     OR (I.bien_inventario_id IS NOT NULL AND B.uot_id<>COALESCE(C.uot_id,CO.uot_id,SC.uot_id))
 ) THROW 51091,N'El recurso seleccionado no pertenece a la UOT de la actividad.',1;
END;
GO
