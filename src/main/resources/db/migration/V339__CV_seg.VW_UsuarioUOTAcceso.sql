IF OBJECT_ID(N'[seg].[VW_UsuarioUOTAcceso]', N'V') IS NOT NULL
    DROP VIEW [seg].[VW_UsuarioUOTAcceso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre de Vista           : seg.VW_UsuarioUOTAcceso
' Descripción              : Consulta las asignaciones de acceso de usuarios a UOT.
'
' Autor / Fecha            : JJFL / 11.10.2026
' Aplicativo / Módulo      : DESCO / Seguridad
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente en Flyway. Definición original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de ejecución:
    -- Referencial: utilizar parámetros/identificadores válidos del entorno.
    SELECT TOP (10) * FROM [seg].[VW_UsuarioUOTAcceso];
*******************************************************************************************************/
CREATE VIEW seg.VW_UsuarioUOTAcceso
AS
SELECT UU.usuario_uot_id,UU.usuario_id,U.nombre_usuario,UU.uot_id,O.codigo uot_codigo,O.nombre uot_nombre,
       UU.es_predeterminada,UU.fecha_desde,UU.fecha_hasta,UU.estado
FROM seg.UsuarioUOT UU
JOIN seg.Usuario U ON U.usuario_id=UU.usuario_id
JOIN org.UOT O ON O.uot_id=UU.uot_id;
GO
