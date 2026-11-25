IF OBJECT_ID(N'[logistica].[VW_SuministroExistencia]') IS NOT NULL
    DROP VIEW [logistica].[VW_SuministroExistencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Vista         : logistica.VW_SuministroExistencia
' Descripción            : Consulta existencias de suministros.
' Aplicativo / Módulo    : DESCO / Logística
*******************************************************************************************************/
CREATE VIEW logistica.VW_SuministroExistencia AS
SELECT S.suministro_id,S.codigo,S.nombre,S.unidad_medida,S.estado,S.stock_minimo,
 COALESCE(K.stock_actual,0) stock_actual,COALESCE(K.stock_reservado,0) stock_reservado,
 COALESCE(K.stock_disponible,0) stock_disponible,
 CONVERT(BIT,CASE WHEN COALESCE(K.stock_disponible,0)<=S.stock_minimo THEN 1 ELSE 0 END) requiere_reposicion
FROM logistica.Suministro S LEFT JOIN logistica.SuministroSaldo K ON K.suministro_id=S.suministro_id;
GO
