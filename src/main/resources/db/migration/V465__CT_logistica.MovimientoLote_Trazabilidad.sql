-- Distribución de cada movimiento entre lotes. Las reservas se mantienen por producto
-- y el lote se asigna al realizar la salida, bajo el bloqueo del saldo del producto.
IF OBJECT_ID(N'logistica.MovimientoInventarioLote',N'U') IS NULL
 CREATE TABLE logistica.MovimientoInventarioLote(
  asignacion_lote_id BIGINT IDENTITY PRIMARY KEY,
  detalle_movimiento_id BIGINT NOT NULL REFERENCES logistica.DetalleMovimientoInventario(detalle_movimiento_inventario_id),
  detalle_origen_id BIGINT NULL REFERENCES logistica.DetalleMovimientoInventario(detalle_movimiento_inventario_id),
  lote VARCHAR(80) NULL,fecha_vencimiento DATE NULL,
  cantidad DECIMAL(19,3) NOT NULL CHECK(cantidad>0));
GO
CREATE INDEX IX_MovimientoLote_Detalle ON logistica.MovimientoInventarioLote(detalle_movimiento_id) INCLUDE(lote,fecha_vencimiento,cantidad,detalle_origen_id);
CREATE INDEX IX_MovimientoLote_Origen ON logistica.MovimientoInventarioLote(detalle_origen_id) INCLUDE(lote,fecha_vencimiento,cantidad);
GO
IF OBJECT_ID(N'logistica.PA_DetalleMovimiento_Ins_Lotes', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_DetalleMovimiento_Ins_Lotes;
GO
CREATE PROCEDURE logistica.PA_DetalleMovimiento_Ins_Lotes @Detalle BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Almacen BIGINT,@Producto BIGINT,@Movimiento BIGINT,@Relacionado BIGINT,
  @Naturaleza CHAR(1),@Tipo VARCHAR(25),@Cantidad DECIMAL(19,3),@Lote VARCHAR(80),@Fecha DATE,
  @Requiere BIT,@Vence BIT,@Bloqueo DECIMAL(19,3);
 SELECT @Movimiento=M.movimiento_inventario_id,@Almacen=M.almacen_id,@Producto=D.producto_id,
  @Naturaleza=M.naturaleza,@Tipo=M.tipo_movimiento,@Relacionado=M.movimiento_relacionado_id,
  @Cantidad=D.cantidad,@Lote=NULLIF(LTRIM(RTRIM(D.lote)),''),@Fecha=D.fecha_vencimiento,
  @Requiere=P.requiere_lote,@Vence=P.controla_vencimiento
 FROM logistica.DetalleMovimientoInventario D JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id
 JOIN logistica.Producto P ON P.producto_id=D.producto_id WHERE D.detalle_movimiento_inventario_id=@Detalle;
 IF @Requiere=0 AND @Vence=0 AND @Lote IS NULL AND @Fecha IS NULL
  AND NOT EXISTS(SELECT 1 FROM logistica.MovimientoInventarioLote A JOIN logistica.DetalleMovimientoInventario D ON D.detalle_movimiento_inventario_id=A.detalle_movimiento_id WHERE D.producto_id=@Producto) RETURN;
 SELECT @Bloqueo=stock_actual FROM logistica.AlmacenProductoStock WITH(UPDLOCK,HOLDLOCK)
 WHERE almacen_id=@Almacen AND producto_id=@Producto;
 IF EXISTS(SELECT 1 FROM logistica.MovimientoInventarioLote WHERE detalle_movimiento_id=@Detalle) RETURN;
 DECLARE @Partes TABLE(id INT IDENTITY PRIMARY KEY,origen BIGINT NULL,lote VARCHAR(80) NULL,fecha DATE NULL,cantidad DECIMAL(19,3));
 IF @Naturaleza='E' AND @Relacionado IS NOT NULL AND @Tipo IN('TRANSFERENCIA','DEVOLUCION')
 BEGIN
  -- Conserva los lotes de la salida original; impide devolver o recibir dos veces.
  INSERT @Partes(origen,lote,fecha,cantidad)
  SELECT A.detalle_movimiento_id,A.lote,A.fecha_vencimiento,SUM(A.cantidad)-COALESCE(R.devuelto,0)
  FROM logistica.MovimientoInventarioLote A JOIN logistica.DetalleMovimientoInventario D ON D.detalle_movimiento_inventario_id=A.detalle_movimiento_id
  JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id AND M.naturaleza='S' AND M.estado=1
  OUTER APPLY(SELECT SUM(X.cantidad) devuelto FROM logistica.MovimientoInventarioLote X
   WHERE X.detalle_origen_id=A.detalle_movimiento_id AND ISNULL(X.lote,'')=ISNULL(A.lote,'')
    AND ISNULL(X.fecha_vencimiento,'99991231')=ISNULL(A.fecha_vencimiento,'99991231')) R
  WHERE M.movimiento_inventario_id=@Relacionado AND D.producto_id=@Producto
  GROUP BY A.detalle_movimiento_id,A.lote,A.fecha_vencimiento,R.devuelto
  HAVING SUM(A.cantidad)>COALESCE(R.devuelto,0);
 END
 ELSE IF @Naturaleza='E'
 BEGIN
  IF @Requiere=1 AND @Lote IS NULL THROW 51120,N'El producto requiere indicar un lote en la entrada.',1;
  IF @Vence=1 AND @Fecha IS NULL THROW 51120,N'El producto requiere fecha de vencimiento en la entrada.',1;
  IF @Fecha<CONVERT(DATE,SYSDATETIME()) THROW 51120,N'No se admite una entrada con fecha de vencimiento anterior a hoy.',1;
  IF @Lote IS NOT NULL AND EXISTS(
   SELECT 1 FROM logistica.MovimientoInventarioLote A JOIN logistica.DetalleMovimientoInventario D ON D.detalle_movimiento_inventario_id=A.detalle_movimiento_id
   JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id
   WHERE M.almacen_id=@Almacen AND D.producto_id=@Producto AND A.lote=@Lote
    AND ISNULL(A.fecha_vencimiento,'99991231')<>ISNULL(@Fecha,'99991231'))
   THROW 51120,N'El lote ya está registrado con otra fecha de vencimiento.',1;
  INSERT logistica.MovimientoInventarioLote(detalle_movimiento_id,lote,fecha_vencimiento,cantidad) VALUES(@Detalle,@Lote,@Fecha,@Cantidad);
  RETURN;
 END
 ELSE
 BEGIN
  INSERT @Partes(lote,fecha,cantidad)
  SELECT A.lote,A.fecha_vencimiento,SUM(CASE WHEN M.naturaleza='E' THEN A.cantidad ELSE -A.cantidad END)
  FROM logistica.MovimientoInventarioLote A JOIN logistica.DetalleMovimientoInventario D ON D.detalle_movimiento_inventario_id=A.detalle_movimiento_id
  JOIN logistica.MovimientoInventario M ON M.movimiento_inventario_id=D.movimiento_inventario_id
  WHERE M.almacen_id=@Almacen AND D.producto_id=@Producto AND M.estado=1
   AND (@Lote IS NULL OR A.lote=@Lote) AND (@Fecha IS NULL OR A.fecha_vencimiento=@Fecha)
   AND (@Tipo='MERMA' OR A.fecha_vencimiento IS NULL OR A.fecha_vencimiento>=CONVERT(DATE,SYSDATETIME()))
  GROUP BY A.lote,A.fecha_vencimiento
  HAVING SUM(CASE WHEN M.naturaleza='E' THEN A.cantidad ELSE -A.cantidad END)>0;
 END;
 IF COALESCE((SELECT SUM(cantidad) FROM @Partes),0)<@Cantidad
  THROW 51120,N'No hay stock trazable suficiente en los lotes seleccionados o están vencidos. Revise el lote y su vencimiento.',1;
 DECLARE @Id INT,@Origen BIGINT,@Tomar DECIMAL(19,3),@Pendiente DECIMAL(19,3)=@Cantidad;
 WHILE @Pendiente>0
 BEGIN
  SELECT TOP(1) @Id=id,@Origen=origen,@Lote=lote,@Fecha=fecha,@Tomar=CASE WHEN cantidad>@Pendiente THEN @Pendiente ELSE cantidad END
  FROM @Partes WHERE cantidad>0 ORDER BY ISNULL(fecha,'99991231'),id;
  INSERT logistica.MovimientoInventarioLote(detalle_movimiento_id,detalle_origen_id,lote,fecha_vencimiento,cantidad)
   VALUES(@Detalle,@Origen,@Lote,@Fecha,@Tomar);
  UPDATE @Partes SET cantidad=cantidad-@Tomar WHERE id=@Id;
  SET @Pendiente=@Pendiente-@Tomar;
 END;
END;
GO
IF OBJECT_ID(N'logistica.TR_DetalleMovimiento_Lotes', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_DetalleMovimiento_Lotes;
GO
CREATE TRIGGER logistica.TR_DetalleMovimiento_Lotes ON logistica.DetalleMovimientoInventario AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM deleted) THROW 51120,N'Los datos del movimiento son históricos. Registre una corrección trazable.',1;
 DECLARE @Detalle BIGINT;
 DECLARE detalles CURSOR LOCAL FAST_FORWARD FOR SELECT detalle_movimiento_inventario_id FROM inserted ORDER BY producto_id,detalle_movimiento_inventario_id;
 OPEN detalles;FETCH NEXT FROM detalles INTO @Detalle;
 WHILE @@FETCH_STATUS=0
 BEGIN EXEC logistica.PA_DetalleMovimiento_Ins_Lotes @Detalle;FETCH NEXT FROM detalles INTO @Detalle;END;
 CLOSE detalles;DEALLOCATE detalles;
END;
GO
IF OBJECT_ID(N'logistica.TR_MovimientoLote_Inmutable', N'TR') IS NOT NULL DROP TRIGGER logistica.TR_MovimientoLote_Inmutable;
GO
CREATE TRIGGER logistica.TR_MovimientoLote_Inmutable ON logistica.MovimientoInventarioLote AFTER UPDATE,DELETE AS
BEGIN THROW 51120,N'Las asignaciones de lotes son históricas y no se pueden modificar.',1;END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Distribución inmutable por lotes, asignada al despachar con vencimiento más cercano. No inventa lotes para saldos históricos sin trazabilidad.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'TABLE',@level1name=N'MovimientoInventarioLote';
GO
