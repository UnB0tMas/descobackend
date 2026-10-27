IF OBJECT_ID(N'[org].[PA_UOT_Sel_Listado]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_UOT_Sel_Listado];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_UOT_Sel_Listado
' Descripción             : Lista unidades organizativas territoriales.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Organización
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
    EXEC [org].[PA_UOT_Sel_Listado]
        @nUsuarioId = 0,
        @nUotId = 0,
        @bIncluirInactivas = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE org.PA_UOT_Sel_Listado
    @nUsuarioId BIGINT,@nUotId BIGINT=NULL,@bIncluirInactivas BIT=0,
    @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @bResultado=0,@cMensaje=N'No se pudo consultar las UOT.';
 DECLARE @EsAdmin BIT=CASE WHEN EXISTS(SELECT 1 FROM seg.UsuarioRol UR JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.codigo='ADMINISTRADOR' AND R.estado=1 WHERE UR.usuario_id=@nUsuarioId AND UR.estado=1 AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())) THEN 1 ELSE 0 END;
 IF @bIncluirInactivas=1 AND @EsAdmin=0 BEGIN SET @cMensaje=N'No tiene permiso para consultar UOT inactivas.'; RETURN 1; END;
 SELECT U.uot_id,U.uot_padre_id,U.codigo,U.nombre,U.descripcion,U.ubicacion_id,U.es_raiz,U.fecha_inicio,U.fecha_fin,U.estado,
        CONVERT(BIT,CASE WHEN A.usuario_uot_id IS NULL THEN 0 ELSE 1 END) asignada,ISNULL(A.es_predeterminada,0) es_predeterminada
 FROM org.UOT U
 LEFT JOIN seg.UsuarioUOT A ON A.uot_id=U.uot_id AND A.usuario_id=@nUsuarioId AND A.estado=1 AND A.fecha_hasta IS NULL
 WHERE (@bIncluirInactivas=1 OR U.estado=1) AND (@nUotId IS NULL OR U.uot_id=@nUotId)
   AND (@EsAdmin=1 OR A.usuario_uot_id IS NOT NULL)
 ORDER BY U.es_raiz DESC,U.nombre;
 SET @bResultado=1; SET @cMensaje=N'UOT consultadas.'; RETURN 0;
END;
GO
