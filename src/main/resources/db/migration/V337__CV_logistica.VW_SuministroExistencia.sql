IF OBJECT_ID(N'[logistica].[VW_SuministroExistencia]', N'V') IS NOT NULL
    DROP VIEW [logistica].[VW_SuministroExistencia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Vista           : logistica.VW_SuministroExistencia
' Descripción              : Consulta existencias de suministros.
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
    SELECT TOP (10) * FROM [logistica].[VW_SuministroExistencia];
*******************************************************************************************************/
CREATE VIEW logistica.VW_SuministroExistencia AS
SELECT S.suministro_id,S.codigo,S.nombre,S.unidad_medida,S.estado,S.stock_minimo,
 COALESCE(K.stock_actual,0) stock_actual,COALESCE(K.stock_reservado,0) stock_reservado,
 COALESCE(K.stock_disponible,0) stock_disponible,
 CONVERT(BIT,CASE WHEN COALESCE(K.stock_disponible,0)<=S.stock_minimo THEN 1 ELSE 0 END) requiere_reposicion
FROM logistica.Suministro S LEFT JOIN logistica.SuministroSaldo K ON K.suministro_id=S.suministro_id;
GO
