/* DESCO: guardas transversales de movimientos y retiros. Ejemplo: las operaciones invalidas se revierten. */
IF OBJECT_ID(N'logistica.TR_DetMov_ProductoActivo',N'TR') IS NOT NULL DROP TRIGGER logistica.TR_DetMov_ProductoActivo;
GO
IF OBJECT_ID(N'logistica.TR_DetMov_ProductoActivo', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_DetMov_ProductoActivo;
GO
CREATE TRIGGER logistica.TR_DetMov_ProductoActivo ON logistica.DetalleMovimientoInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted D JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id JOIN logistica.AlmacenProductoStock S ON S.almacen_id=M.almacen_id AND S.producto_id=D.producto_id WHERE S.estado=0)
 THROW 51080,N'El producto esta inactivo en este almacen. Reactive su configuracion antes de registrar movimientos.',1;
END;
GO
IF OBJECT_ID(N'logistica.TR_AlmacenProducto_ValidarRetiro',N'TR') IS NOT NULL DROP TRIGGER logistica.TR_AlmacenProducto_ValidarRetiro;
GO
IF OBJECT_ID(N'logistica.TR_AlmacenProducto_ValidarRetiro', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_AlmacenProducto_ValidarRetiro;
GO
CREATE TRIGGER logistica.TR_AlmacenProducto_ValidarRetiro ON logistica.AlmacenProductoStock AFTER DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted D WHERE D.stock_actual<>0 OR D.stock_reservado<>0 OR logistica.FN_AlmacenProducto_TieneHistorial(D.almacen_id,D.producto_id)=1)
 THROW 51080,N'No puede retirar una asociacion con stock, reservas o historial operativo.',1;
END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Impide registrar movimientos para asociaciones inactivas, independientemente de su origen (Kardex, POS o transferencia).',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'DetalleMovimientoInventario',@level2type=N'TRIGGER',@level2name=N'TR_DetMov_ProductoActivo';
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Protege de retiros que borren la asociacion de saldos, reservas o historial operativo.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'AlmacenProductoStock',@level2type=N'TRIGGER',@level2name=N'TR_AlmacenProducto_ValidarRetiro';
GO
IF OBJECT_ID(N'logistica.TR_ProgramacionProducto_Activo',N'TR') IS NOT NULL DROP TRIGGER logistica.TR_ProgramacionProducto_Activo;
GO
IF OBJECT_ID(N'logistica.TR_ProgramacionProducto_Activo', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_ProgramacionProducto_Activo;
GO
CREATE TRIGGER logistica.TR_ProgramacionProducto_Activo ON logistica.ProgramacionProducto AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I JOIN logistica.AlmacenProductoStock S ON S.almacen_id=I.almacen_id AND S.producto_id=I.producto_id WHERE S.estado=0 AND I.estado_proceso IN('PENDIENTE','APROBADA','ENTREGADA'))
 THROW 51080,N'El producto esta inactivo en este almacen y no puede programarse.',1;
END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Impide programaciones pendientes sobre productos inactivos en el almacen.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'ProgramacionProducto',@level2type=N'TRIGGER',@level2name=N'TR_ProgramacionProducto_Activo';
GO
