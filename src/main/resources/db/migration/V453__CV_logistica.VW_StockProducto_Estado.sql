IF OBJECT_ID(N'[logistica].[VW_StockProducto]', N'V') IS NOT NULL
    DROP VIEW [logistica].[VW_StockProducto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Vista           : logistica.VW_StockProducto
' Descripción              : Consulta existencias de productos por almacén.
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
    SELECT TOP (10) * FROM [logistica].[VW_StockProducto];
*******************************************************************************************************/
CREATE VIEW logistica.VW_StockProducto
AS
SELECT S.almacen_id,A.codigo almacen_codigo,A.nombre almacen,A.uot_propietaria_id,
       S.producto_id,P.codigo producto_codigo,P.nombre producto,P.unidad_medida,
       S.stock_actual,S.stock_reservado,S.stock_disponible,S.stock_minimo,S.fecha_actualizacion,S.estado,logistica.FN_AlmacenProducto_TieneHistorial(S.almacen_id,S.producto_id) tiene_historial,
       CONVERT(BIT,CASE WHEN S.estado=1 AND S.stock_disponible<=S.stock_minimo THEN 1 ELSE 0 END) requiere_reposicion
FROM logistica.AlmacenProductoStock S
JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id
JOIN logistica.Producto P ON P.producto_id=S.producto_id;
GO
