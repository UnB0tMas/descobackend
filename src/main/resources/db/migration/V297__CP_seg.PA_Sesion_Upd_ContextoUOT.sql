IF OBJECT_ID(N'[seg].[PA_Sesion_Upd_ContextoUOT]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_Sesion_Upd_ContextoUOT];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_Sesion_Upd_ContextoUOT
' Descripción             : Actualiza el contexto UOT de una sesión.
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
    EXEC [seg].[PA_Sesion_Upd_ContextoUOT]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @cModo = '',
        @nUotId = 0,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE seg.PA_Sesion_Upd_ContextoUOT
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@cModo VARCHAR(12),@nUotId BIGINT=NULL,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo cambiar el contexto de trabajo.';
 SET @cModo=UPPER(NULLIF(LTRIM(RTRIM(@cModo)),''));
 IF NOT EXISTS(SELECT 1 FROM seg.SesionUsuario WHERE sesion_usuario_id=@nSesionUsuarioId AND usuario_id=@nUsuarioId AND estado=1 AND fecha_revocacion IS NULL)
 BEGIN SET @cMensaje=N'La sesion ya no esta disponible.'; RETURN 1; END;
 IF @cModo='ESPECIFICA'
 BEGIN
   IF @nUotId IS NULL OR seg.FN_Usuario_TieneAccesoUOT(@nUsuarioId,@nUotId)=0
   BEGIN SET @cMensaje=N'No tiene acceso a la UOT seleccionada.'; RETURN 1; END;
 END
 ELSE IF @cModo='GENERAL'
 BEGIN
   IF @nUotId IS NOT NULL BEGIN SET @cMensaje=N'El modo general no utiliza una UOT especifica.'; RETURN 1; END;
   IF (SELECT COUNT(*) FROM seg.UsuarioUOT UU JOIN org.UOT U ON U.uot_id=UU.uot_id AND U.estado=1 WHERE UU.usuario_id=@nUsuarioId AND UU.estado=1 AND UU.fecha_hasta IS NULL AND UU.fecha_desde<=SYSUTCDATETIME())<2
   BEGIN SET @cMensaje=N'El modo general requiere acceso a mas de una UOT.'; RETURN 1; END;
 END
 ELSE BEGIN SET @cMensaje=N'El modo de trabajo no es valido.'; RETURN 1; END;
 UPDATE seg.SesionUsuario
    SET modo_uot=@cModo,uot_contexto_id=CASE WHEN @cModo='ESPECIFICA' THEN @nUotId ELSE NULL END,fecha_ultima_actividad=SYSUTCDATETIME()
 WHERE sesion_usuario_id=@nSesionUsuarioId;
 SET @bResultado=1; SET @cMensaje=N'Contexto actualizado.'; RETURN 0;
END;
GO
