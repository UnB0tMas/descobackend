IF OBJECT_ID(N'[org].[PA_Asociacion_Sel_ListadoUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_Asociacion_Sel_ListadoUOT];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_Asociacion_Sel_ListadoUOT
' Descripción             : Lista por UOT asociaciones.
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
    EXEC [org].[PA_Asociacion_Sel_ListadoUOT]
        @nUsuarioId = 0,
        @nUotId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [org].[PA_Asociacion_Sel_ListadoUOT]
    @nUsuarioId BIGINT,@nUotId BIGINT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las asociaciones.';
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'ORGANIZACIONES_LISTAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para consultar esta UOT.'; RETURN 1; END;
    SELECT E.empresa_id asociacionId,E.ruc,E.razon_social razonSocial,E.nombre_comercial nombreComercial,A.fecha_constitucion fechaConstitucion,A.numero_partida numeroPartida,A.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre
    FROM org.Asociacion A JOIN org.Empresa E ON E.empresa_id=A.asociacion_id JOIN org.UOT U ON U.uot_id=A.uot_id JOIN org.ConvenioUOTOrganizacion C ON C.empresa_id=A.asociacion_id AND C.uot_id=A.uot_id AND C.tipo_vinculo='ASOCIACION' AND C.estado=1 AND C.fecha_fin IS NULL
    WHERE A.uot_id=@nUotId AND A.estado=1 AND E.estado=1 ORDER BY E.razon_social;
    SET @bResultado=1; SET @cMensaje=N'Asociaciones consultadas.'; RETURN 0;
END;
GO
