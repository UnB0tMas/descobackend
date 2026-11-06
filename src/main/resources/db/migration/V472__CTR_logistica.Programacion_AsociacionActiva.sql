-- La validación también cubre inserciones desde otros procesos.
IF OBJECT_ID(N'logistica.TR_ProgramacionProducto_Activo',N'TR') IS NOT NULL DROP TRIGGER logistica.TR_ProgramacionProducto_Activo;
GO
IF OBJECT_ID(N'logistica.TR_ProgramacionProducto_Activo', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_ProgramacionProducto_Activo;
GO
CREATE TRIGGER logistica.TR_ProgramacionProducto_Activo ON logistica.ProgramacionProducto AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I LEFT JOIN logistica.AlmacenProductoStock S
  ON S.almacen_id=I.almacen_id AND S.producto_id=I.producto_id
  WHERE (S.producto_id IS NULL OR S.estado=0) AND I.estado_proceso IN('PENDIENTE','APROBADA','ENTREGADA'))
  THROW 51121,N'El producto debe estar incorporado y activo en el almacén para programarlo.',1;
END;
GO
