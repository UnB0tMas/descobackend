IF OBJECT_ID(N'[logistica].[VW_KardexProducto]', N'V') IS NOT NULL
    DROP VIEW [logistica].[VW_KardexProducto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Vista           : logistica.VW_KardexProducto
' Descripción              : Expone movimientos del kardex de productos.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT TOP (10) * FROM [logistica].[VW_KardexProducto];
*******************************************************************************************************/
CREATE VIEW logistica.VW_KardexProducto
AS
SELECT M.movimiento_inventario_id,M.almacen_id,M.uot_id,M.tipo_movimiento,M.naturaleza,M.fecha_hora,M.usuario_id,
       D.detalle_movimiento_inventario_id,D.producto_id,D.cantidad,D.costo_unitario,D.moneda,D.lote,D.fecha_vencimiento,
       CASE WHEN M.naturaleza='E' THEN D.cantidad ELSE -D.cantidad END cantidad_firmada,
       M.documento_referencia,M.observacion,M.estado
FROM logistica.MovimientoInventario M
JOIN logistica.DetalleMovimientoInventario D ON D.movimiento_inventario_id=M.movimiento_inventario_id;
GO
