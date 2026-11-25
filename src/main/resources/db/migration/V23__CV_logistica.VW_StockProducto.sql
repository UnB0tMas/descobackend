IF OBJECT_ID(N'[logistica].[VW_StockProducto]') IS NOT NULL
    DROP VIEW [logistica].[VW_StockProducto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Vista         : logistica.VW_StockProducto
' Descripción            : Expone la información de vw stock producto para consulta.
' Aplicativo / Módulo    : DESCO / logistica
*******************************************************************************************************/
CREATE   VIEW logistica.VW_StockProducto AS
SELECT S.almacen_id,A.codigo almacen_codigo,A.nombre almacen,A.uot_propietaria_id,
 S.producto_id,P.codigo producto_codigo,P.nombre producto,P.unidad_medida,
 S.stock_actual,S.stock_reservado,logistica.FN_Producto_StockDespachable(S.almacen_id,S.producto_id) stock_disponible,
 S.stock_minimo,S.fecha_actualizacion,S.estado,logistica.FN_AlmacenProducto_TieneHistorial(S.almacen_id,S.producto_id) tiene_historial,
 CONVERT(BIT,CASE WHEN S.estado=1 AND logistica.FN_Producto_StockDespachable(S.almacen_id,S.producto_id)<=S.stock_minimo THEN 1 ELSE 0 END) requiere_reposicion
FROM logistica.AlmacenProductoStock S JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id JOIN logistica.Producto P ON P.producto_id=S.producto_id;
GO
