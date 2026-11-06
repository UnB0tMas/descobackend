/* DESCO / Inventario / 2026-10-27
   Protege la regla tambien en operaciones SQL y APIs anteriores.
   Ejemplo: un UPDATE a DISPONIBLE sin placa debe rechazarse, sin alterar el bien.
*/
IF OBJECT_ID(N'logistica.TR_BienInventario_ValidarPlacaOperativa',N'TR') IS NOT NULL
    DROP TRIGGER logistica.TR_BienInventario_ValidarPlacaOperativa;
GO
IF OBJECT_ID(N'logistica.TR_BienInventario_ValidarPlacaOperativa', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_BienInventario_ValidarPlacaOperativa;
GO
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
IF OBJECT_ID(N'logistica.TR_Vehiculo_ValidarPlacaOperativa',N'TR') IS NOT NULL
    DROP TRIGGER logistica.TR_Vehiculo_ValidarPlacaOperativa;
GO
IF OBJECT_ID(N'logistica.TR_Vehiculo_ValidarPlacaOperativa', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_Vehiculo_ValidarPlacaOperativa;
GO
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
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Impide disponibilidad o asignacion de un vehiculo sin placa registrada.',
 @level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'BienInventario',
 @level2type=N'TRIGGER',@level2name=N'TR_BienInventario_ValidarPlacaOperativa';
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Impide retirar la placa o el registro de un vehiculo operativo.',
 @level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'Vehiculo',
 @level2type=N'TRIGGER',@level2name=N'TR_Vehiculo_ValidarPlacaOperativa';
GO
