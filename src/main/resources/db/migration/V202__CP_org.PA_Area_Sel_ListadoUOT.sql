IF OBJECT_ID(N'[org].[PA_Area_Sel_ListadoUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Area_Sel_ListadoUOT];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Area_Sel_ListadoUOT
' Descripción             : Lista por UOT áreas de la organización.
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
    EXEC [org].[PA_Area_Sel_ListadoUOT]
        @nUsuarioId = 0,
        @nUotId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Area_Sel_ListadoUOT]
    @nUsuarioId BIGINT,@nUotId BIGINT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las áreas.';
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'ORGANIZACIONES_LISTAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para consultar esta UOT.'; RETURN 1; END;
    SELECT A.area_id areaId,A.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,A.area_padre_id areaPadreId,P.nombre areaPadre,A.codigo,A.nombre,A.estado FROM org.Area A JOIN org.UOT U ON U.uot_id=A.uot_id LEFT JOIN org.Area P ON P.area_id=A.area_padre_id AND P.uot_id=A.uot_id WHERE A.uot_id=@nUotId AND A.estado=1 ORDER BY A.nombre,A.area_id;
    SET @bResultado=1; SET @cMensaje=N'Áreas consultadas.'; RETURN 0;
END;
GO
