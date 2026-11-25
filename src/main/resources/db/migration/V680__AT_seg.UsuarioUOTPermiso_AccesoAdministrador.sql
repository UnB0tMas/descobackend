-- Accesos expresos para administradores con UOT vigente.
-- La habilitación de convenios especiales continúa siendo obligatoria.
IF OBJECT_ID(N'[seg].[UsuarioUOTPermiso]', N'U') IS NULL
BEGIN
    THROW 51000, N'No existe la asignación de permisos por UOT.', 1;
END;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Ahora DATETIME2(0) = SYSUTCDATETIME();
DECLARE @Concesiones TABLE (
    usuario_uot_id BIGINT NOT NULL,
    permiso_id BIGINT NOT NULL,
    PRIMARY KEY (usuario_uot_id, permiso_id)
);

INSERT INTO @Concesiones (usuario_uot_id, permiso_id)
SELECT DISTINCT UU.usuario_uot_id, P.permiso_id
FROM seg.Usuario U
INNER JOIN seg.UsuarioRol UR
    ON UR.usuario_id = U.usuario_id
    AND UR.estado = 1
    AND UR.fecha_desde <= @Ahora
    AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta > @Ahora)
INNER JOIN seg.Rol R
    ON R.rol_id = UR.rol_id
    AND R.codigo = 'ADMINISTRADOR'
    AND R.estado = 1
INNER JOIN seg.UsuarioUOT UU
    ON UU.usuario_id = U.usuario_id
    AND UU.estado = 1
    AND UU.fecha_desde <= @Ahora
    AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta > @Ahora)
INNER JOIN org.UOT O
    ON O.uot_id = UU.uot_id AND O.estado = 1
INNER JOIN seg.Permiso P
    ON P.estado = 1
INNER JOIN seg.Modulo M
    ON M.modulo_id = P.modulo_id AND M.estado = 1
WHERE U.estado = 1
  AND U.estado_cuenta = 'ACTIVA'
  AND (
      NOT EXISTS (
          SELECT 1
          FROM seg.ModuloEspecialPermiso MP
          WHERE MP.permiso_id = P.permiso_id
      )
      OR EXISTS (
          SELECT 1
          FROM seg.ModuloEspecialPermiso MP
          INNER JOIN seg.ModuloEspecial ME
              ON ME.modulo_especial_id = MP.modulo_especial_id AND ME.estado = 1
          INNER JOIN org.ConvenioModuloEspecial CM
              ON CM.modulo_especial_id = ME.modulo_especial_id AND CM.estado = 1
          INNER JOIN org.ConvenioUOTOrganizacion CO
              ON CO.convenio_uot_organizacion_id = CM.convenio_uot_organizacion_id
          INNER JOIN org.Empresa E
              ON E.empresa_id = CO.empresa_id AND E.estado = 1
          WHERE MP.permiso_id = P.permiso_id
            AND CO.uot_id = UU.uot_id
            AND CO.estado = 1
            AND (CO.fecha_inicio IS NULL OR CO.fecha_inicio <= CONVERT(DATE, @Ahora))
            AND (CO.fecha_fin IS NULL OR CO.fecha_fin >= CONVERT(DATE, @Ahora))
      )
  );

BEGIN TRY
    BEGIN TRANSACTION;

    -- Corregir denegaciones expresas activas, sin tocar otras cuentas.
    UPDATE UP
    SET UP.permitido = 1,
        UP.motivo = N'Acceso del administrador en UOT autorizada',
        UP.fecha_desde = CASE WHEN UP.fecha_desde > @Ahora THEN @Ahora ELSE UP.fecha_desde END
    FROM seg.UsuarioUOTPermiso UP
    INNER JOIN @Concesiones C
        ON C.usuario_uot_id = UP.usuario_uot_id
        AND C.permiso_id = UP.permiso_id
    WHERE UP.estado = 1
      AND (UP.fecha_hasta IS NULL OR UP.fecha_hasta > @Ahora)
      AND (UP.permitido = 0 OR UP.fecha_desde > @Ahora);

    INSERT INTO seg.UsuarioUOTPermiso (
        usuario_uot_id, permiso_id, permitido, motivo, fecha_desde, estado
    )
    SELECT C.usuario_uot_id, C.permiso_id, 1,
           N'Acceso del administrador en UOT autorizada', @Ahora, 1
    FROM @Concesiones C
    WHERE NOT EXISTS (
        SELECT 1
        FROM seg.UsuarioUOTPermiso UP WITH (UPDLOCK, HOLDLOCK)
        WHERE UP.usuario_uot_id = C.usuario_uot_id
          AND UP.permiso_id = C.permiso_id
          AND UP.estado = 1
          AND UP.fecha_desde <= @Ahora
          AND (UP.fecha_hasta IS NULL OR UP.fecha_hasta > @Ahora)
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
