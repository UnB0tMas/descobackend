/* DESCO / Inventario: color opcional del vehiculo. Ejemplo: SELECT color FROM logistica.Vehiculo; */
IF OBJECT_ID(N'logistica.Vehiculo',N'U') IS NOT NULL AND COL_LENGTH(N'logistica.Vehiculo',N'color') IS NULL
 ALTER TABLE logistica.Vehiculo ADD color NVARCHAR(50) NULL;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Color del vehiculo, opcional y de hasta 50 caracteres.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'Vehiculo',@level2type=N'COLUMN',@level2name=N'color';
GO
