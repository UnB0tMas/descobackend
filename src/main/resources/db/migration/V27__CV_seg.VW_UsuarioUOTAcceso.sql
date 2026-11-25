IF OBJECT_ID(N'[seg].[VW_UsuarioUOTAcceso]') IS NOT NULL
    DROP VIEW [seg].[VW_UsuarioUOTAcceso];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Vista         : seg.VW_UsuarioUOTAcceso
' Descripción            : Consulta las asignaciones de acceso de usuarios a UOT.
' Aplicativo / Módulo    : DESCO / Seguridad
*******************************************************************************************************/
CREATE VIEW seg.VW_UsuarioUOTAcceso
AS
SELECT UU.usuario_uot_id,UU.usuario_id,U.nombre_usuario,UU.uot_id,O.codigo uot_codigo,O.nombre uot_nombre,
       UU.es_predeterminada,UU.fecha_desde,UU.fecha_hasta,UU.estado
FROM seg.UsuarioUOT UU
JOIN seg.Usuario U ON U.usuario_id=UU.usuario_id
JOIN org.UOT O ON O.uot_id=UU.uot_id;
GO
