IF OBJECT_ID(N'[logistica].[TR_BienInventario_ProveedorSoloEmpresa]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_BienInventario_ProveedorSoloEmpresa];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_BienInventario_ProveedorSoloEmpresa
' Descripción            : Controla las modificaciones de bien inventario proveedor solo empresa mediante reglas del trigger.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE   TRIGGER logistica.TR_BienInventario_ProveedorSoloEmpresa
ON logistica.BienInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF NOT(UPDATE(proveedor_persona_id) OR UPDATE(proveedor_empresa_id)) RETURN;
 IF EXISTS(SELECT 1 FROM inserted I WHERE I.proveedor_persona_id IS NOT NULL OR
  (I.proveedor_empresa_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Empresa E
    WHERE E.empresa_id=I.proveedor_empresa_id AND E.estado=1
      AND NOT EXISTS(SELECT 1 FROM org.Asociacion A WHERE A.asociacion_id=E.empresa_id))))
 THROW 51156,N'El proveedor debe ser una empresa activa registrada en Administración.',1;
END;
GO
