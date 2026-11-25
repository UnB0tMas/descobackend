-- Sincronizar el rol ADMINISTRADOR en las UOT ya asignadas a cada administrador.
IF OBJECT_ID(N'[seg].[UsuarioUOTRol]', N'U') IS NULL
BEGIN
    THROW 51000, N'No existe la asignación de roles por UOT.', 1;
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

    INSERT INTO seg.UsuarioUOTRol (usuario_uot_id, rol_id, fecha_desde, estado)
    SELECT UU.usuario_uot_id, @RolAdmin, SYSUTCDATETIME(), 1
    FROM seg.UsuarioUOT UU
    INNER JOIN seg.UsuarioRol UR ON UR.usuario_id = UU.usuario_id AND UR.rol_id = @RolAdmin
    INNER JOIN seg.Usuario U ON U.usuario_id = UU.usuario_id AND U.estado = 1 AND U.estado_cuenta = 'ACTIVA'
    INNER JOIN org.UOT O ON O.uot_id = UU.uot_id AND O.estado = 1
    WHERE UU.estado = 1 AND UU.fecha_desde <= SYSUTCDATETIME()
      AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta > SYSUTCDATETIME())
      AND UR.estado = 1 AND UR.fecha_desde <= SYSUTCDATETIME()
      AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta > SYSUTCDATETIME())
      AND NOT EXISTS (
          SELECT 1
          FROM seg.UsuarioUOTRol UUR WITH (UPDLOCK, HOLDLOCK)
          WHERE UUR.usuario_uot_id = UU.usuario_uot_id
            AND UUR.rol_id = @RolAdmin AND UUR.estado = 1
            AND (UUR.fecha_hasta IS NULL OR UUR.fecha_hasta > SYSUTCDATETIME())
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
