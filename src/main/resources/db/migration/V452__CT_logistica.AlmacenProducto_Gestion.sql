/* DESCO: estado y auditoria de la asociacion producto-almacen. No modifica saldos existentes.
   Ejemplo: SELECT estado FROM logistica.AlmacenProductoStock; */
IF COL_LENGTH(N'logistica.AlmacenProductoStock',N'estado') IS NULL
 ALTER TABLE logistica.AlmacenProductoStock ADD estado BIT NOT NULL CONSTRAINT DF_AlmacenProductoStock_Estado DEFAULT(1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=N'CK_AlmacenProductoStock_InactivoSinSaldo')
 ALTER TABLE logistica.AlmacenProductoStock ADD CONSTRAINT CK_AlmacenProductoStock_InactivoSinSaldo CHECK(estado=1 OR (stock_actual=0 AND stock_reservado=0));
GO
IF OBJECT_ID(N'logistica.AlmacenProductoEvento',N'U') IS NULL
 CREATE TABLE logistica.AlmacenProductoEvento(
  almacen_producto_evento_id BIGINT IDENTITY PRIMARY KEY, almacen_id BIGINT NOT NULL,producto_id BIGINT NOT NULL,
  operacion VARCHAR(15) NOT NULL, stock_minimo_anterior DECIMAL(19,3) NULL,stock_minimo_nuevo DECIMAL(19,3) NULL,
  estado_anterior BIT NULL,estado_nuevo BIT NULL,motivo NVARCHAR(500) NOT NULL,usuario_id BIGINT NOT NULL,
  fecha_hora DATETIME2(3) NOT NULL CONSTRAINT DF_AlmacenProductoEvento_Fecha DEFAULT SYSUTCDATETIME(),
  clave_idempotencia UNIQUEIDENTIFIER NOT NULL CONSTRAINT UQ_AlmacenProductoEvento_Clave UNIQUE,
  solicitud_sha256 VARBINARY(32) NOT NULL,
  CONSTRAINT FK_AlmacenProductoEvento_Almacen FOREIGN KEY(almacen_id) REFERENCES logistica.Almacen(almacen_id),
  CONSTRAINT FK_AlmacenProductoEvento_Producto FOREIGN KEY(producto_id) REFERENCES logistica.Producto(producto_id),
  CONSTRAINT FK_AlmacenProductoEvento_Usuario FOREIGN KEY(usuario_id) REFERENCES seg.Usuario(usuario_id)
 );
GO
IF OBJECT_ID(N'logistica.FN_AlmacenProducto_TieneHistorial',N'FN') IS NOT NULL DROP FUNCTION logistica.FN_AlmacenProducto_TieneHistorial;
GO
IF OBJECT_ID(N'logistica.FN_AlmacenProducto_TieneHistorial', N'FN') IS NOT NULL DROP FUNCTION logistica.FN_AlmacenProducto_TieneHistorial;
GO
CREATE FUNCTION logistica.FN_AlmacenProducto_TieneHistorial(@Almacen BIGINT,@Producto BIGINT) RETURNS BIT
AS BEGIN
 IF EXISTS(SELECT 1 FROM logistica.DetalleMovimientoInventario D JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id WHERE M.almacen_id=@Almacen AND D.producto_id=@Producto) RETURN 1;
 IF EXISTS(SELECT 1 FROM logistica.ProgramacionProducto WHERE almacen_id=@Almacen AND producto_id=@Producto) RETURN 1;
 IF EXISTS(SELECT 1 FROM comercial.DetalleVenta D JOIN comercial.Venta V ON V.venta_id=D.venta_id WHERE V.almacen_id=@Almacen AND D.producto_id=@Producto) RETURN 1;
 RETURN 0;
END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Estado local del producto en un almacen; inactivo solo con saldo y reservas cero.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'AlmacenProductoStock',@level2type=N'COLUMN',@level2name=N'estado';
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Historial administrativo de edicion, desactivacion, reactivacion y retiro; conserva motivo y actor e idempotencia.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'AlmacenProductoEvento';
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Detecta uso operativo de una asociacion, incluso cerrado o anulado, para impedir su retiro. Ejemplo: SELECT logistica.FN_AlmacenProducto_TieneHistorial(1,1);',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'FUNCTION',@level1name=N'FN_AlmacenProducto_TieneHistorial';
GO
