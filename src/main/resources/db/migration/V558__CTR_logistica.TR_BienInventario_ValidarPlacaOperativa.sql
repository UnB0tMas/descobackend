IF OBJECT_ID(N'[logistica].[TR_BienInventario_ValidarPlacaOperativa]') IS NOT NULL
    DROP TRIGGER [logistica].[TR_BienInventario_ValidarPlacaOperativa];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : logistica.TR_BienInventario_ValidarPlacaOperativa
' Descripción            : Valida las reglas de bien inventario validar placa operativa al modificar registros.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE TRIGGER logistica.TR_BienInventario_ValidarPlacaOperativa ON logistica.BienInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted B JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
    WHERE B.estado=1 AND B.estado_bien IN('DISPONIBLE','ASIGNADO')
      AND UPPER(T.nombre) COLLATE Modern_Spanish_CI_AI=N'VEHICULO'
      AND NOT EXISTS(SELECT 1 FROM logistica.Vehiculo V WHERE V.vehiculo_id=B.bien_inventario_id AND V.estado=1 AND NULLIF(LTRIM(RTRIM(V.placa)),'') IS NOT NULL))
    THROW 51080,N'Registre la placa antes de habilitar o asignar el vehiculo.',1;
 IF EXISTS(SELECT 1 FROM inserted B JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
    WHERE B.estado_bien='PENDIENTE_PLACA' AND UPPER(T.nombre) COLLATE Modern_Spanish_CI_AI<>N'VEHICULO')
    THROW 51080,N'El estado pendiente de placa solo corresponde a vehiculos.',1;
END;
GO
