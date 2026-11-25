IF OBJECT_ID(N'[seg].[PA_UsuarioUOT_Sel_Contexto]') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioUOT_Sel_Contexto];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : seg.PA_UsuarioUOT_Sel_Contexto
' Descripción            : Consulta el contexto UOT de un usuario.
' Aplicativo / Módulo    : DESCO / Seguridad
*******************************************************************************************************/
CREATE PROCEDURE seg.PA_UsuarioUOT_Sel_Contexto
 @nUsuarioId BIGINT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo obtener el contexto de UOT.';
 SELECT UU.usuario_uot_id,UU.uot_id,U.codigo,U.nombre,UU.es_predeterminada,
        STRING_AGG(R.codigo,',') WITHIN GROUP(ORDER BY R.codigo) roles
 FROM seg.UsuarioUOT UU JOIN org.UOT U ON U.uot_id=UU.uot_id AND U.estado=1
 LEFT JOIN seg.UsuarioUOTRol UR ON UR.usuario_uot_id=UU.usuario_uot_id AND UR.estado=1 AND UR.fecha_hasta IS NULL
 LEFT JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1
 WHERE UU.usuario_id=@nUsuarioId AND UU.estado=1 AND UU.fecha_hasta IS NULL
 GROUP BY UU.usuario_uot_id,UU.uot_id,U.codigo,U.nombre,UU.es_predeterminada
 ORDER BY UU.es_predeterminada DESC,U.nombre;
 SET @bResultado=1; SET @cMensaje=N'Contexto de UOT obtenido correctamente.';
END;
GO
