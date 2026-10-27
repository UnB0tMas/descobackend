IF OBJECT_ID(N'[seg].[PA_UsuarioUOTRol_Ins_Asignar]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioUOTRol_Ins_Asignar];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_UsuarioUOTRol_Ins_Asignar
' Descripción             : Asigna un rol a un usuario dentro de una UOT.
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
    EXEC [seg].[PA_UsuarioUOTRol_Ins_Asignar]
        @nActorUsuarioId = 0,
        @nUsuarioId = 0,
        @nUotId = 0,
        @nRolId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE seg.PA_UsuarioUOTRol_Ins_Asignar
 @nActorUsuarioId BIGINT,@nUsuarioId BIGINT,@nUotId BIGINT,@nRolId BIGINT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo asignar el rol en la UOT.';
 IF seg.FN_Usuario_TienePermisoUOT(@nActorUsuarioId,@nUotId,'UOT_ADMINISTRAR_ACCESOS')=0 BEGIN SET @cMensaje=N'No tiene permiso para administrar accesos en esta UOT.'; RETURN; END;
 DECLARE @UU BIGINT=(SELECT TOP(1) usuario_uot_id FROM seg.UsuarioUOT WHERE usuario_id=@nUsuarioId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL);
 IF @UU IS NULL BEGIN SET @cMensaje=N'Primero asigne la UOT al usuario.'; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM seg.Rol WHERE rol_id=@nRolId AND estado=1) BEGIN SET @cMensaje=N'El rol seleccionado no está disponible.'; RETURN; END;
 IF EXISTS(SELECT 1 FROM seg.UsuarioUOTRol WHERE usuario_uot_id=@UU AND rol_id=@nRolId AND estado=1 AND fecha_hasta IS NULL)
 BEGIN SET @bResultado=1; SET @cMensaje=N'El rol ya está asignado en esta UOT.'; RETURN; END;
 INSERT seg.UsuarioUOTRol(usuario_uot_id,rol_id,fecha_desde,estado,asignado_por_usuario_id) VALUES(@UU,@nRolId,SYSUTCDATETIME(),1,@nActorUsuarioId);
 SET @bResultado=1; SET @cMensaje=N'Rol asignado correctamente en la UOT.';
END;
GO
