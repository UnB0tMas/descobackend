-- El procedimiento de entrega técnica utiliza USO_TECNICO: la tabla debe admitirlo.
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'logistica.MovimientoInventario') AND name=N'CK_MovInv_Tipo')
 ALTER TABLE logistica.MovimientoInventario DROP CONSTRAINT CK_MovInv_Tipo;
GO
ALTER TABLE logistica.MovimientoInventario WITH CHECK ADD CONSTRAINT CK_MovInv_Tipo
 CHECK(tipo_movimiento IN('COMPRA','DONACION','DEVOLUCION','VENTA','CONSUMO','TRANSFERENCIA','AJUSTE','MERMA','OTRO','USO_TECNICO'));
GO
