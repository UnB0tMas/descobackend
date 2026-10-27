/* Integridad logística por UOT; las existencias previas nunca se redistribuyen automáticamente. */
IF EXISTS (
    SELECT 1 FROM logistica.MovimientoInventario M
    JOIN logistica.Almacen A ON A.almacen_id=M.almacen_id
    WHERE M.uot_id<>A.uot_propietaria_id
)
    THROW 51001, N'Existen movimientos de almacenes compartidos pendientes de conciliación.', 1;
GO
IF EXISTS (
    SELECT 1 FROM comercial.Venta V
    JOIN logistica.Almacen A ON A.almacen_id=V.almacen_id
    WHERE V.uot_id<>A.uot_propietaria_id
)
    THROW 51003, N'Existen ventas asignadas a almacenes de otra UOT; se requiere conciliación.', 1;
GO
IF EXISTS (
    SELECT 1 FROM logistica.AlmacenUOT AU
    JOIN logistica.Almacen A ON A.almacen_id=AU.almacen_id
    JOIN logistica.AlmacenProductoStock S ON S.almacen_id=A.almacen_id AND (S.stock_actual<>0 OR S.stock_reservado<>0)
    WHERE AU.uot_id<>A.uot_propietaria_id AND AU.estado=1 AND AU.fecha_hasta IS NULL
)
    THROW 51002, N'Conciliar existencias compartidas antes de asignar almacenes exclusivos.', 1;
GO
UPDATE AU SET estado=0,fecha_hasta=COALESCE(fecha_hasta,SYSUTCDATETIME())
FROM logistica.AlmacenUOT AU JOIN logistica.Almacen A ON A.almacen_id=AU.almacen_id
WHERE AU.uot_id<>A.uot_propietaria_id AND AU.estado=1;
GO
IF OBJECT_ID(N'logistica.ProductoUOTPolitica',N'U') IS NULL
BEGIN
 CREATE TABLE logistica.ProductoUOTPolitica(
  uot_id BIGINT NOT NULL, producto_id BIGINT NOT NULL,
  permite_venta BIT NOT NULL CONSTRAINT DF_DESCO_PoliticaVenta DEFAULT(0),
  permite_uso_interno BIT NOT NULL CONSTRAINT DF_DESCO_PoliticaUso DEFAULT(1),
  estado BIT NOT NULL CONSTRAINT DF_DESCO_PoliticaEstado DEFAULT(1),
  usuario_actualizacion_id BIGINT NULL,
  fecha_actualizacion DATETIME2(3) NOT NULL CONSTRAINT DF_DESCO_PoliticaFecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT PK_DESCO_ProductoUOTPolitica PRIMARY KEY(uot_id,producto_id),
  CONSTRAINT FK_DESCO_Politica_UOT FOREIGN KEY(uot_id) REFERENCES org.UOT(uot_id),
  CONSTRAINT FK_DESCO_Politica_Producto FOREIGN KEY(producto_id) REFERENCES logistica.Producto(producto_id)
 );
END;
GO
/* Conservar ventas previamente habilitadas y permitir la operación interna de stock existente. */
INSERT logistica.ProductoUOTPolitica(uot_id,producto_id,permite_venta,permite_uso_interno,estado)
SELECT A.uot_propietaria_id,S.producto_id,
 CONVERT(BIT,CASE WHEN EXISTS(
   SELECT 1 FROM logistica.ProductoPrecio PP
   WHERE PP.producto_id=S.producto_id AND (PP.uot_id=A.uot_propietaria_id OR PP.uot_id IS NULL)
     AND PP.estado=1 AND PP.fecha_hasta IS NULL) THEN 1 ELSE 0 END),1,1
FROM logistica.AlmacenProductoStock S JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id
WHERE NOT EXISTS(SELECT 1 FROM logistica.ProductoUOTPolitica P WHERE P.uot_id=A.uot_propietaria_id AND P.producto_id=S.producto_id)
GROUP BY A.uot_propietaria_id,S.producto_id;
GO
IF OBJECT_ID(N'logistica.TransferenciaAlmacen',N'U') IS NULL
BEGIN
 CREATE TABLE logistica.TransferenciaAlmacen(
  transferencia_almacen_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  almacen_origen_id BIGINT NOT NULL, almacen_destino_id BIGINT NOT NULL,
  uot_origen_id BIGINT NOT NULL, uot_destino_id BIGINT NOT NULL,
  movimiento_salida_id BIGINT NOT NULL, movimiento_entrada_id BIGINT NOT NULL,
  clave_idempotencia UNIQUEIDENTIFIER NOT NULL,
  detalle_sha256 VARBINARY(32) NOT NULL,
  usuario_id BIGINT NOT NULL,
  fecha_hora DATETIME2(0) NOT NULL CONSTRAINT DF_DESCO_TransferFecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_DESCO_TransferClave UNIQUE(clave_idempotencia),
  CONSTRAINT FK_DESCO_TransferOrigen FOREIGN KEY(almacen_origen_id) REFERENCES logistica.Almacen(almacen_id),
  CONSTRAINT FK_DESCO_TransferDestino FOREIGN KEY(almacen_destino_id) REFERENCES logistica.Almacen(almacen_id),
  CONSTRAINT FK_DESCO_TransferMovSalida FOREIGN KEY(movimiento_salida_id) REFERENCES logistica.MovimientoInventario(movimiento_inventario_id),
  CONSTRAINT FK_DESCO_TransferMovEntrada FOREIGN KEY(movimiento_entrada_id) REFERENCES logistica.MovimientoInventario(movimiento_inventario_id)
 );
END;
GO
IF OBJECT_ID(N'logistica.ProgramacionProducto',N'U') IS NULL
BEGIN
 CREATE TABLE logistica.ProgramacionProducto(
  programacion_producto_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  uot_id BIGINT NOT NULL, almacen_id BIGINT NOT NULL, producto_id BIGINT NOT NULL,
  empleado_id BIGINT NOT NULL,
  cantidad_programada DECIMAL(19,3) NOT NULL,
  cantidad_entregada DECIMAL(19,3) NOT NULL CONSTRAINT DF_DESCO_PP_Entregada DEFAULT(0),
  cantidad_devuelta DECIMAL(19,3) NOT NULL CONSTRAINT DF_DESCO_PP_Devuelta DEFAULT(0),
  cantidad_consumida DECIMAL(19,3) NOT NULL CONSTRAINT DF_DESCO_PP_Consumida DEFAULT(0),
  estado_proceso VARCHAR(20) NOT NULL CONSTRAINT DF_DESCO_PP_Estado DEFAULT('PENDIENTE'),
  actividad NVARCHAR(250) NOT NULL, lugar_destino NVARCHAR(300) NOT NULL,
  fecha_inicio DATETIME2(0) NOT NULL, fecha_fin DATETIME2(0) NULL,
  observacion NVARCHAR(500) NULL, archivo_autorizacion_id BIGINT NULL,
  usuario_solicitante_id BIGINT NOT NULL, usuario_aprobador_id BIGINT NULL,
  fecha_aprobacion DATETIME2(0) NULL, motivo_cierre NVARCHAR(300) NULL,
  clave_idempotencia UNIQUEIDENTIFIER NOT NULL, fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_DESCO_PP_Fecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_DESCO_PP_Clave UNIQUE(clave_idempotencia),
  CONSTRAINT CK_DESCO_PP_Cantidades CHECK(cantidad_programada>0 AND cantidad_entregada>=0 AND cantidad_devuelta>=0 AND cantidad_consumida>=0 AND cantidad_entregada<=cantidad_programada AND cantidad_devuelta+cantidad_consumida<=cantidad_entregada),
  CONSTRAINT CK_DESCO_PP_Estados CHECK(estado_proceso IN('PENDIENTE','APROBADA','ENTREGADA','FINALIZADA','RECHAZADA','CANCELADA')),
  CONSTRAINT CK_DESCO_PP_Fechas CHECK(fecha_fin IS NULL OR fecha_fin>=fecha_inicio),
  CONSTRAINT FK_DESCO_PP_UOT FOREIGN KEY(uot_id) REFERENCES org.UOT(uot_id),
  CONSTRAINT FK_DESCO_PP_Almacen FOREIGN KEY(almacen_id) REFERENCES logistica.Almacen(almacen_id),
  CONSTRAINT FK_DESCO_PP_Producto FOREIGN KEY(producto_id) REFERENCES logistica.Producto(producto_id),
  CONSTRAINT FK_DESCO_PP_Empleado FOREIGN KEY(empleado_id) REFERENCES org.Empleado(empleado_id),
  CONSTRAINT FK_DESCO_PP_Archivo FOREIGN KEY(archivo_autorizacion_id) REFERENCES archivo.Archivo(archivo_id)
 );
 CREATE INDEX IX_DESCO_PP_UOT_Estado ON logistica.ProgramacionProducto(uot_id,estado_proceso,fecha_inicio);
END;
GO
IF OBJECT_ID(N'logistica.ProgramacionProductoEvento',N'U') IS NULL
BEGIN
 CREATE TABLE logistica.ProgramacionProductoEvento(
  programacion_producto_evento_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  programacion_producto_id BIGINT NOT NULL,
  tipo_evento VARCHAR(20) NOT NULL,
  cantidad DECIMAL(19,3) NULL,
  movimiento_inventario_id BIGINT NULL,
  usuario_id BIGINT NOT NULL,
  clave_idempotencia UNIQUEIDENTIFIER NOT NULL,
  observacion NVARCHAR(300) NULL,
  fecha_hora DATETIME2(0) NOT NULL CONSTRAINT DF_DESCO_PPEvento_Fecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_DESCO_PPEvento_Clave UNIQUE(clave_idempotencia),
  CONSTRAINT FK_DESCO_PPEvento_Programacion FOREIGN KEY(programacion_producto_id) REFERENCES logistica.ProgramacionProducto(programacion_producto_id),
  CONSTRAINT FK_DESCO_PPEvento_Mov FOREIGN KEY(movimiento_inventario_id) REFERENCES logistica.MovimientoInventario(movimiento_inventario_id)
 );
END;
GO
IF OBJECT_ID(N'logistica.RecursoProgramadoArchivo',N'U') IS NULL
BEGIN
 CREATE TABLE logistica.RecursoProgramadoArchivo(
   recurso_programado_id BIGINT NOT NULL, archivo_id BIGINT NOT NULL,
   usuario_id BIGINT NOT NULL, fecha_vinculo DATETIME2(0) NOT NULL CONSTRAINT DF_DESCO_RPArchivo_Fecha DEFAULT SYSUTCDATETIME(),
   CONSTRAINT PK_DESCO_RPArchivo PRIMARY KEY(recurso_programado_id,archivo_id),
   CONSTRAINT FK_DESCO_RPArchivo_RP FOREIGN KEY(recurso_programado_id) REFERENCES logistica.RecursoProgramado(recurso_programado_id),
   CONSTRAINT FK_DESCO_RPArchivo_Archivo FOREIGN KEY(archivo_id) REFERENCES archivo.Archivo(archivo_id)
 );
END;
GO
