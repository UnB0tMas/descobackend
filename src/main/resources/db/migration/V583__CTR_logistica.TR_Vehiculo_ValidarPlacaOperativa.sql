IF OBJECT_ID(N'[logistica].[TR_Vehiculo_ValidarPlacaOperativa]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_Vehiculo_ValidarPlacaOperativa];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_Vehiculo_ValidarPlacaOperativa
' Descripción            : Valida las reglas de vehiculo validar placa operativa al modificar registros.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_Vehiculo_ValidarPlacaOperativa ON logistica.Vehiculo AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM logistica.BienInventario B
    WHERE B.estado=1 AND B.estado_bien IN('DISPONIBLE','ASIGNADO')
      AND (B.bien_inventario_id IN(SELECT vehiculo_id FROM inserted) OR B.bien_inventario_id IN(SELECT vehiculo_id FROM deleted))
      AND NOT EXISTS(SELECT 1 FROM logistica.Vehiculo V WHERE V.vehiculo_id=B.bien_inventario_id AND V.estado=1 AND NULLIF(LTRIM(RTRIM(V.placa)),'') IS NOT NULL))
    THROW 51080,N'Pase el vehiculo a pendiente o no operativo antes de retirar su placa.',1;
END;
GO
