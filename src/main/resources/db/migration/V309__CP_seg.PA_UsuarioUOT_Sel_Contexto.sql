IF OBJECT_ID(N'[seg].[PA_UsuarioUOT_Sel_Contexto]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioUOT_Sel_Contexto];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_UsuarioUOT_Sel_Contexto
' Descripción             : Consulta el contexto UOT de un usuario.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Seguridad
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [seg].[PA_UsuarioUOT_Sel_Contexto]
        @nUsuarioId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
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
