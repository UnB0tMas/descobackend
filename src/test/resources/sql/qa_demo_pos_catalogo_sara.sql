-- QA de solo lectura: inventario demo Sara Sara y condiciones del catálogo POS.
SET NOCOUNT ON;
IF DB_NAME() NOT IN (N'DESCO_DB_dev', N'DESCO_DB_dev2')
    THROW 51780, N'Este diagnóstico solo se ejecuta en bases DEV.', 1;

DECLARE @nUotId BIGINT;
SELECT @nUotId = U.uot_id
FROM org.UOT U WITH (NOLOCK)
WHERE U.codigo = 'UOT_LEGACY_4' AND U.estado = 1 AND U.es_raiz = 0;

SELECT A.almacen_id, A.nombre, AU.uot_id, AU.permite_salida, AU.estado,
       COUNT(S.producto_id) AS productos_con_stock
FROM logistica.Almacen A WITH (NOLOCK)
JOIN logistica.AlmacenUOT AU WITH (NOLOCK)
     ON AU.almacen_id = A.almacen_id AND AU.uot_id = @nUotId
LEFT JOIN logistica.AlmacenProductoStock S WITH (NOLOCK)
     ON S.almacen_id = A.almacen_id AND S.estado = 1 AND S.stock_disponible > 0
WHERE A.uot_propietaria_id = @nUotId AND A.estado = 1
GROUP BY A.almacen_id, A.nombre, AU.uot_id, AU.permite_salida, AU.estado
ORDER BY A.nombre;

SELECT P.codigo, P.nombre, P.permite_venta, P.estado AS producto_activo,
       S.almacen_id, S.stock_actual, S.stock_reservado, S.stock_disponible,
       POL.permite_venta AS venta_uot, POL.estado AS politica_activa,
       PR.precio_venta, PR.moneda,
       CASE WHEN P.estado = 1 AND P.permite_venta = 1 AND POL.permite_venta = 1
                 AND POL.estado = 1 AND S.estado = 1 AND S.stock_disponible > 0
                 AND PR.precio_venta > 0 AND PR.estado = 1 AND PR.fecha_hasta IS NULL
            THEN N'Visible en POS' ELSE N'Revisar configuración' END AS resultado
FROM logistica.Producto P WITH (NOLOCK)
LEFT JOIN logistica.AlmacenProductoStock S WITH (NOLOCK)
     ON S.producto_id = P.producto_id
LEFT JOIN logistica.Almacen A WITH (NOLOCK) ON A.almacen_id = S.almacen_id
     AND A.uot_propietaria_id = @nUotId
LEFT JOIN logistica.ProductoUOTPolitica POL WITH (NOLOCK)
     ON POL.producto_id = P.producto_id AND POL.uot_id = @nUotId
OUTER APPLY (
    SELECT TOP (1) PP.precio_venta, PP.moneda, PP.estado, PP.fecha_hasta
    FROM logistica.ProductoPrecio PP WITH (NOLOCK)
    WHERE PP.producto_id = P.producto_id AND PP.uot_id = @nUotId
    ORDER BY PP.version DESC, PP.producto_precio_id DESC
) PR
WHERE P.codigo LIKE 'DEMO-POS-SARA-%'
ORDER BY P.codigo;
