IF OBJECT_ID(N'[logistica].[TR_ProgramacionProducto_Activo]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_ProgramacionProducto_Activo];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_ProgramacionProducto_Activo
' Descripción            : Controla las modificaciones de programacion producto activo mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_ProgramacionProducto_Activo ON logistica.ProgramacionProducto AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I LEFT JOIN logistica.AlmacenProductoStock S
  ON S.almacen_id=I.almacen_id AND S.producto_id=I.producto_id
  WHERE (S.producto_id IS NULL OR S.estado=0) AND I.estado_proceso IN('PENDIENTE','APROBADA','ENTREGADA'))
  THROW 51121,N'El producto debe estar incorporado y activo en el almacén para programarlo.',1;
END;
GO
