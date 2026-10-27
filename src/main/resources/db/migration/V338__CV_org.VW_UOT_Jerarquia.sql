IF OBJECT_ID(N'[org].[VW_UOT_Jerarquia]', N'V') IS NOT NULL
    DROP VIEW [org].[VW_UOT_Jerarquia];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Vista           : org.VW_UOT_Jerarquia
' Descripción              : Presenta la jerarquía de unidades organizativas territoriales.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Organización
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT TOP (10) * FROM [org].[VW_UOT_Jerarquia];
*******************************************************************************************************/
CREATE VIEW org.VW_UOT_Jerarquia
AS
WITH J AS
(
    SELECT U.uot_id,U.uot_padre_id,U.codigo,U.nombre,U.ubicacion_id,U.es_raiz,U.estado,
           CONVERT(NVARCHAR(1000),U.nombre) ruta,0 nivel
    FROM org.UOT U WHERE U.uot_padre_id IS NULL
    UNION ALL
    SELECT U.uot_id,U.uot_padre_id,U.codigo,U.nombre,U.ubicacion_id,U.es_raiz,U.estado,
           CONVERT(NVARCHAR(1000),J.ruta+N' > '+U.nombre),J.nivel+1
    FROM org.UOT U JOIN J ON J.uot_id=U.uot_padre_id
)
SELECT * FROM J;
GO
