package com.franco.desco.infrastructure.bootstrap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

/** Inventario de prueba para el POS Sara Sara. No se ejecuta en producción. */
@Component
@Order(40)
public class DemoPosInventoryBootstrap implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(DemoPosInventoryBootstrap.class);
    private static final String UOT_CODE = "UOT_LEGACY_4";
    private static final String DEMO_LOGIN = "pos_sarasara_01";
    private static final String DOC = "DESCO-DEMO-POS-SARA-2026";

    private record Item(String code, String name, String category, String unit,
                        BigDecimal price, BigDecimal quantity) {}

    private static final List<Item> ITEMS = List.of(
        item("01", "Palta Hass seleccionada", "PF-0000010", "KG", "8.50", "100"),
        item("02", "Palta Fuerte seleccionada", "PF-0000010", "KG", "7.50", "80"),
        item("03", "Palta de segunda selección", "PF-0000010", "KG", "5.50", "60"),
        item("04", "Palta Hass caja de 10 kg", "PF-0000010", "CAJA", "82.00", "35"),
        item("05", "Compost orgánico saco 40 kg", "IA-0000011", "UND", "35.00", "50"),
        item("06", "Humus de lombriz saco 25 kg", "IA-0000011", "UND", "28.00", "50"),
        item("07", "Biol orgánico por litro", "IA-0000011", "L", "9.50", "70"),
        item("08", "Fertilizante NPK 20-20-20", "F-0000023", "KG", "18.00", "100"),
        item("09", "Fertilizante foliar por litro", "F-0000023", "L", "16.00", "50"),
        item("10", "Jaba plástica ventilada 25 kg", "IA-0000011", "UND", "27.00", "60")
    );

    private static Item item(String suffix, String name, String category, String unit,
                             String price, String quantity) {
        return new Item("DEMO-POS-SARA-" + suffix, name, category, unit,
                        new BigDecimal(price), new BigDecimal(quantity));
    }

    private final JdbcTemplate jdbc;
    private final boolean enabled;

    public DemoPosInventoryBootstrap(JdbcTemplate jdbc,
            @Value("${DESCO_DEMO_POS_INVENTORY_ENABLED:true}") boolean enabled) {
        this.jdbc = jdbc;
        this.enabled = enabled;
    }

    private long uniqueId(String sql, Object... parameters) {
        List<Long> result = jdbc.query(sql, (rs, i) -> rs.getLong(1), parameters);
        if (result.size() != 1) {
            throw new IllegalStateException("La configuración de inventario demo es inexistente o ambigua.");
        }
        return result.getFirst();
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (!enabled) {
            return;
        }
        String database = jdbc.queryForObject("SELECT DB_NAME()", String.class);
        if (!"DESCO_DB_dev".equalsIgnoreCase(database)
                && !"DESCO_DB_dev2".equalsIgnoreCase(database)) {
            log.warn("[POS INVENTARIO DEMO] Omitido: la base no es de desarrollo.");
            return;
        }

        long uot = uniqueId("""
            SELECT uot_id FROM org.UOT
            WHERE codigo = ? AND estado = 1 AND es_raiz = 0
            """, UOT_CODE);
        long user = uniqueId("""
            SELECT usuario_id FROM seg.Usuario
            WHERE nombre_usuario = ? AND estado = 1 AND estado_cuenta = 'ACTIVA'
            """, DEMO_LOGIN);
        long warehouse = uniqueId("""
            SELECT TOP (1) A.almacen_id
            FROM logistica.Almacen A
            JOIN logistica.AlmacenUOT AU ON AU.almacen_id = A.almacen_id
            WHERE A.uot_propietaria_id = ? AND A.estado = 1
              AND AU.uot_id = ? AND AU.estado = 1 AND AU.permite_salida = 1
              AND AU.fecha_desde <= SYSUTCDATETIME()
              AND (AU.fecha_hasta IS NULL OR AU.fecha_hasta >= SYSUTCDATETIME())
            ORDER BY CASE WHEN A.nombre = N'Almacén agrícola central - Pausa' THEN 0 ELSE 1 END,
                     A.almacen_id
            """, uot, uot);

        Integer lock = jdbc.queryForObject("""
            DECLARE @result INT;
            EXEC @result = sys.sp_getapplock
                @Resource = N'DESCO:DEMO:POS:INVENTARIO:SARA',
                @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
            SELECT @result;
            """, Integer.class);
        if (lock == null || lock < 0) {
            throw new IllegalStateException("No fue posible reservar el inventario demo para su inicialización.");
        }

        for (Item item : ITEMS) {
            Integer categoryCount = jdbc.queryForObject("""
                SELECT COUNT(1) FROM config.CatalogoRecursoValor
                WHERE catalogo = 'CATEGORIA_PRODUCTO' AND codigo = ? AND estado = 1
                """, Integer.class, item.category());
            Integer unitCount = jdbc.queryForObject("""
                SELECT COUNT(1) FROM config.CatalogoRecursoValor
                WHERE catalogo = 'UNIDAD_MEDIDA' AND codigo = ? AND estado = 1
                """, Integer.class, item.unit());
            if (categoryCount == null || categoryCount != 1 || unitCount == null || unitCount != 1) {
                throw new IllegalStateException("Catálogo demo incompatible: " + item.code());
            }
        }

        int created = 0;
        int stocked = 0;
        for (Item item : ITEMS) {
            List<Long> ids = jdbc.query("""
                SELECT producto_id FROM logistica.Producto WITH (UPDLOCK, HOLDLOCK)
                WHERE codigo = ?
                """, (rs, i) -> rs.getLong(1), item.code());
            if (ids.size() > 1) {
                throw new IllegalStateException("Producto demo duplicado: " + item.code());
            }
            if (ids.isEmpty()) {
                jdbc.update("""
                    INSERT logistica.Producto
                        (codigo, nombre, descripcion, unidad_medida, categoria,
                         requiere_lote, controla_vencimiento, permite_venta, estado)
                    VALUES (?, ?, N'Producto exclusivo de pruebas de POS.', ?, ?, 0, 0, 1, 1)
                    """, item.code(), item.name(), item.unit(), item.category());
                created++;
            }
            long productId = uniqueId("SELECT producto_id FROM logistica.Producto WHERE codigo = ?", item.code());

            // Solo habilita la política de venta si todavía no existe.
            Integer policies = jdbc.queryForObject("""
                SELECT COUNT(*) FROM logistica.ProductoUOTPolitica
                WHERE uot_id = ? AND producto_id = ?
                """, Integer.class, uot, productId);
            if (policies != null && policies == 0) {
                jdbc.update("""
                    INSERT logistica.ProductoUOTPolitica
                        (uot_id, producto_id, permite_venta, permite_uso_interno, estado,
                         usuario_actualizacion_id)
                    VALUES (?, ?, 1, 0, 1, ?)
                    """, uot, productId, user);
            }

            // Se preservan los precios ya configurados por un operador.
            Integer prices = jdbc.queryForObject("""
                SELECT COUNT(*) FROM logistica.ProductoPrecio
                WHERE producto_id = ? AND uot_id = ?
                """, Integer.class, productId, uot);
            if (prices != null && prices == 0) {
                jdbc.update("""
                    INSERT logistica.ProductoPrecio
                        (producto_id, uot_id, precio_venta, precio_inicial, moneda,
                         version, fecha_desde, estado, usuario_id)
                    VALUES (?, ?, ?, ?, 'PEN', 1, SYSUTCDATETIME(), 1, ?)
                    """, productId, uot, item.price(),
                        item.price().multiply(new BigDecimal("0.70")), user);
            }

            // No reponer stock existente ni recrear stock de productos con movimientos previos.
            Integer existingStock = jdbc.queryForObject("""
                SELECT COUNT(1) FROM logistica.AlmacenProductoStock WITH (UPDLOCK, HOLDLOCK)
                WHERE almacen_id = ? AND producto_id = ?
                """, Integer.class, warehouse, productId);
            if (existingStock != null && existingStock > 0) {
                continue;
            }

            Long previousMovements = jdbc.queryForObject("""
                SELECT COUNT_BIG(1)
                FROM logistica.MovimientoInventario M
                JOIN logistica.DetalleMovimientoInventario D
                  ON D.movimiento_inventario_id = M.movimiento_inventario_id
                WHERE M.almacen_id = ? AND D.producto_id = ?
                """, Long.class, warehouse, productId);
            if (previousMovements != null && previousMovements > 0) {
                log.warn("[POS INVENTARIO DEMO] {} sin stock actual, pero con historial; no se repone.",
                    item.code());
                continue;
            }

            // Un movimiento idempotente por producto permite completar cargas parciales.
            UUID key = UUID.nameUUIDFromBytes(
                (DOC + ":" + uot + ":" + warehouse + ":" + item.code())
                    .getBytes(StandardCharsets.UTF_8));
            Integer previousKey = jdbc.queryForObject("""
                SELECT COUNT(1) FROM logistica.MovimientoInventario
                WHERE clave_idempotencia = ?
                """, Integer.class, key.toString());
            if (previousKey != null && previousKey > 0) {
                log.warn("[POS INVENTARIO DEMO] Movimiento previo sin stock: {}.", item.code());
                continue;
            }

            jdbc.update("""
                INSERT logistica.MovimientoInventario
                    (almacen_id, uot_id, tipo_movimiento, naturaleza, documento_referencia,
                     clave_idempotencia, usuario_id, observacion, estado)
                VALUES (?, ?, 'AJUSTE', 'E', ?, ?, ?,
                        N'Ingreso inicial exclusivo de pruebas POS.', 1)
                """, warehouse, uot, DOC, key.toString(), user);
            long movement = uniqueId("""
                SELECT movimiento_inventario_id FROM logistica.MovimientoInventario
                WHERE clave_idempotencia = ?
                """, key.toString());
            jdbc.update("""
                INSERT logistica.DetalleMovimientoInventario
                    (movimiento_inventario_id, producto_id, cantidad, costo_unitario, moneda)
                VALUES (?, ?, ?, ?, 'PEN')
                """, movement, productId, item.quantity(),
                item.price().multiply(new BigDecimal("0.70")));
            jdbc.update("""
                INSERT logistica.AlmacenProductoStock
                    (almacen_id, producto_id, stock_actual, stock_reservado, stock_minimo, estado)
                VALUES (?, ?, ?, 0, 0, 1)
                """, warehouse, productId, item.quantity());
            stocked++;
        }

        Integer available = jdbc.queryForObject("""
            SELECT COUNT(*) FROM logistica.AlmacenProductoStock S
            JOIN logistica.Producto P ON P.producto_id = S.producto_id
            JOIN logistica.ProductoUOTPolitica POL ON POL.producto_id = P.producto_id
                AND POL.uot_id = ? AND POL.estado = 1 AND POL.permite_venta = 1
            JOIN logistica.ProductoPrecio PR ON PR.producto_id = P.producto_id
                AND PR.uot_id = ? AND PR.estado = 1 AND PR.fecha_hasta IS NULL
            WHERE S.almacen_id = ? AND S.estado = 1 AND S.stock_disponible > 0
              AND P.estado = 1 AND P.permite_venta = 1 AND P.codigo LIKE 'DEMO-POS-SARA-%'
              AND PR.precio_venta > 0
            """, Integer.class, uot, uot, warehouse);
        log.info("[POS INVENTARIO DEMO] UOT={} almacén={} creados={} ingresos={} visibles={}",
            uot, warehouse, created, stocked, available);
    }
}
