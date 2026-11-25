-- Habilitar permisos expresos del administrador solo en UOT vigentes.
-- Los módulos especiales requieren convenio habilitado en esa UOT.
IF OBJECT_ID(N'[seg].[UsuarioUOTPermiso]', N'U') IS NULL
BEGIN
    THROW 51000, N'No existe la asignación de permisos por UOT.', 1;
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

DECLARE @Concesiones TABLE (
    usuario_uot_id BIGINT NOT NULL,
    permiso_id BIGINT NOT NULL,
    PRIMARY KEY (usuario_uot_id, permiso_id)
);

INSERT INTO @Concesiones (usuario_uot_id, permiso_id)
SELECT DISTINCT UU.usuario_uot_id, P.permiso_id
FROM seg.UsuarioRol UR
INNER JOIN seg.Usuario U ON U.usuario_id = UR.usuario_id
INNER JOIN seg.UsuarioUOT UU ON UU.usuario_id = UR.usuario_id
INNER JOIN org.UOT O ON O.uot_id = UU.uot_id AND O.estado = 1
INNER JOIN seg.Permiso P ON P.estado = 1
INNER JOIN seg.Modulo M ON M.modulo_id = P.modulo_id AND M.estado = 1
WHERE UR.rol_id = @RolAdmin AND UR.estado = 1
  AND UR.fecha_desde <= SYSUTCDATETIME()
  AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta > SYSUTCDATETIME())
  AND U.estado = 1 AND U.estado_cuenta = 'ACTIVA'
  AND UU.estado = 1 AND UU.fecha_desde <= SYSUTCDATETIME()
  AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta > SYSUTCDATETIME())
  AND (
      NOT EXISTS (
          SELECT 1
          FROM seg.ModuloEspecialPermiso MP
          WHERE MP.permiso_id = P.permiso_id
      )
      OR EXISTS (
          SELECT 1
          FROM seg.ModuloEspecialPermiso MP
          INNER JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id = MP.modulo_especial_id AND ME.estado = 1
          INNER JOIN org.ConvenioModuloEspecial CM ON CM.modulo_especial_id = ME.modulo_especial_id AND CM.estado = 1
          INNER JOIN org.ConvenioUOTOrganizacion CO ON CO.convenio_uot_organizacion_id = CM.convenio_uot_organizacion_id
          INNER JOIN org.Empresa E ON E.empresa_id = CO.empresa_id AND E.estado = 1
          WHERE MP.permiso_id = P.permiso_id AND CO.uot_id = UU.uot_id
            AND CO.estado = 1
            AND (CO.fecha_inicio IS NULL OR CO.fecha_inicio <= CONVERT(DATE, SYSUTCDATETIME()))
            AND (CO.fecha_fin IS NULL OR CO.fecha_fin >= CONVERT(DATE, SYSUTCDATETIME()))
      )
  );

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE UP
    SET UP.permitido = 1,
        UP.motivo = N'Bootstrap de acceso del administrador'
    FROM seg.UsuarioUOTPermiso UP
    INNER JOIN @Concesiones C
        ON C.usuario_uot_id = UP.usuario_uot_id AND C.permiso_id = UP.permiso_id
    WHERE UP.estado = 1 AND UP.fecha_hasta IS NULL AND UP.permitido = 0;

    INSERT INTO seg.UsuarioUOTPermiso (
        usuario_uot_id, permiso_id, permitido, motivo, fecha_desde, estado
    )
    SELECT C.usuario_uot_id, C.permiso_id, 1,
           N'Bootstrap de acceso del administrador', SYSUTCDATETIME(), 1
    FROM @Concesiones C
    WHERE NOT EXISTS (
        SELECT 1
        FROM seg.UsuarioUOTPermiso UP WITH (UPDLOCK, HOLDLOCK)
        WHERE UP.usuario_uot_id = C.usuario_uot_id
          AND UP.permiso_id = C.permiso_id
          AND UP.estado = 1 AND UP.fecha_hasta IS NULL
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
