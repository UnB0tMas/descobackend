-- Completar permisos del rol ADMINISTRADOR sin modificar otros roles.
IF OBJECT_ID(N'[seg].[RolPermiso]', N'U') IS NULL
BEGIN
    THROW 51000, N'No existe el catálogo de permisos por rol.', 1;
END;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @RolAdmin BIGINT;
SELECT @RolAdmin = R.rol_id
FROM seg.Rol R
WHERE R.codigo = 'ADMINISTRADOR' AND R.estado = 1;

IF @RolAdmin IS NULL
BEGIN
    THROW 51000, N'No existe el rol administrador activo.', 1;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE RP
    SET RP.estado = 1,
        RP.fecha_retiro = NULL,
        RP.retirado_por_usuario_id = NULL,
        RP.motivo_retiro = NULL,
        RP.fecha_asignacion = COALESCE(RP.fecha_asignacion, SYSUTCDATETIME())
    FROM seg.RolPermiso RP
    INNER JOIN seg.Permiso P ON P.permiso_id = RP.permiso_id AND P.estado = 1
    WHERE RP.rol_id = @RolAdmin AND RP.estado = 0;

    INSERT INTO seg.RolPermiso (rol_id, permiso_id, estado, fecha_asignacion)
    SELECT @RolAdmin, P.permiso_id, 1, SYSUTCDATETIME()
    FROM seg.Permiso P
    WHERE P.estado = 1
      AND NOT EXISTS (
          SELECT 1
          FROM seg.RolPermiso RP WITH (UPDLOCK, HOLDLOCK)
          WHERE RP.rol_id = @RolAdmin AND RP.permiso_id = P.permiso_id
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;
    THROW;
END CATCH;
GO
