-- Aplicación manual opcional para corregir permisos demo ya existentes.
-- Nunca ejecutar en producción. No cambia permisos de otros roles.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() NOT IN (N'DESCO_DB_dev',N'DESCO_DB_dev2')
    THROW 51800,N'Este ajuste solo puede ejecutarse en bases de desarrollo DESCO.',1;

IF NOT EXISTS (SELECT 1 FROM seg.Rol WITH (NOLOCK)
               WHERE codigo=N'POS_DEMO_BASE' AND estado=1)
    THROW 51801,N'El perfil de prueba no existe.',1;

DECLARE @sara BIGINT = (SELECT uot_id FROM org.UOT WITH (NOLOCK)
                      WHERE codigo=N'UOT_LEGACY_4' AND estado=1);
IF @sara IS NULL THROW 51804,N'No se encontró la sede de prueba.',1;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE RP
       SET estado=0,
           fecha_retiro=SYSUTCDATETIME(),
           motivo_retiro=N'Operador de prueba sin funciones administrativas'
      FROM seg.RolPermiso RP
      JOIN seg.Rol R ON R.rol_id=RP.rol_id
      JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id
     WHERE R.codigo=N'POS_DEMO_BASE'
       AND RP.estado=1
       AND P.codigo IN ('PERSONAL_COMERCIAL_LISTAR','PERSONAL_COMERCIAL_EDITAR',
                        'PERSONAL_COMERCIAL_HABILITAR','HORARIO_COMERCIAL_CONFIGURAR');

    IF NOT EXISTS (
        SELECT 1 FROM seg.Usuario U WITH (NOLOCK)
        JOIN seg.UsuarioUOT UU WITH (NOLOCK) ON UU.usuario_id=U.usuario_id
        WHERE U.nombre_usuario=N'pos_sarasara_01'
          AND UU.uot_id=@sara AND UU.estado=1
          AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'PERSONAL_COMERCIAL_PROPIO')=1
          AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,'POS_OPERAR')=1
    ) THROW 51802,N'Faltan permisos básicos del operador de prueba.',1;

    IF EXISTS (
        SELECT 1 FROM seg.Usuario U WITH (NOLOCK)
        CROSS JOIN (VALUES('PERSONAL_COMERCIAL_LISTAR'),('PERSONAL_COMERCIAL_EDITAR'),
                         ('PERSONAL_COMERCIAL_HABILITAR'),('HORARIO_COMERCIAL_CONFIGURAR')) P(codigo)
        WHERE U.nombre_usuario=N'pos_sarasara_01'
          AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@sara,P.codigo)=1
    ) THROW 51803,N'El usuario conserva permisos administrativos desde otra asignación.',1;

    COMMIT TRANSACTION;
    SELECT N'CORRECTO' AS resultado,
           N'Valeria conserva Mi horario y POS, sin gestionar horarios ajenos.' AS detalle;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
