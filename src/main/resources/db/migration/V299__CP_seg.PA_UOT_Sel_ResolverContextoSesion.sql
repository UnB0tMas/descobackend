IF OBJECT_ID(N'[seg].[PA_UOT_Sel_ResolverContextoSesion]', N'P') IS NOT NULL
    DROP PROCEDURE [seg].[PA_UOT_Sel_ResolverContextoSesion];
GO

/******************************************************************************************************
' Nombre del PA           : seg.PA_UOT_Sel_ResolverContextoSesion
' Descripción             : Resuelve el contexto de UOT asociado a una sesión.
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
        @nUotId BIGINT,
        @bModoGeneral BIT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [seg].[PA_UOT_Sel_ResolverContextoSesion]
        @nUsuarioId = 0,
        @nSesionUsuarioId = 0,
        @nUotSolicitada = 0,
        @cCodigoPermiso = '',
        @bRequiereUot = 0,
        @nUotId = @nUotId OUTPUT,
        @bModoGeneral = @bModoGeneral OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nUotId, @bModoGeneral, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE seg.PA_UOT_Sel_ResolverContextoSesion
    @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotSolicitada BIGINT=NULL,
    @cCodigoPermiso VARCHAR(40)=NULL,@bRequiereUot BIT=1,
    @nUotId BIGINT OUTPUT,@bModoGeneral BIT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SELECT @nUotId=NULL,@bModoGeneral=0,@bResultado=0,@cMensaje=N'No se pudo validar la UOT.';
 DECLARE @Modo VARCHAR(12),@UotSesion BIGINT;
 SELECT @Modo=modo_uot,@UotSesion=uot_contexto_id FROM seg.SesionUsuario
 WHERE sesion_usuario_id=@nSesionUsuarioId AND usuario_id=@nUsuarioId AND estado=1 AND fecha_revocacion IS NULL;
 IF @Modo IS NULL BEGIN SET @cMensaje=N'La sesion ya no esta disponible.'; RETURN 1; END;
 IF @Modo='GENERAL'
 BEGIN
   SET @bModoGeneral=1; SET @nUotId=@nUotSolicitada;
   IF @bRequiereUot=1 AND @nUotId IS NULL BEGIN SET @cMensaje=N'Seleccione una UOT.'; RETURN 1; END;
 END
 ELSE
 BEGIN
   SET @nUotId=@UotSesion;
   IF @nUotId IS NULL BEGIN SET @cMensaje=N'Seleccione una UOT.'; RETURN 1; END;
   IF @nUotSolicitada IS NOT NULL AND @nUotSolicitada<>@nUotId BEGIN SET @cMensaje=N'La UOT no corresponde al contexto actual.'; RETURN 1; END;
 END;
 IF @nUotId IS NOT NULL
 BEGIN
   IF seg.FN_Usuario_TieneAccesoUOT(@nUsuarioId,@nUotId)=0 BEGIN SET @cMensaje=N'No tiene acceso a la UOT.'; RETURN 1; END;
   IF NULLIF(@cCodigoPermiso,'') IS NOT NULL AND seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,@cCodigoPermiso)=0
   BEGIN SET @cMensaje=N'No tiene permiso para esta accion en la UOT.'; RETURN 1; END;
 END
 ELSE IF NOT EXISTS(
   SELECT 1 FROM seg.UsuarioUOT UU JOIN org.UOT U ON U.uot_id=UU.uot_id AND U.estado=1
   WHERE UU.usuario_id=@nUsuarioId AND UU.estado=1 AND UU.fecha_hasta IS NULL AND UU.fecha_desde<=SYSUTCDATETIME()
     AND (NULLIF(@cCodigoPermiso,'') IS NULL OR seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,UU.uot_id,@cCodigoPermiso)=1)
 )
 BEGIN SET @cMensaje=N'No tiene UOT disponibles para esta accion.'; RETURN 1; END;
 SET @bResultado=1; SET @cMensaje=N'UOT validada.'; RETURN 0;
END;
GO
