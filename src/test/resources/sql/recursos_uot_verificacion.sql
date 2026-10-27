/* Ejecutar sobre DESCO_DB después de Flyway: cada consulta debe devolver 0 filas. */
SELECT A.almacen_id,AU.uot_id
FROM logistica.AlmacenUOT AU JOIN logistica.Almacen A ON A.almacen_id=AU.almacen_id
WHERE AU.estado=1 AND AU.fecha_hasta IS NULL AND AU.uot_id<>A.uot_propietaria_id;

SELECT M.movimiento_inventario_id
FROM logistica.MovimientoInventario M JOIN logistica.Almacen A ON A.almacen_id=M.almacen_id
WHERE M.uot_id<>A.uot_propietaria_id;

SELECT V.venta_id
FROM comercial.Venta V JOIN logistica.Almacen A ON A.almacen_id=V.almacen_id
WHERE V.uot_id<>A.uot_propietaria_id;

SELECT P.programacion_producto_id
FROM logistica.ProgramacionProducto P JOIN logistica.Almacen A ON A.almacen_id=P.almacen_id
WHERE P.uot_id<>A.uot_propietaria_id;

SELECT S.almacen_id,S.producto_id,S.stock_actual,S.stock_reservado
FROM logistica.AlmacenProductoStock S
WHERE S.stock_actual<0 OR S.stock_reservado<0 OR S.stock_reservado>S.stock_actual;

SELECT P.programacion_producto_id,P.cantidad_programada,P.cantidad_entregada,P.cantidad_devuelta,P.cantidad_consumida
FROM logistica.ProgramacionProducto P
WHERE P.cantidad_entregada>P.cantidad_programada OR P.cantidad_devuelta+P.cantidad_consumida>P.cantidad_entregada;

/* Escenarios para pruebas de integración con datos de ensayo:
   1. Dos UOT con almacenes exclusivos; acceso cruzado prohibido.
   2. Un producto: venta POS y salida técnica sobre el mismo saldo.
   3. Dos ventas concurrentes no superan stock_disponible.
   4. Solicitud -> aprobación (reserva) -> entrega (salida) -> devolución o consumo.
   5. Cancelación libera la reserva, no descuenta stock.
   6. Reintento con misma clave de idempotencia no duplica salidas.
   7. Transferencia entre almacenes crea kardex vinculado en ambos extremos.
   8. Documento PDF local puede vincularse solo desde la misma UOT.
   9. Venta rechaza producto configurado solo para uso interno.
   10. Imágenes y precios históricos de productos siguen disponibles. */
