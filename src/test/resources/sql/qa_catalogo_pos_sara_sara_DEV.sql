-- Diagnóstico de catálogo POS Sara Sara, solo lectura.
SET NOCOUNT ON;
IF DB_NAME() NOT IN (N'DESCO_DB_dev', N'DESCO_DB_dev2')
BEGIN
    THROW 51780, N'El diagnóstico solo está permitido en DEV.', 1;
END;

DECLARE @nUotId BIGINT;
DECLARE @nAlmacenId BIGINT;

SELECT @nUotId = U.uot_id
FROM org.UOT U WITH (NOLOCK)
WHERE U.codigo = 'UOT_LEGACY_4' AND U.estado = 1;

SELECT @nAlmacenId = A.almacen_id
FROM logistica.Almacen A WITH (NOLOCK)
WHERE A.codigo = 'ALM-SS-PAUSA' AND A.uot_propietaria_id = @nUotId AND A.estado = 1;

IF @nUotId IS NULL OR @nAlmacenId IS NULL
BEGIN
    THROW 51781, N'No existe la UOT o el almacén esperado.', 1;
END;

SELECT DB_NAME() AS base_desarrollo, @nUotId AS uot_id, @nAlmacenId AS almacen_id,
       COUNT(P.producto_id) AS productos_demo,
       SUM(CASE WHEN S.stock_disponible > 0 AND S.estado = 1
                 AND POL.estado = 1 AND POL.permite_venta = 1
                 AND PR.precio_venta > 0 AND P.estado = 1 AND P.permite_venta = 1
                 THEN 1 ELSE 0 END) AS productos_listos
FROM logistica.Producto P WITH (NOLOCK)
LEFT JOIN logistica.AlmacenProductoStock S WITH (NOLOCK)
       ON S.producto_id = P.producto_id AND S.almacen_id = @nAlmacenId
LEFT JOIN logistica.ProductoUOTPolitica POL WITH (NOLOCK)
       ON POL.producto_id = P.producto_id AND POL.uot_id = @nUotId
OUTER APPLY (
    SELECT TOP (1) PP.precio_venta
    FROM logistica.ProductoPrecio PP WITH (NOLOCK)
    WHERE PP.producto_id = P.producto_id AND PP.uot_id = @nUotId
      AND PP.estado = 1 AND PP.fecha_hasta IS NULL
    ORDER BY PP.version DESC, PP.producto_precio_id DESC
) PR
WHERE P.codigo LIKE 'DEMO-POS-SARA-%';

SELECT P.codigo, P.nombre, P.unidad_medida, P.categoria,
       S.stock_actual, S.stock_reservado, S.stock_disponible,
       POL.permite_venta AS venta_uot, PR.precio_venta,
       CASE
           WHEN S.producto_id IS NULL THEN N'Falta stock'
           WHEN S.estado <> 1 OR S.stock_disponible <= 0 THEN N'Sin stock disponible'
           WHEN POL.producto_id IS NULL OR POL.estado <> 1 OR POL.permite_venta <> 1 THEN N'Política de venta inactiva'
           WHEN PR.precio_venta IS NULL OR PR.precio_venta <= 0 THEN N'Falta precio vigente'
           WHEN P.estado <> 1 OR P.permite_venta <> 1 THEN N'Producto no habilitado'
           ELSE N'Listo para POS'
       END AS diagnostico
FROM logistica.Producto P WITH (NOLOCK)
LEFT JOIN logistica.AlmacenProductoStock S WITH (NOLOCK)
       ON S.producto_id = P.producto_id AND S.almacen_id = @nAlmacenId
LEFT JOIN logistica.ProductoUOTPolitica POL WITH (NOLOCK)
       ON POL.producto_id = P.producto_id AND POL.uot_id = @nUotId
OUTER APPLY (
    SELECT TOP (1) PP.precio_venta
    FROM logistica.ProductoPrecio PP WITH (NOLOCK)
    WHERE PP.producto_id = P.producto_id AND PP.uot_id = @nUotId
      AND PP.estado = 1 AND PP.fecha_hasta IS NULL
    ORDER BY PP.version DESC, PP.producto_precio_id DESC
) PR
WHERE P.codigo LIKE 'DEMO-POS-SARA-%'
ORDER BY P.codigo;
