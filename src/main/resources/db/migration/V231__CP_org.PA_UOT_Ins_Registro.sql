IF OBJECT_ID(N'[org].[PA_UOT_Ins_Registro]', N'P') IS NOT NULL
    DROP PROCEDURE [org].[PA_UOT_Ins_Registro];
GO

/******************************************************************************************************
' Nombre del PA           : org.PA_UOT_Ins_Registro
' Descripción             : Registra unidades organizativas territoriales.
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
        @nUotId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [org].[PA_UOT_Ins_Registro]
        @nUsuarioId = 0,
        @nUotPadreId = 0,
        @nUbicacionId = 0,
        @cCodigo = '',
        @cNombre = N'',
        @cDescripcion = N'',
        @nUotId = @nUotId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nUotId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE org.PA_UOT_Ins_Registro
    @nUsuarioId BIGINT,@nUotPadreId BIGINT,@nUbicacionId BIGINT=NULL,@cCodigo VARCHAR(40),@cNombre NVARCHAR(160),@cDescripcion NVARCHAR(400)=NULL,
    @nUotId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SELECT @nUotId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar la UOT.';
    SET @cCodigo=UPPER(NULLIF(LTRIM(RTRIM(@cCodigo)),'')); SET @cNombre=NULLIF(LTRIM(RTRIM(@cNombre)),N'');
    IF @cCodigo IS NULL OR @cNombre IS NULL BEGIN SET @cMensaje=N'Complete correctamente los datos de la UOT.'; RETURN 1; END;
    IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotPadreId,'UOT_CREAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para crear una UOT.'; RETURN 1; END;
    IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotPadreId AND estado=1) BEGIN SET @cMensaje=N'La UOT superior no esta disponible.'; RETURN 1; END;
    IF @nUbicacionId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM geo.Ubicacion WHERE ubicacion_id=@nUbicacionId) BEGIN SET @cMensaje=N'La ubicacion no es valida.'; RETURN 1; END;
    IF EXISTS(SELECT 1 FROM org.UOT WHERE codigo=@cCodigo) BEGIN SET @cMensaje=N'El codigo de UOT ya esta registrado.'; RETURN 1; END;
    BEGIN TRY
      BEGIN TRAN;
      INSERT org.UOT(uot_padre_id,ubicacion_id,codigo,nombre,descripcion,es_raiz,fecha_inicio,estado)
      VALUES(@nUotPadreId,@nUbicacionId,@cCodigo,@cNombre,@cDescripcion,0,CONVERT(date,SYSUTCDATETIME()),1);
      SET @nUotId=SCOPE_IDENTITY();
      DECLARE @RolAdmin BIGINT=(SELECT TOP(1) rol_id FROM seg.Rol WHERE codigo='ADMINISTRADOR' AND estado=1);
      DECLARE @Admins TABLE(usuario_id BIGINT PRIMARY KEY);
      INSERT @Admins SELECT DISTINCT UR.usuario_id FROM seg.UsuarioRol UR WHERE UR.rol_id=@RolAdmin AND UR.estado=1 AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME());
      INSERT seg.UsuarioUOT(usuario_id,uot_id,es_predeterminada,fecha_desde,estado,asignado_por_usuario_id)
      SELECT A.usuario_id,@nUotId,0,SYSUTCDATETIME(),1,@nUsuarioId FROM @Admins A
      WHERE NOT EXISTS(SELECT 1 FROM seg.UsuarioUOT X WHERE X.usuario_id=A.usuario_id AND X.uot_id=@nUotId AND X.estado=1 AND X.fecha_hasta IS NULL);
      INSERT seg.UsuarioUOTRol(usuario_uot_id,rol_id,fecha_desde,estado,asignado_por_usuario_id)
      SELECT UU.usuario_uot_id,@RolAdmin,SYSUTCDATETIME(),1,@nUsuarioId
      FROM seg.UsuarioUOT UU JOIN @Admins A ON A.usuario_id=UU.usuario_id
      WHERE UU.uot_id=@nUotId AND UU.estado=1 AND UU.fecha_hasta IS NULL
        AND NOT EXISTS(SELECT 1 FROM seg.UsuarioUOTRol X WHERE X.usuario_uot_id=UU.usuario_uot_id AND X.rol_id=@RolAdmin AND X.estado=1 AND X.fecha_hasta IS NULL);
      COMMIT; SET @bResultado=1; SET @cMensaje=N'UOT registrada.'; RETURN 0;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @nUotId=NULL; SET @cMensaje=N'No se pudo registrar la UOT.'; RETURN 1; END CATCH;
END;
GO
