IF OBJECT_ID(N'[org].[PA_UOT_Upd_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_UOT_Upd_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_UOT_Upd_Registro
' Descripción             : Actualiza los datos de unidades organizativas territoriales.
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
    EXEC [org].[PA_UOT_Upd_Registro]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nUotPadreId = 0,
        @nUbicacionId = 0,
        @cNombre = N'',
        @cDescripcion = N'',
        @bEstado = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE org.PA_UOT_Upd_Registro
    @nUsuarioId BIGINT,@nUotId BIGINT,@nUotPadreId BIGINT=NULL,@nUbicacionId BIGINT=NULL,
    @cNombre NVARCHAR(160),@cDescripcion NVARCHAR(400)=NULL,@bEstado BIT=1,
    @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo actualizar la UOT.';
 SET @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N'');
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'UOT_EDITAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para editar esta UOT.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotId AND estado=1) BEGIN SET @cMensaje=N'La UOT no esta disponible.'; RETURN 1; END;
 IF @cNombre IS NULL BEGIN SET @cMensaje=N'Ingrese el nombre de la UOT.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotId AND es_raiz=1) AND @nUotPadreId IS NOT NULL BEGIN SET @cMensaje=N'La UOT raiz no puede depender de otra.'; RETURN 1; END;
 IF @nUotPadreId=@nUotId BEGIN SET @cMensaje=N'La UOT no puede depender de si misma.'; RETURN 1; END;
 IF @nUotPadreId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotPadreId AND estado=1) BEGIN SET @cMensaje=N'La UOT superior no esta disponible.'; RETURN 1; END;
 IF @nUbicacionId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Ubicacion WHERE ubicacion_id=@nUbicacionId) BEGIN SET @cMensaje=N'La ubicacion no es valida.'; RETURN 1; END;
 UPDATE org.UOT SET uot_padre_id=@nUotPadreId,ubicacion_id=@nUbicacionId,nombre=@cNombre,descripcion=@cDescripcion WHERE uot_id=@nUotId AND estado=1;
 SET @bResultado=1; SET @cMensaje=N'UOT actualizada.'; RETURN 0;
END;
GO
