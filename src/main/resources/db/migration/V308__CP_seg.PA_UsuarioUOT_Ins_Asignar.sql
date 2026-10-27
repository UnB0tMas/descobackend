IF OBJECT_ID(N'[seg].[PA_UsuarioUOT_Ins_Asignar]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UsuarioUOT_Ins_Asignar];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_UsuarioUOT_Ins_Asignar
' Descripción             : Vincula un usuario con una unidad organizativa territorial.
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
    EXEC [seg].[PA_UsuarioUOT_Ins_Asignar]
        @nActorUsuarioId = 0,
        @nUsuarioId = 0,
        @nUotId = 0,
        @bPredeterminada = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE seg.PA_UsuarioUOT_Ins_Asignar
 @nActorUsuarioId BIGINT,@nUsuarioId BIGINT,@nUotId BIGINT,@bPredeterminada BIT=0,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo asignar la UOT.';
 IF seg.FN_Usuario_TienePermisoUOT(@nActorUsuarioId,@nUotId,'UOT_ADMINISTRAR_ACCESOS')=0 BEGIN SET @cMensaje=N'No tiene permiso para administrar accesos en esta UOT.'; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM seg.Usuario WHERE usuario_id=@nUsuarioId AND estado=1) BEGIN SET @cMensaje=N'El usuario seleccionado no está disponible.'; RETURN; END;
 BEGIN TRY BEGIN TRAN;
 IF @bPredeterminada=1 UPDATE seg.UsuarioUOT SET es_predeterminada=0 WHERE usuario_id=@nUsuarioId AND estado=1 AND fecha_hasta IS NULL;
 IF EXISTS(SELECT 1 FROM seg.UsuarioUOT WHERE usuario_id=@nUsuarioId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL)
   UPDATE seg.UsuarioUOT SET es_predeterminada=@bPredeterminada WHERE usuario_id=@nUsuarioId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL;
 ELSE INSERT seg.UsuarioUOT(usuario_id,uot_id,es_predeterminada,fecha_desde,estado,asignado_por_usuario_id) VALUES(@nUsuarioId,@nUotId,@bPredeterminada,SYSUTCDATETIME(),1,@nActorUsuarioId);
 COMMIT; SET @bResultado=1; SET @cMensaje=N'UOT asignada correctamente.';
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=N'No se pudo asignar la UOT.'; END CATCH;
END;
GO
