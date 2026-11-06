/* DESCO / Inventario / 2026-10-27
   Placa y kilometraje opcionales al adquirir un vehiculo.
   Sin placa el bien queda PENDIENTE_PLACA, sin disponibilidad operativa.
   Ejemplo: SELECT estado_bien FROM logistica.BienInventario WHERE bien_inventario_id=@Id;
*/
IF OBJECT_ID(N'logistica.Vehiculo',N'U') IS NULL
    THROW 51080,N'No existe logistica.Vehiculo.',1;
GO
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'logistica.Vehiculo') AND name=N'UQ_Vehiculo_Placa')
    ALTER TABLE logistica.Vehiculo DROP CONSTRAINT UQ_Vehiculo_Placa;
GO
ALTER TABLE logistica.Vehiculo ALTER COLUMN placa VARCHAR(12) COLLATE Modern_Spanish_CI_AS NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'logistica.Vehiculo') AND name=N'UX_Vehiculo_PlacaRegistrada')
    CREATE UNIQUE INDEX UX_Vehiculo_PlacaRegistrada ON logistica.Vehiculo(placa) WHERE placa IS NOT NULL;
GO
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'logistica.BienInventario') AND name=N'CK_BienInventario_EstadoProceso')
    ALTER TABLE logistica.BienInventario DROP CONSTRAINT CK_BienInventario_EstadoProceso;
GO
ALTER TABLE logistica.BienInventario WITH CHECK ADD CONSTRAINT CK_BienInventario_EstadoProceso
    CHECK(estado_bien IN('DISPONIBLE','ASIGNADO','MANTENIMIENTO','AVERIADO','INACTIVO','BAJA','NO_DISPONIBLE','PENDIENTE_PLACA'));
GO
DECLARE @Corregidos TABLE(id BIGINT);
UPDATE B SET estado_bien='PENDIENTE_PLACA'
OUTPUT inserted.bien_inventario_id INTO @Corregidos
FROM logistica.BienInventario B JOIN logistica.TipoBien T ON T.tipo_bien_id=B.tipo_bien_id
WHERE UPPER(T.nombre) COLLATE Modern_Spanish_CI_AI=N'VEHICULO'
  AND B.estado=1 AND B.estado_bien IN('DISPONIBLE','ASIGNADO')
  AND NOT EXISTS(SELECT 1 FROM logistica.Vehiculo V WHERE V.vehiculo_id=B.bien_inventario_id AND V.estado=1 AND NULLIF(LTRIM(RTRIM(V.placa)),'') IS NOT NULL);
UPDATE H SET fecha_hasta=SYSUTCDATETIME() FROM logistica.BienEstadoHistorial H JOIN @Corregidos C ON C.id=H.bien_inventario_id WHERE H.fecha_hasta IS NULL;
INSERT logistica.BienEstadoHistorial(bien_inventario_id,estado_bien,fecha_desde,motivo,estado)
SELECT id,'PENDIENTE_PLACA',SYSUTCDATETIME(),N'Pendiente de registro de placa; no disponible para asignacion.',1 FROM @Corregidos;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
 @value=N'Las placas nulas se permiten durante el tramite; el bien vehicular sin placa no puede estar disponible ni asignado.',
 @level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'Vehiculo',
 @level2type=N'INDEX',@level2name=N'UX_Vehiculo_PlacaRegistrada';
GO
